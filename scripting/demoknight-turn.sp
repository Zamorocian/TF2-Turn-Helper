// i don't understand game maths and i wrote this very quickly

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <tf2>
#include <tf2_stocks>

#define M_E        2.71828182845904523536   // e
#define M_LOG2E    1.44269504088896340736   // log2(e)
#define M_LOG10E   0.434294481903251827651  // log10(e)
#define M_LN2      0.693147180559945309417  // ln(2)
#define M_LN10     2.30258509299404568402   // ln(10)
#define M_PI       3.14159265358979323846   // pi
#define M_PI_2     1.57079632679489661923   // pi/2
#define M_PI_4     0.785398163397448309616  // pi/4
#define M_1_PI     0.318309886183790671538  // 1/pi
#define M_2_PI     0.636619772367581343076  // 2/pi
#define M_2_SQRTPI 1.12837916709551257390   // 2/sqrt(pi)
#define M_SQRT2    1.41421356237309504880   // sqrt(2)
#define M_SQRT1_2  0.707106781186547524401  // 1/sqrt(2)

Handle sync;
bool toggle[MAXPLAYERS + 1];
bool anglemeter[MAXPLAYERS + 1];
bool extra[MAXPLAYERS + 1];
bool speedometer[MAXPLAYERS + 1];
bool vspeedometer[MAXPLAYERS + 1];
bool target[MAXPLAYERS + 1];
bool ninetytarget[MAXPLAYERS + 1];

float lastanglevector[MAXPLAYERS + 1];

float lastspeed[MAXPLAYERS + 1];
float lastchangedspeed[MAXPLAYERS + 1];

public void OnPluginStart()
{
    sync = CreateHudSynchronizer();
    RegConsoleCmd("chargetoggle", chargetoggle);
    RegConsoleCmd("angletoggle", angletoggle);
    RegConsoleCmd("extratoggle", extratoggle);
    RegConsoleCmd("speedtoggle", speedtoggle);
    RegConsoleCmd("vspeedtoggle", vspeedtoggle);
    RegConsoleCmd("targettoggle", targettoggle);
    RegConsoleCmd("ninetytargettoggle", ninetytargettoggle);
}

Action chargetoggle(int client, int args)
{
    toggle[client] = !toggle[client];
    return Plugin_Continue;
}

Action angletoggle(int client, int args)
{
    anglemeter[client] = !anglemeter[client];
    return Plugin_Continue;
}

Action extratoggle(int client, int args)
{
    extra[client] = !extra[client];
    return Plugin_Continue;
}

Action speedtoggle(int client, int args)
{
    speedometer[client] = !speedometer[client];
    return Plugin_Continue;
}

Action vspeedtoggle(int client, int args)
{
    vspeedometer[client] = !vspeedometer[client];
    return Plugin_Continue;
}

Action targettoggle(int client, int args)
{
    target[client] = !target[client];
    return Plugin_Continue;
}

Action ninetytargettoggle(int client, int args)
{
    ninetytarget[client] = !ninetytarget[client];
    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    // Change these if you want toggles on or off by default
    toggle[client] = true;
    anglemeter[client] = false;
    extra[client] = false;
    speedometer[client] = true;
    vspeedometer[client] = true;
    target[client] = true;
    ninetytarget[client] = true;
}

//int abs(int x)
//{
//    int mask = x >> 32 - 1;
//    return (x + mask) ^ mask;
//}

float threesixtywraparound(float difference)
{
    if (difference <= 0.00)
        difference += 360.00;
    else if (difference >= 360.00)
        difference -= 360.00;
    return difference;
}

