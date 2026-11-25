// Sender push-varsler (FCM): 1v1-utfordringer og klubbkamper. Kalles av databasen med
// {duel_id} eller {game_id, event: "invite" | "accepted" | "kickoff"}. Samme mønster som i Logica.
// Trygt uten delt hemmelighet: funksjonen slår opp saken selv, varsler bare om det som faktisk
// har skjedd, og merker det som varslet så ingenting sendes to ganger.
// Hemmelighet i Supabase (Edge Functions -> Secrets): FCM_SERVICE_ACCOUNT = hele JSON-filen
// fra Firebase (tjenestekonto).
import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";

type Kind = "duel" | "invite" | "accepted" | "kickoff";
type Text = { title: string; body: string }; // {n} = navn på utfordrer / motstanderklubb

const MESSAGES: Record<string, Record<Kind, Text>> = {
  nb: {
    duel: { title: "Du er utfordret!", body: "{n} har utfordret deg til 1v1 i Ball Brain." },
    invite: { title: "Klubben er utfordret!", body: "{n} vil møte klubben din." },
    accepted: { title: "Klubbkampen er avtalt", body: "Meld deg på laget mot {n}." },
    kickoff: { title: "Avspark!", body: "Kampen mot {n} har startet. Fristen er kort." },
  },
  sv: {
    duel: { title: "Du är utmanad!", body: "{n} har utmanat dig på 1v1 i Ball Brain." },
    invite: { title: "Klubben är utmanad!", body: "{n} vill möta din klubb." },
    accepted: { title: "Klubbmatchen är bestämd", body: "Gå med i laget mot {n}." },
    kickoff: { title: "Avspark!", body: "Matchen mot {n} har börjat. Tiden är kort." },
  },
  da: {
    duel: { title: "Du er udfordret!", body: "{n} har udfordret dig til 1v1 i Ball Brain." },
    invite: { title: "Klubben er udfordret!", body: "{n} vil møde din klub." },
    accepted: { title: "Klubkampen er aftalt", body: "Kom med på holdet mod {n}." },
    kickoff: { title: "Kampstart!", body: "Kampen mod {n} er i gang. Fristen er kort." },
  },
  de: {
    duel: { title: "Du wurdest herausgefordert!", body: "{n} hat dich in Ball Brain zum 1v1 herausgefordert." },
    invite: { title: "Euer Klub ist herausgefordert!", body: "{n} will gegen euch antreten." },
    accepted: { title: "Klubduell steht", body: "Tritt dem Team gegen {n} bei." },
    kickoff: { title: "Anstoß!", body: "Das Duell gegen {n} läuft. Die Zeit ist knapp." },
  },
  es: {
    duel: { title: "¡Te han retado!", body: "{n} te ha retado a un 1v1 en Ball Brain." },
    invite: { title: "¡Han retado a tu club!", body: "{n} quiere enfrentarse a tu club." },
    accepted: { title: "Partido de clubes fijado", body: "Únete al equipo contra {n}." },
    kickoff: { title: "¡Saque inicial!", body: "El partido contra {n} ha empezado. Queda poco tiempo." },
  },
  fr: {
    duel: { title: "Tu as été défié !", body: "{n} t’a défié en 1v1 dans Ball Brain." },
    invite: { title: "Ton club est défié !", body: "{n} veut affronter ton club." },
    accepted: { title: "Match de clubs fixé", body: "Rejoins l’équipe contre {n}." },
    kickoff: { title: "Coup d’envoi !", body: "Le match contre {n} a commencé. Le temps est compté." },
  },
  en: {
    duel: { title: "You've been challenged!", body: "{n} challenged you to a 1v1 in Ball Brain." },
    invite: { title: "Your club is challenged!", body: "{n} wants to play your club." },
    accepted: { title: "Club match is on", body: "Join the team against {n}." },
    kickoff: { title: "Kick-off!", body: "The match against {n} has started. Be quick." },
  },
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

/** Sender samme varsel til flere brukere, på hver sitt språk. */
async function send(sb: SupabaseClient, users: string[], kind: Kind, name: string): Promise<number> {
  if (users.length === 0) return 0;
  const { data: tokens } = await sb.from("push_tokens").select("token, user_id").in("user_id", users);
  if (!tokens || tokens.length === 0) return 0;
  const { data: profiles } = await sb.from("profiles").select("id, country_code").in("id", users);
  const country = new Map((profiles ?? []).map((p) => [p.id, p.country_code ?? ""]));
  const sa = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT")!);
  const bearer = await accessToken(sa);
  let sent = 0;
  for (const { token, user_id } of tokens) {
    const msg = MESSAGES[BY_COUNTRY[country.get(user_id) ?? ""] ?? "en"][kind];
    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
      method: "POST",
      headers: { Authorization: `Bearer ${bearer}`, "Content-Type": "application/json" },
      body: JSON.stringify({ message: { token, notification: { title: msg.title, body: msg.body.replace("{n}", name) }, android: { priority: "HIGH" } } }),
    });
    if (res.ok) sent++;
    if (res.status === 404 || res.status === 400) await sb.from("push_tokens").delete().eq("token", token);
  }
  return sent;
}

