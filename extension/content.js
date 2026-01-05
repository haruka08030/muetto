console.log("X to Notion Extension Loaded!");

async function getSupabaseUrl() {
    return new Promise((resolve) => {
        chrome.storage.sync.get(['supabaseUrl'], function (result) {
            resolve(result.supabaseUrl || "YOUR_SUPABASE_EDGE_FUNCTION_URL_HERE");
        });
    });
}

function createButton() {
    if (document.getElementById("save-btn")) return;

    const btn = document.createElement("button");
    btn.id = "save-btn";
    btn.innerText = "Save to Notion";

    btn.addEventListener("click", async (e) => {
        e.preventDefault();
        e.stopPropagation();
        console.log("Button Clicked!");

        const tweet = document.querySelector('article[data-testid="tweet"]');
        if (!tweet) return alert("ツイートが見つかりません");

        console.log("Scraping started...");

        const data = {
            text: tweet.querySelector('[data-testid="tweetText"]')?.innerText || "",
            author: tweet.querySelector('[data-testid="User-Name"]')?.innerText.split('\n')[0] || "",
            url: tweet.querySelector('a[href*="/status/"]')?.href || window.location.href,
            mediaUrl: tweet.querySelector('[data-testid="tweetPhoto"] img')?.src || null
        };

        btn.innerText = "Saving...";

        const supabaseUrl = await getSupabaseUrl();
        if (supabaseUrl === "YOUR_SUPABASE_EDGE_FUNCTION_URL_HERE") {
            alert("Supabase Edge Function URLが設定されていません。拡張機能の設定でURLを設定してください。");
            btn.innerText = "Error";
            setTimeout(() => { btn.innerText = "Save to Notion"; }, 2000);
            return;
        }

        try {
            const res = await fetch(supabaseUrl, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify(data)
            });

            if (res.ok) {
                btn.innerText = "Saved!";
            } else {
                console.error("Supabase error:", await res.text());
                btn.innerText = "Error";
            }
        } catch (error) {
            console.error("Fetch error:", error);
            btn.innerText = "Fetch Error";
        }

        setTimeout(() => {
            btn.innerText = "Save to Notion";
        }, 2000);
    });

    document.body.appendChild(btn);
}

// 2秒ごとに実行してSPAの画面遷移に対応する
setInterval(createButton, 2000);