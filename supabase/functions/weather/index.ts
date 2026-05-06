// Supabase Edge Function: /functions/v1/weather
// Proxies WeatherAPI so the API key stays server-side.

type WeatherOk = {
  locationName: string;
  tempC: number;
  conditionText: string;
  iconUrl: string;
};

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response("Method Not Allowed", { status: 405 });
    }

    const apiKey = Deno.env.get("WEATHER_API_KEY")?.trim() ?? "";
    if (!apiKey) {
      return Response.json(
        { error: "Missing WEATHER_API_KEY secret on function." },
        { status: 500 },
      );
    }

    const body = await req.json().catch(() => ({}));
    const q = typeof body?.q === "string" && body.q.trim().length > 0 ? body.q.trim() : "auto:ip";

    const url = new URL("https://api.weatherapi.com/v1/current.json");
    url.searchParams.set("key", apiKey);
    url.searchParams.set("q", q);

    const upstream = await fetch(url.toString(), {
      headers: { "Accept": "application/json" },
    });

    const upstreamText = await upstream.text();
    if (!upstream.ok) {
      return Response.json(
        { error: "WeatherAPI error", status: upstream.status, body: upstreamText },
        { status: 502 },
      );
    }

    const decoded = JSON.parse(upstreamText);
    const locationName = decoded?.location?.name;
    const tempC = decoded?.current?.temp_c;
    const conditionText = decoded?.current?.condition?.text;
    const icon = decoded?.current?.condition?.icon;
    const iconUrl = typeof icon === "string" ? (icon.startsWith("http") ? icon : `https:${icon}`) : "";

    if (
      typeof locationName !== "string" || !locationName ||
      typeof tempC !== "number" ||
      typeof conditionText !== "string" || !conditionText ||
      typeof iconUrl !== "string" || !iconUrl
    ) {
      return Response.json({ error: "Unexpected WeatherAPI response shape" }, { status: 502 });
    }

    const payload: WeatherOk = {
      locationName,
      tempC,
      conditionText,
      iconUrl,
    };

    return Response.json(payload);
  } catch (e) {
    return Response.json(
      { error: String(e ?? "Unknown error") },
      { status: 500 },
    );
  }
});