public void OnGameFrame()
{
    for (int i = 1; i <= MaxClients; ++i)
    {
        if (IsValidEntity(i) && IsClientInGame(i))
        {
            if (toggle[i])
            {
                float clientEyeAngles[3];
                float m_vecAbsVelocity[3];
                float angleVector[3];

                GetClientEyeAngles(i, clientEyeAngles);
                GetEntPropVector(i, Prop_Data, "m_vecAbsVelocity", m_vecAbsVelocity);
                NormalizeVector(m_vecAbsVelocity, m_vecAbsVelocity);
                m_vecAbsVelocity[2] = 0.00;
                GetVectorAngles(m_vecAbsVelocity, angleVector);
                if (clientEyeAngles[1] < 0)
                    clientEyeAngles[1]  += 360.00;
            
                // there's 
                float difference = clientEyeAngles[1] - lastanglevector[i]; // Need to use the angle vector from the previous tick because GetClientEyeAngles gives info from the previous tick for some reason
                lastanglevector[i] = angleVector[1];
                if (difference <= -180.00)
                    difference += 360.00;
                else if (difference >= 180.00)
                    difference -= 360.00;
                int angle = RoundFloat(difference); // Angle turned away from velocity, spans -180 to 180

                GetEntPropVector(i, Prop_Data, "m_vecAbsVelocity", m_vecAbsVelocity);
                float totalspeed = GetVectorLength(m_vecAbsVelocity);
                float vspeed = m_vecAbsVelocity[2]
                m_vecAbsVelocity[2] = 0.00;
                float speed = GetVectorLength(m_vecAbsVelocity);

                // https://steamcommunity.com/sharedfiles/filedetails/?id=184184420
                float limit = 750.00;
                float accel = 7500.00;
                float ticklength = 0.015;
                // Checking for holding the skullcutter, which changes the limit and acceleration
                new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
                if (IsPlayerAlive(i) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 172) // Weapon is the Skullcutter
                {
                    limit = 637.50;
                    accel = 6375.00;
                    int primaryweapon = GetPlayerWeaponSlot(i, 0); // 0 is the int which means primary weapon
                    if (primaryweapon == -1) // Using booties or bootlegger (they don't count as a weapon so return as -1)
                    {
                        limit *= 1.1;
                        accel *= 1.1;
                    }
                }
                float optimalf = ArcCosine((limit - FloatAbs(ticklength * accel)) / FloatAbs(speed)) * (180 / M_PI);
                float minimumf = ArcCosine(limit / FloatAbs(speed)) * (180 / M_PI);
                float minimumoptimalrange = optimalf - minimumf;
                int optimal = RoundFloat(optimalf) // Spans ~30 to ~70
                int minimum = RoundFloat(minimumf) // Spans ~0 to ~70
                bool reducedaccel = vspeed > 0.01 && vspeed < 249.99;
                float absdifference = FloatAbs(difference);
                
                // Always show yellowy green while under the forward speed limit, and not aiming backwards
                if (TF2_IsPlayerInCondition(i, TFCond_Charging) && speed < limit + 0.01 && absdifference <= 92.00)
                {
                    if (reducedaccel) 
                         SetHudTextParams(-1.0, 0.48, 1.00, 92, 255, 64, 255, 0, 6.0, 0.0, 0.0); // white yellowy green
                    else SetHudTextParams(-1.0, 0.48, 1.00, 32, 255, 0, 255, 0, 6.0, 0.0, 0.0); // yellowy green
                }
                else if (!TF2_IsPlayerInCondition(i, TFCond_Charging) || absdifference < minimumf || absdifference > 92.00 || speed - lastspeed[i] < 10.00 && GetGameTime() - lastchangedspeed[i] >= 0.1)
                {
                    if (reducedaccel) 
                         SetHudTextParams(-1.0, 0.48, 1.00, 255, 64, 64, 255, 0, 6.0, 0.0, 0.0);  // white red
                    else SetHudTextParams(-1.0, 0.48, 1.00, 255, 0, 0, 255, 0, 6.0, 0.0, 0.0);  // red
                }
                else if (absdifference < optimalf - 0.67 * minimumoptimalrange)
                {
                    if (reducedaccel) 
                         SetHudTextParams(-1.0, 0.48, 1.00, 159, 255, 64, 255, 0, 6.0, 0.0, 0.0); // white yellow
                    else SetHudTextParams(-1.0, 0.48, 1.00, 127, 255, 0, 255, 0, 6.0, 0.0, 0.0); // yellow
                }
                else if (absdifference < optimalf - 0.33 * minimumoptimalrange)
                {
                    if (reducedaccel) 
                         SetHudTextParams(-1.0, 0.48, 1.00, 64, 255, 159, 255, 0, 6.0, 0.0, 0.0); // white turquoise
                    else SetHudTextParams(-1.0, 0.48, 1.00, 0, 255, 127, 255, 0, 6.0, 0.0, 0.0); // turquoise
                }
                else if (absdifference < optimalf + 0.33 * minimumoptimalrange)
                {
                    if (reducedaccel) 
                         SetHudTextParams(-1.0, 0.48, 1.00, 64, 255, 64, 255, 0, 6.0, 0.0, 0.0); // white green
                    else SetHudTextParams(-1.0, 0.48, 1.00, 0, 255, 0, 255, 0, 6.0, 0.0, 0.0); // green
                }
                else if (absdifference < optimalf + 1.00 * minimumoptimalrange)
                {
                    if (reducedaccel) 
                         SetHudTextParams(-1.0, 0.48, 1.00, 64, 64, 255, 255, 0, 6.0, 0.0, 0.0); // white blue
                    else SetHudTextParams(-1.0, 0.48, 1.00, 0, 0, 255, 255, 0, 6.0, 0.0, 0.0); // blue
                }
                else
                {
                    if (reducedaccel) 
                         SetHudTextParams(-1.0, 0.48, 1.00, 255, 64, 159, 255, 0, 6.0, 0.0, 0.0); // white purple
                    else SetHudTextParams(-1.0, 0.48, 1.00, 255, 0, 125, 255, 0, 6.0, 0.0, 0.0); // purple
                }

                char anglebuffer[256];
                char extrabuffer[256];
                char speedbuffer[256];
                char vspeedbuffer[256];
                char targetbuffer[256];

                Format(anglebuffer, sizeof(anglebuffer), "\n%i", speed == 0 ? 0 : angle);
                Format(extrabuffer, sizeof(extrabuffer), "\nmin: %i, optimal: %i", speed < limit ? 0 : minimum, speed < limit - accel * ticklength ? 0 : optimal);
                Format(speedbuffer, sizeof(speedbuffer), "\nh%i", RoundFloat(speed));
                Format(vspeedbuffer, sizeof(vspeedbuffer), "\nv%i", RoundFloat(vspeed));
                // Putting 135 spaces into it (hardcoded so change this too if you want to change the charstodisplay)
                Format(targetbuffer, sizeof(targetbuffer), "                                                                                                                                       ");
                int charstodisplay = 135
                float mappingratio = (charstodisplay-1) / 360.00 // Converts the 360 degree angles to a screen width of chars (~135 letters on my screen) to be used as indexes
                float threesixtydifference = difference + 180.00 // Spans 0 to 360
                if (speed > 0)
                {
                    int angleindex = RoundFloat(threesixtydifference * mappingratio)
                    int negminindex = RoundFloat(threesixtywraparound(threesixtydifference - minimumf) * mappingratio)
                    int posminindex = RoundFloat(threesixtywraparound(threesixtydifference + minimumf) * mappingratio)
                    int negoptimalindex = RoundFloat(threesixtywraparound(threesixtydifference - optimalf) * mappingratio)
                    int posoptimalindex = RoundFloat(threesixtywraparound(threesixtydifference + optimalf) * mappingratio)
                    int negninetyindex = RoundFloat(threesixtywraparound(threesixtydifference - 90.0) * mappingratio)
                    int posninetyindex = RoundFloat(threesixtywraparound(threesixtydifference + 90.0) * mappingratio)
                    if (angleindex >= 0 && angleindex < charstodisplay)
                        targetbuffer[angleindex] = 'v'
                    if (negminindex >= 0 && negminindex < charstodisplay)
                        targetbuffer[negminindex] = '-';
                    if (posminindex >= 0 && posminindex < charstodisplay)
                        targetbuffer[posminindex] = '-'
                    if (negoptimalindex >= 0 && negoptimalindex < charstodisplay)
                        targetbuffer[negoptimalindex] = '|'
                    if (posoptimalindex >= 0 && posoptimalindex < charstodisplay)
                        targetbuffer[posoptimalindex] = '|'
                    if (ninetytarget[i] && totalspeed >= 300)
                    {
                        if (negninetyindex >= 0 && negninetyindex < charstodisplay)
                            targetbuffer[negninetyindex] = '='
                        if (posninetyindex >= 0 && posninetyindex < charstodisplay)
                            targetbuffer[posninetyindex] = '='
                    }
                }

                ShowSyncHudText(i, sync, "%s%s%s%s%s", target[i] ? targetbuffer : "", speedometer[i] ? speedbuffer : "", vspeedometer[i] ? vspeedbuffer : "", anglemeter[i] ? anglebuffer : "", extra[i] ? extrabuffer : "");

                if (speed - lastspeed[i] > 0.5 || lastspeed[i] - speed > 0.5)
                {
                    lastspeed[i] = speed;
                    lastchangedspeed[i] = GetGameTime();
                }
            }
        }
    }
}