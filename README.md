## [🞂 2-modular-tags.lua](2-modular-tags.lua)
This patch hijacks the "Show calibre tags/keywords" field to display anything you want instead.

<img src="screenshots/FileManager_2025-12-12_100353.png" width="45%" alt="Patch Preview"> <img src="screenshots/FileManager_2025-12-12_100624.png" width="45%" alt="Patch Preview 3">

#### Choose What to Display
Edit the `DISPLAY_MODE` setting at the top of the patch file:

```lua
local DISPLAY_MODE = "pages"
```

**Available modes:**
- `"pages"` - Show page count (e.g., "350 pages")
- `"tags"` - Show original calibre tags
- `"pages_and_tags"` - Show both (e.g., "350 pages | Fiction • Sci-Fi")
- `"custom"` - Use the custom function

#### Font Size
You can adjust how the text looks:

```lua
-- Make text bigger (less offset from author font size)
local CUSTOM_FONT_SIZE_OFFSET = 1

-- Make text smaller (more offset from author font size)  
local CUSTOM_FONT_SIZE_OFFSET = 5

-- Set minimum font size
local CUSTOM_FONT_MIN = 12
```

#### Custom Display Function
For complete control, use `DISPLAY_MODE = "custom"` and edit the `customFormat` function.

**Available bookinfo fields:**
- `bookinfo.pages` - Number of pages
- `bookinfo.title` - Book title
- `bookinfo.authors` - Author(s) 
- `bookinfo.series` - Series name
- `bookinfo.series_index` - Series position
- `bookinfo.keywords` - Original tags/keywords
- `bookinfo.description` - Book description

## [🞂 2-series-first.lua](2-series-first.lua)
This patch reverses the displayed order of author and series, and it keeps both lines separated even with the "Show calibre tags/keywords" option activated. 
