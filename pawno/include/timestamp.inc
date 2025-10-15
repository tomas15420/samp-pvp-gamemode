// ==========================
//  timestamp_dg.inc (no warnings)
// ==========================

// ========== Helper Functions First ==========
stock GetWeekday(day, month, year)
{
    if (month < 3)
    {
        month += 12;
        year--;
    }
    return (day + 2 * month + 3 * (month + 1) / 5 + year + year / 4 - year / 100 + year / 400) % 7;
}

stock bool:IsDST_Europe(day, month, year, hour)
{
    new weekday = GetWeekday(day, month, year);

    // DST začíná: poslední neděle v březnu ve 2:00
    if (month == 3)
    {
        if (weekday == 0 && day + 7 > 31 && hour >= 2)
            return true;
        if (day > 24 && weekday == 0)
            return true;
    }

    // DST končí: poslední neděle v říjnu ve 3:00
    if (month == 10)
    {
        if (weekday == 0 && day + 7 > 31 && hour < 3)
            return true;
        return false;
    }

    return (month > 3 && month < 10);
}

// ========== Main Conversion ==========
stock TimestampToDate(timestamp, &year, &month, &day, &hour, &minute, &second, gmtOffset = 1, useDST = true)
{
    timestamp += gmtOffset * 3600;

    if (useDST)
    {
        new tmpy, tmpmo, tmpd, tmph, tmpm, tmpsec;
        TimestampToDateSimple(timestamp, tmpy, tmpmo, tmpd, tmph, tmpm, tmpsec);

        if (IsDST_Europe(tmpd, tmpmo, tmpy, tmph))
        {
            timestamp += 3600;
        }
    }

    TimestampToDateSimple(timestamp, year, month, day, hour, minute, second);
}

stock TimestampToDateSimple(timestamp, &year, &month, &day, &hour, &minute, &second)
{
    new daysOfMonth[12] = {31,28,31,30,31,30,31,31,30,31,30,31};

    year = 1970;
    for(;;)
    {
        new isLeap = ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0);
        new yearLength = isLeap ? 366 * 86400 : 365 * 86400;

        if (timestamp >= yearLength)
        {
            timestamp -= yearLength;
            year++;
        }
        else break;
    }

    new isLeap = ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0);
    if (isLeap) daysOfMonth[1] = 29;

    month = 1;
    for (new i = 0; i < 12; i++)
    {
        new monthLength = daysOfMonth[i] * 86400;
        if (timestamp >= monthLength)
        {
            timestamp -= monthLength;
            month++;
        }
        else break;
    }

    day = timestamp / 86400 + 1;
    timestamp %= 86400;

    hour = timestamp / 3600;
    timestamp %= 3600;

    minute = timestamp / 60;
    second = timestamp % 60;
}
