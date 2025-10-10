[SettingsTab name="Discalimer" icon="ExclamationTriangle" order=1]
void RenderSettingsGeneral()
{
    UI::Text(Icons::ExclamationTriangle + "This plugin is in no way a guarantee!" + Icons::ExclamationTriangle);
    UI::Text("It is impossible* to know for 100%, if an AT is valid or not, just based on map data.");
    UI::Text("An AT might appear legit, but could still be set in another way.");
    UI::Text("An AT might also appear to be set by a plugin, but the time could come from a different copy or version of (essentially) the same map.");
    UI::PushFontSize(12.0f);
    UI::Text("\\$i*Except for older maps which have the validation ghost saved in the map file, but that I do not check.");
    UI::PopFontSize();
}

// General Settings
[Setting category="General" name="Enabled"]
bool S_Enabled = true;

[Setting category="General" name="Show data window"]
bool S_ShowData = false;

[Setting category="General" name="Show/hide data window with game UI"]
bool S_HideWithGame = true;

[Setting category="General" name="Show/hide data window with Openplanet UI"]
bool S_HideWithOP = true;

[Setting category="General" name="Hide if AT is already beaten"]
bool S_HideIfATBeaten = true;

// Notification Settings
[Setting category="Notifications" name="Show AT likely valid notification"]
bool S_NotifValid = false;
[Setting category="Notifications" name="Time showing AT likely valid notification [ms]"]
uint S_NotifValidTime = 3000;

[Setting
    category="Notifications"
    name="Show AT Ghost (GPS) is likely present in the map"
    description="The plugin can only check the 'race time' of the ghost in the mediatracker clip, not if it is valid or driven on the same (version of the) map"
]
bool S_NotifIfGPS = true;
[Setting category="Notifications" name="Time showing AT GPS [ms]"]
uint S_NotifGPSTime = 3000;

[Setting category="Notifications" name="Show AT inconclusive notification"]
bool S_NotifInconclusive = true;
[Setting category="Notifications" name="Time showing AT inconclusive notification [ms]"]
uint S_NotifInconclusiveTime = 3000;

[Setting category="Notifications" name="Show AT likely set by a plugin notification"]
bool S_NotifInvalid = true;
[Setting category="Notifications" name="Time showing AT likely set by a plugin notification [ms]"]
uint S_NotifInvalidTime = 3000;