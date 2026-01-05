document.addEventListener('DOMContentLoaded', () => {
    const supabaseUrlInput = document.getElementById('supabaseUrl');
    const saveButton = document.getElementById('saveButton');
    const statusDiv = document.getElementById('status');

    // Load saved settings
    chrome.storage.sync.get(['supabaseUrl'], (result) => {
        if (result.supabaseUrl) {
            supabaseUrlInput.value = result.supabaseUrl;
        } else {
            // For development, if .env is used, we can set a default from there if a build process is in place.
            // Otherwise, it's expected to be set by the user in the options page.
            // This is a placeholder for potential future integration with a build process and .env.
            supabaseUrlInput.value = "YOUR_SUPABASE_EDGE_FUNCTION_URL_HERE";
        }
    });

    // Save settings
    saveButton.addEventListener('click', () => {
        const supabaseUrl = supabaseUrlInput.value;
        chrome.storage.sync.set({ supabaseUrl: supabaseUrl }, () => {
            statusDiv.textContent = 'Settings saved!';
            setTimeout(() => {
                statusDiv.textContent = '';
            }, 2000);
        });
    });
});
