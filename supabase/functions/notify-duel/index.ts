// Sender push-varsel (FCM) til den som er utfordret til 1v1. Kalles av databasen (trigger på duels)
// med {duel_id}. Samme mønster som i Logica. Trygt uten delt hemmelighet: funksjonen slår opp
// utfordringen selv, varsler bare om nye, uvarslede utfordringer og merker dem som varslet.
// Hemmelighet i Supabase (Edge Functions -> Secrets): FCM_SERVICE_ACCOUNT = hele JSON-filen
// fra Firebase (tjenestekonto).
import { createClient } from "npm:@supabase/supabase-js@2";

type Msg = { title: string; body: (n: string) => string };

const MESSAGES: Record<string, Msg> = {
  nb: { title: "Du er utfordret!", body: (n) => `${n} har utfordret deg til 1v1 i Ball Brain.` },
  sv: { title: "Du är utmanad!", body: (n) => `${n} har utmanat dig på 1v1 i Ball Brain.` },
  da: { title: "Du er udfordret!", body: (n) => `${n} har udfordret dig til 1v1 i Ball Brain.` },
  de: { title: "Du wurdest herausgefordert!", body: (n) => `${n} hat dich in Ball Brain zum 1v1 herausgefordert.` },
  es: { title: "¡Te han retado!", body: (n) => `${n} te ha retado a un 1v1 en Ball Brain.` },
  fr: { title: "Tu as été défié !", body: (n) => `${n} t’a défié en 1v1 dans Ball Brain.` },
  en: { title: "You've been challenged!", body: (n) => `${n} challenged you to a 1v1 in Ball Brain.` },
};

// Språk ut fra mottakerens land (samme regel som i appen).
const BY_COUNTRY: Record<string, string> = {
  NO: "nb", SE: "sv", DK: "da", DE: "de", AT: "de", CH: "de",
  ES: "es", MX: "es", AR: "es", CO: "es", CL: "es", FR: "fr",
};

function b64url(data: ArrayBuffer | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : new Uint8Array(data);
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function accessToken(sa: { client_email: string; private_key: string }): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const pem = sa.private_key.replace(/-----[A-Z ]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey("pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claim}`));
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: `${header}.${claim}.${b64url(sig)}` }),
  });
  const json = await res.json();
  if (!json.access_token) throw new Error("token: " + JSON.stringify(json));
  return json.access_token;
}

Deno.serve(async (req) => {
  try {
    const { duel_id } = await req.json();
    if (typeof duel_id !== "string" || duel_id.length < 10) return new Response("bad request", { status: 400 });
    const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

    // Bare nye, uvarslede utfordringer (under 10 minutter); merk først, så den ikke sendes to ganger.
    const since = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    const { data: claimed } = await sb.from("duels").update({ notified: true })
      .eq("id", duel_id).eq("mode", "challenge").eq("notified", false).gt("created_at", since)
      .select("p1, p2");
    if (!claimed || claimed.length === 0) return new Response("nothing to send");
    const { p1, p2 } = claimed[0];

    const { data: from } = await sb.from("profiles").select("username").eq("id", p1).single();
    const { data: to } = await sb.from("profiles").select("country_code, accepts_challenges").eq("id", p2).single();
    if (to && to.accepts_challenges === false) return new Response("opted out");
    const { data: tokens } = await sb.from("push_tokens").select("token").eq("user_id", p2);
    if (!tokens || tokens.length === 0) return new Response("no tokens");

    const sa = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT")!);
    const bearer = await accessToken(sa);
    const msg = MESSAGES[BY_COUNTRY[to?.country_code ?? ""] ?? "en"];
    for (const { token } of tokens) {
      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
        method: "POST",
        headers: { Authorization: `Bearer ${bearer}`, "Content-Type": "application/json" },
        body: JSON.stringify({ message: { token, notification: { title: msg.title, body: msg.body(from?.username ?? "?") }, android: { priority: "HIGH" } } }),
      });
      if (res.status === 404 || res.status === 400) await sb.from("push_tokens").delete().eq("token", token);
    }
    return new Response("sent");
  } catch (e) {
    console.error(String(e));
    return new Response("error", { status: 500 });
  }
});
