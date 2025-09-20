void AddTableRow(const string &in variable, const string &in value)
{
    UI::TableNextRow();
    UI::TableNextColumn();
    UI::Text(variable);
    UI::TableNextColumn();
    UI::Text(value);
    if (UI::IsItemHovered(UI::HoveredFlags::None)) {
        UI::SetMouseCursor(UI::MouseCursor::Hand);
    }
    if (UI::IsItemClicked()) {
        IO::SetClipboard(value);
        UI::ShowNotification(pluginTitle, "Copied the value!", S_ColorError, 1500);
    }
}

void RenderInfo() {
    if (S_Enabled && S_ShowData && app.RootMap !is null) {
        if ((S_HideWithGame && !UI::IsGameUIVisible()) || (S_HideWithOP and !UI::IsOverlayShown())) return;

        if (UI::Begin(pluginTitle + " Info", S_ShowData, UI::WindowFlags::None)) {

            if (UI::BeginTable("atCheckTable", 2, UI::TableFlags::SizingStretchSame)) {
                UI::TableSetupColumn("Variable", UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("Value", UI::TableColumnFlags::WidthStretch);
                UI::TableHeadersRow();

                AddTableRow("Metadata CP times:", Json::Write(times.ToJson()));
                AddTableRow("CPs in map:", tostring(CPsToFinish));
                AddTableRow("CPs in metadata:", tostring(CPsMetadata));
                AddTableRow("CP count matches:", tostring(cpCntMatch));
                AddTableRow("Authortime:", tostring(authorTime));
                AddTableRow("Metadata AT:", tostring(metadataAT));
                AddTableRow("AT metadata match:", tostring(lastIsAT));

                UI::EndTable();
            }

        }
        UI::End();
    }
}