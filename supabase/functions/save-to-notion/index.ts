import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { Client } from "https://deno.land/x/notion_sdk/src/mod.ts";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

    try {
        const { url, text, author, mediaUrl } = await req.json();
        const notion = new Client({ auth: Deno.env.get("NOTION_API_KEY") });

        await notion.pages.create({
            parent: { database_id: Deno.env.get("NOTION_DATABASE_ID")! },
            properties: {
                Title: { title: [{ text: { content: text.substring(0, 30) } }] },
                URL: { url: url },
                Author: { rich_text: [{ text: { content: author } }] },
                Content: { rich_text: [{ text: { content: text } }] },
                ...(mediaUrl && {
                    Media: { files: [{ name: "image", type: "external", external: { url: mediaUrl } }] }
                })
            },
        });

        return new Response(JSON.stringify({ success: true }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
    } catch (error) {
        console.error(error);
        const errorMessage = error instanceof Error ? error.message : "An unknown error occurred";
        return new Response(JSON.stringify({ error: errorMessage }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 400,
        });
    }
});