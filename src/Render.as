void Render() {
    RenderInfo();
}

void RenderMenu()
{
    if (UI::BeginMenu("\\$F22" + Icons::QuestionCircle	+ "\\$z" + pluginTitle)) {
        if (UI::MenuItem("Check Author Time")) {
            force_notif = true;
            Reset(); // causes the notification to re-appear
        }
        if (UI::MenuItem("Enabled", "", S_Enabled)) S_Enabled = !S_Enabled;
        if (UI::MenuItem("Show data window", "", S_ShowData)) S_ShowData = !S_ShowData;
        if (UI::MenuItem("Settings")) {
            Meta::OpenSettings();
        }
        UI::EndMenu();
    }
}