async function duel(sb: SupabaseClient, id: string): Promise<string> {
  // Bare nye, uvarslede utfordringer (under 10 minutter); merk først, så den ikke sendes to ganger.
  const since = new Date(Date.now() - 10 * 60 * 1000).toISOString();
  const { data: claimed } = await sb.from("duels").update({ notified: true })
    .eq("id", id).eq("mode", "challenge").eq("notified", false).gt("created_at", since)
    .select("p1, p2");
  if (!claimed || claimed.length === 0) return "nothing to send";
  const { p1, p2 } = claimed[0];
  const { data: from } = await sb.from("profiles").select("username").eq("id", p1).single();
  const { data: to } = await sb.from("profiles").select("accepts_challenges").eq("id", p2).single();
  if (to && to.accepts_challenges === false) return "opted out";
  return `sent ${await send(sb, [p2], "duel", from?.username ?? "?")}`;
}

async function club(sb: SupabaseClient, id: string, event: "invite" | "accepted" | "kickoff"): Promise<string> {
  const flag = `n_${event}`;
  const status = event === "invite" ? "invited" : "accepted";
  let q = sb.from("club_games").update({ [flag]: true }).eq("id", id).eq(flag, false).eq("status", status);
  if (event === "kickoff") q = q.lte("kickoff", new Date().toISOString());
  const { data: claimed } = await q.select("home, away");
  if (!claimed || claimed.length === 0) return "nothing to send";
  const { home, away } = claimed[0];
  const { data: groups } = await sb.from("groups").select("id, name").in("id", [home, away]);
  const nameOf = (g: string) => groups?.find((x) => x.id === g)?.name ?? "?";
  // Invitasjonen går til den utfordrede klubben; de andre til begge (motstanderens navn).
  let sent = 0;
  for (const [mine, other] of event === "invite" ? [[away, home]] : [[home, away], [away, home]]) {
    const { data: members } = await sb.from("group_members").select("user_id").eq("group_id", mine);
    sent += await send(sb, (members ?? []).map((m) => m.user_id), event, nameOf(other));
  }
  return `sent ${sent}`;
}

Deno.serve(async (req) => {
  try {
    const { duel_id, game_id, event } = await req.json();
    const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    if (typeof duel_id === "string" && duel_id.length >= 10) return new Response(await duel(sb, duel_id));
    if (typeof game_id === "string" && ["invite", "accepted", "kickoff"].includes(event)) {
      return new Response(await club(sb, game_id, event));
    }
    return new Response("bad request", { status: 400 });
  } catch (e) {
    console.error(String(e));
    return new Response("error", { status: 500 });
  }
});
