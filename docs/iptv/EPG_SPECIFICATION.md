# Saiful IPTV Player: XMLTV EPG Specification

## 1. Overview

The Electronic Program Guide (EPG) module ingests standard XMLTV data feeds to provide real-time programming schedules, program progress indicators, genre categorization, and chronological timeline navigation across channels.

Source code implementation:
- Parser & Index: [`lib/features/iptv/parsers/xmltv_parser.dart`](file:///d:/Saiful%20iptv%20player/lib/features/iptv/parsers/xmltv_parser.dart)
- Model: [`lib/features/iptv/models/epg_program.dart`](file:///d:/Saiful%20iptv%20player/lib/features/iptv/models/epg_program.dart)
- UI Presentation: [`lib/features/epg/presentation/epg_guide_page.dart`](file:///d:/Saiful%20iptv%20player/lib/features/epg/presentation/epg_guide_page.dart)

---

## 2. XMLTV Schema Compliance

The parser processes valid XMLTV XML structures containing `<tv>`, `<channel>`, and `<programme>` elements:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<tv generator-info-name="Saiful IPTV EPG Engine">
  <channel id="aljazeera.en">
    <display-name>Al Jazeera English HD</display-name>
    <icon src="https://logos.server.com/aje.png"/>
  </channel>

  <programme start="20261111200000 +0600" stop="20261111210000 +0600" channel="aljazeera.en">
    <title lang="en">Newshour Live</title>
    <desc lang="en">In-depth international news reporting, investigative stories, and global financial analysis.</desc>
    <category lang="en">News</category>
    <icon src="https://images.server.com/newshour.jpg"/>
  </programme>
</tv>
```

### 2.1 Supported Fields
- **`<channel id="...">`**: Unique identifier matched against `tvg-id` in M3U playlists.
- **`<display-name>`**: Fallback channel name when unlisted in playlist.
- **`<icon src="...">`**: Channel or program thumbnail.
- **`<programme start="..." stop="..." channel="...">`**:
  - `start` & `stop`: Schedule air timestamps.
  - `<title>`: Episode or program title.
  - `<desc>`: Synopsis and description.
  - `<category>`: Program category (News, Sports, Movie, Documentary).

---

## 3. Timezone Normalization Architecture

XMLTV timestamps follow the standard ISO 8601 variant:
`YYYYMMDDHHMMSS +HHMM` or `YYYYMMDDHHMMSS -HHMM` or `YYYYMMDDHHMMSS Z`

Example: `20261111200000 +0600`
1. Extracts Date and Time: `2026-11-11 20:00:00`.
2. Extracts Timezone Offset: `+0600` (positive 6 hours = Dhaka Standard Time).
3. Adjusts to Coordinated Universal Time (UTC): `20:00:00 - 06:00:00 = 14:00:00 UTC`.
4. Stores in memory as standardized UTC `DateTime` objects, preventing cross-timezone schedule drift regardless of the client device's local clock.

---

## 4. Query & Indexing Architecture

The `EpgIndex` provides $O(1)$ and $O(\log N)$ access to program schedules:
- **`getCurrentProgram(channelTvgId, [now])`**: Evaluates `startTime <= now && now < endTime` to return the currently broadcasting show.
- **`getNextProgram(channelTvgId, [now])`**: Finds the immediate subsequent program in chronological order.
- **`getScheduleForDate(channelTvgId, date)`**: Returns the 24-hour program schedule for timeline rendering.
- **`progressRatio([now])`**: Computes `(elapsed / totalDuration)` as a scalar between `0.0` and `1.0` for visual progress bars.

---

## 5. Security & Malicious XML Prevention

To prevent XML External Entity (XXE) and recursive entity expansion attacks ("Billion Laughs"):
1. The parser strips any `<!DOCTYPE>` or `<!ENTITY>` definitions prior to tokenization.
2. Direct external entity resolution is disabled.
3. Node recursion is bounded by strict attribute and tag regex matchers, preventing thread blocking or CPU starvation.

