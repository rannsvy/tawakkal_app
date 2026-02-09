# EQuran v2 Integration Notes

Base URL: `https://equran.id/api/v2`

## Endpoints Used
- `GET /surat`
  - Surah catalog for all 114 surahs.
- `GET /surat/{nomor}`
  - Surah detail with ayahs and per-ayah audio maps.
- `GET /tafsir/{nomor}`
  - Tafsir entries used for grounded quiz generation.

## Caching Strategy
- Save surah list and detail into local SQLite.
- Use local cache as primary source when offline.
- Refresh on pull-to-refresh or cache miss.

## Mapping Notes
- Reciter keys are string values (`"01"`..`"06"`).
- `deskripsi` can include HTML tags and should be sanitized before display.
- Indonesian translation is provided in `teksIndonesia`.
- English translation is nullable in local schema and can be filled later via curated source.

