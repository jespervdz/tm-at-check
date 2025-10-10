const string S_AT_GPS_Header = "\\$o\\$sMap likely has AT GPS  \\$z\\$n\\$555" + pluginTitle;
const string S_AT_GPS_Text = "There is a ghost present with AT time. \nReminder: it could still be invalid!";
const string S_AT_Invalid_Header = "\\$o\\$sAT set by a plugin  \\$z\\$n\\$555" + pluginTitle;
const string S_AT_Invalid_Text = "AT likely set by a plugin\nReminder: it could still be valid!";
const string S_AT_Valid_Header = "\\$o\\$sAT Valid  \\$z\\$n\\$555" + pluginTitle;
const string S_AT_Valid_Text = "AT likely valid\nReminder: it could still be invalid!";
const string S_AT_Inconclusive_Header = "\\$o\\$sAT inconclusive  \\$z\\$n\\$555" + pluginTitle;
const string S_AT_Inconclusive_Text = "AT could be valid or invalid";

const vec4 S_ColorGPS = vec4(0.5f, 0.75f, 0.0f, 1.0f);
const vec4 S_ColorInvalid = vec4(1.0f, 0.0f, 0.0f, 1.0f);
const vec4 S_ColorValid = vec4(0.0f, 0.7f, 0.0f, 1.0f);
const vec4 S_ColorInconclusive = vec4(1.0f, 0.5f, 0.0f, 1.0f);
const vec4 S_ColorError = vec4(0.5f, 0.5f, 0.5f, 1.0f);

void NotifyGPS() {
    if (S_NotifIfGPS || force_notif)
        UI::ShowNotification(S_AT_GPS_Header, S_AT_GPS_Text, S_ColorGPS, S_NotifGPSTime);
}

void NotifyInvalid() {
    if (S_NotifInvalid || force_notif)
        UI::ShowNotification(S_AT_Invalid_Header, S_AT_Invalid_Text, S_ColorInvalid, S_NotifInvalidTime);
}

void NotifyValid() {
    if (S_NotifValid || force_notif)
        UI::ShowNotification(S_AT_Valid_Header, S_AT_Valid_Text, S_ColorValid, S_NotifValidTime);
}

void NotifyInconclusive() {
    if (S_NotifInconclusive || force_notif)
        UI::ShowNotification(S_AT_Inconclusive_Header, S_AT_Inconclusive_Text, S_ColorInconclusive, S_NotifInconclusiveTime);
}

void Notify()
{
    // first check GPS, else check metadata
    if (ATGhostPresent())
        NotifyGPS();
    else if (ATInvalid())
        NotifyInvalid();
    else if (ATValid())
        NotifyValid();
    else
        NotifyInconclusive();

    force_notif = false;
}