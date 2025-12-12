--[[
Modular User Patch for Project: Title - Replace Tags Field

This patch hijacks the "tags" display field to show different metadata.
Simply change the DISPLAY_MODE setting below to choose what to display.

Installation:
1. Save this file as "modular-tags.lua" in: koreader/patches/
2. Restart KOReader
3. Enable "Show calibre tags/keywords" in Project: Title settings
4. The field will show your chosen metadata

Available modes:
- "pages"          : Show page count (e.g., "350 pages")
- "tags"           : Show original calibre tags/keywords  
- "pages_and_tags" : Show both (e.g., "350 pages • tag1 • tag2")
- "publisher"      : Show publisher information
- "language"       : Show book language
- "custom"         : Define your own in the custom function
]]--

local userpatch = require("userpatch")

-- ============================================================================
-- CONFIGURATION - Change these settings
-- ============================================================================ 
local DISPLAY_MODE = "pages"  -- Options: "pages", "tags", "pages_and_tags", "publisher", "language", "custom"

-- Font customization
local CUSTOM_FONT_SIZE_OFFSET = 4  -- Default is 3 (smaller than author font) 
local CUSTOM_FONT_MIN = nil   -- Default is 10 

-- ============================================================================
-- Patch Implementation - Don't edit below unless you know what you're doing
-- ============================================================================ 
local function patchCoverBrowser(CoverBrowser)
    local logger = require("logger")
    local _ = require("gettext")
    local BD = require("ui/bidi")
    local util = require("util")
    local BookInfoManager = require("bookinfomanager")
    local ptutil = require("ptutil")
    
    logger.info("Modular Tags Patch: Loading with DISPLAY_MODE =", DISPLAY_MODE)
    
    -- Cache indexed by FILEPATH, not keywords
    local bookinfo_cache = {}
    
    local original_formatTags = ptutil.formatTags
    
    -- ========================================================================
    -- Format Helpers
    -- ========================================================================
    local function formatPages(bookinfo)
        local pages = bookinfo.pages
        if not pages or pages == 0 then return nil end
        local pages_num = tonumber(pages)
        if not pages_num then return nil end
        
        if pages_num == 1 then
            return "1 " .. _("page")
        else
            return tostring(pages_num) .. " " .. _("pages")
        end
    end
    
    local function formatPublisher(bookinfo)
        if not bookinfo.publisher or bookinfo.publisher == "" then return nil end
        return BD.auto(bookinfo.publisher)
    end
    
    local function formatLanguage(bookinfo)
        if not bookinfo.language or bookinfo.language == "" then return nil end
        return BD.auto(bookinfo.language)
    end
    
    -- ========================================================================
    -- Custom format function (only used if DISPLAY_MODE = "custom")
    -- ======================================================================== 
    local function customFormat(bookinfo, tags_limit)
        local parts = {}
        
        -- Example custom setup
        if bookinfo.publisher then
            table.insert(parts, BD.auto(bookinfo.publisher))
        end
        
        if bookinfo.pages and bookinfo.pages > 0 then
            table.insert(parts, tostring(bookinfo.pages) .. " p")
        end
        
        if #parts > 0 then
            return table.concat(parts, " • ")
        end
        return nil
    end

    local function formatPagesAndTags(bookinfo, tags_limit)
        local parts = {}
        
        local pages_text = formatPages(bookinfo)
        if pages_text then
            table.insert(parts, pages_text)
        end
        
        -- IMPORTANT: Use the backed-up original keywords
        local original_tags = bookinfo._original_keywords
        if original_tags then
             local tags_text = original_formatTags(original_tags, tags_limit)
             if tags_text and tags_text ~= "" then
                 table.insert(parts, tags_text)
             end
        end
        
        if #parts > 0 then
            return table.concat(parts, " | ")
        end
        return nil
    end
    
    -- ========================================================================
    -- Redefine ptutil.formatTags
    -- ========================================================================
    function ptutil.formatTags(keywords_identifier, tags_limit)
        -- 'keywords_identifier' here is actually the filepath we injected in getBookInfo
        -- We use it to look up the real data in our cache.
        
        local bookinfo = bookinfo_cache[keywords_identifier]
        
        -- Fallback: If cache miss (shouldn't happen), try to treat it as standard tags
        if not bookinfo then
            if DISPLAY_MODE == "tags" then
                return original_formatTags(keywords_identifier, tags_limit)
            end
            return nil
        end
        
        local result = nil
        
        if DISPLAY_MODE == "tags" then
            -- Restore original behavior using backed-up tags
            return original_formatTags(bookinfo._original_keywords, tags_limit)
            
        elseif DISPLAY_MODE == "pages" then
            result = formatPages(bookinfo)
            
        elseif DISPLAY_MODE == "pages_and_tags" then
            result = formatPagesAndTags(bookinfo, tags_limit)
            
        elseif DISPLAY_MODE == "publisher" then
            result = formatPublisher(bookinfo)
            
        elseif DISPLAY_MODE == "language" then
            result = formatLanguage(bookinfo)
            
        elseif DISPLAY_MODE == "custom" then
            result = customFormat(bookinfo, tags_limit)
        end
        
        -- If our chosen metadata is empty, return space so line doesn't collapse
        -- (Optional: remove this if you want it to collapse when empty)
        return result or " " 
    end
    
    -- ========================================================================
    -- Patch BookInfoManager
    -- ========================================================================
    local original_getBookInfo = BookInfoManager.getBookInfo
    
    function BookInfoManager:getBookInfo(filepath, get_cover)
        local bookinfo = original_getBookInfo(self, filepath, get_cover)
        
        if bookinfo then
            if not bookinfo._original_keywords then
                bookinfo._original_keywords = bookinfo.keywords
            end
            
            -- This ensures 'keywords' is never nil, forcing KOReader to call formatTags.
            bookinfo.keywords = filepath
            bookinfo_cache[filepath] = bookinfo
        end
        
        return bookinfo
    end
    
    -- ========================================================================
    -- Apply Font Settings
    -- ========================================================================
    if CUSTOM_FONT_SIZE_OFFSET then
        ptutil.list_defaults.tags_font_offset = CUSTOM_FONT_SIZE_OFFSET
    end
    
    if CUSTOM_FONT_MIN then
        ptutil.list_defaults.tags_font_min = CUSTOM_FONT_MIN
    end
    
    logger.info("Modular Tags Patch: Applied.")
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)