[SettingsTab name="Discalimer" icon="ExclamationTriangle" order=1]
void RenderSettingsGeneral()
{
    UI::Text(Icons::ExclamationTriangle + "This plugin is in no way a guarantee!" + Icons::ExclamationTriangle);
    UI::Text("It is impossible* to know for 100%, if an AT is valid or not, just based on map data.");
    UI::Text("An AT might appear legit, but could still be cheated in another way.");
    UI::Text("An AT might also appear cheated, but the time was set on a different copy or version of the (essentially) same map.");
    UI::PushFontSize(12.0f);
    UI::Text("\\$i*Except for older maps which have the validation ghost saved in the map file, but that I do not check.");
    UI::PopFontSize();
}

[Setting category="General" name="Enabled"]
bool S_Enabled = true;

[Setting category="General" name="Show data window"]
bool S_ShowData = false;

[Setting category="General" name="Show/hide data window with game UI"]
bool S_HideWithGame = true;

[Setting category="General" name="Show/hide data window with Openplanet UI"]
bool S_HideWithOP = true;

[Setting category="Notifications" name="Show AT likely valid notification"]
bool S_NotifValid = false;
[Setting category="Notifications" name="Time showing AT likely valid notification [ms]"]
uint S_NotifValidTime = 3000;

[Setting category="Notifications" name="Show AT inconclusive notification"]
bool S_NotifInconclusive = true;
[Setting category="Notifications" name="Time showing AT inconclusive notification [ms]"]
uint S_NotifInconclusiveTime = 3000;

[Setting category="Notifications" name="Show AT likely cheated notification"]
bool S_NotifCheated = true;
[Setting category="Notifications" name="Time showing AT likely cheated notification [ms]"]
uint S_NotifCheatedTime = 3000;