import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID') ?? '';
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY') ?? '';
const ONESIGNAL_API = 'https://onesignal.com/api/v1/notifications';

interface NotificationPayload {
  userIds: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  let payload: NotificationPayload;
  try {
    payload = await req.json() as NotificationPayload;
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const { userIds, title, body, data } = payload;

  if (!userIds || userIds.length === 0) {
    return new Response(
      JSON.stringify({ skipped: true, reason: 'no recipients' }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );
  }

  if (!ONESIGNAL_REST_API_KEY) {
    return new Response(
      JSON.stringify({ error: 'ONESIGNAL_REST_API_KEY not configured' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  const osPayload = {
    app_id: ONESIGNAL_APP_ID,
    include_external_user_ids: userIds,
    channel_for_external_user_ids: 'push',
    headings: { en: title },
    contents: { en: body },
    data: data ?? {},
  };

  const osRes = await fetch(ONESIGNAL_API, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Basic ${ONESIGNAL_REST_API_KEY}`,
    },
    body: JSON.stringify(osPayload),
  });

  const osBody = await osRes.json();

  return new Response(JSON.stringify(osBody), {
    status: osRes.status,
    headers: { 'Content-Type': 'application/json', Connection: 'keep-alive' },
  });
});
