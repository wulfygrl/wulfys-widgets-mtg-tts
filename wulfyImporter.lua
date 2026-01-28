moduleVersion = 0.05
pID = "w_importer"
-- Wulfy Importer by @wulfygrl
-- Built for use with the Encoder by Tipsy Hobbit (steam_id: 13465982)
--   (but will work to import cards without it)
-- Necessary for supporting my Wulfy Widgets modules.

GIT_BASEURL = ('https://raw.githubusercontent.com/%s/%s/refs/heads/%s/'):format(
  'wulfygrl',
  'wulfys-widgets-mtg-tts',
  'main')
MOD_DATA = {
  modVersion = moduleVersion,
  modID = pID,
  modName = 'Wulfy Importer',
  gitFileName = 'wulfyImporter.lua',
  colors = { init = { primary = 'h195', secondary = 'h30' } },
  encData = {
    pID = pID
  }
}
-- [[ UNIVERSAL ]] --

function checkUtils() return Global.getVar('wulfy_utils') ~= nil end
function spawnUtils(cb)
  local giturl = GIT_BASEURL .. 'wulfyUtils.lua'
  WebRequest.get(giturl, function(wr)
    if wr.is_error then
      error('Failed to fetch utils. Wulfy mods will not function.')
    end
    local utils_data = self.getData()
    utils_data.Nickname = 'Wulfy Utils'
    utils_data.Description = 'wulfy_utils'
    utils_data.LuaScript = wr.text
    utils_data.LuaScriptState = ''
    spawnObjectData({
      data = utils_data,
      position = self.getPosition() + Vector(1, 0, 0),
      callback_function = function(o)
        o.interactable = false
        o.locked = true
        cb()
      end
    })
  end)
end
function getExternalObject(var_name)
  local o = {}
  setmetatable(o, {
    __call = function() return Global.getVar(var_name) end,
    __index = function(t, k)
      local obj = Global.getVar(var_name)
      if obj == nil then error('Object named '.. var_name .. ' not found.') end
      return function(...)
        return obj.call(k, {obj = self, data = MOD_DATA, args = { ... } })
      end
    end
  })
  return o
end
local utils = getExternalObject('wulfy_utils')

-- Log message wrapper for this module.
function wLog(msg, pre, tags)
  utils().call('log_wrapper', {
    pID = MOD_DATA.modID,
    color = MOD_DATA.colors.primary.mlight,
    msg = msg,
    pre = pre,
    tags = tags
  })
end

-- Same but for debug messages.
function wDebug(msg, pre, tags) if DEBUG then wLog(msg, pre, tags) end end

-- register this module
function registerModule()
  MOD_DATA.isRegistered = utils().call('registerWulfyMod', MOD_DATA.encData)
  chipButtons()
end

-- unregister this module
function unregisterModule()
  MOD_DATA.isRegistered = utils().call('unregisterWulfyMod', MOD_DATA.encData)
  chipButtons()
end

-- update this module
function selfUpdate() utils().call('updateCheck', { o = self, d = MOD_DATA }) end

function chipButtons()
  colors() -- init colors just in case
  utils().call('drawChipButtons', { o = self, d = MOD_DATA })
end

-- return this module's colors, initializing them if needed.
function colors()
  if MOD_DATA.colors.init ~= nil then
    MOD_DATA.colors = utils().call('getColors', MOD_DATA.colors.init)
  end
  return MOD_DATA.colors
end

function onLoad(save_data)
  local function init() initMod(save_data) end
  -- if this is utils obj or we already have utils, skip to init.
  if pID == 'w_utils' or checkUtils() then
    init()
  else
    Wait.condition(
      init, checkUtils, 2, function() spawnUtils(init) end)
  end
end

function onSave()
  save_data = (saveMod ~= nil and saveMod() or {})
  local c = checkUtils()
  if c then
    save_data.utilsGUID = (utils()).getGUID() 
  end
  return utils.jsonEncode(save_data)
end

-- [[ END UNIVERSAL ]] --

-- [[ Data Load/Save ]] --
function initMod(s) chipButtons() end

function saveMod() return {} end

-- [[ Chat commands ]] --
chatFlag = 'w'
chatCmds = { import = 'getDeck', test = 'testDeckerDFC' }
function onChat(msg, ply)
  local flag, cmd, args = msg:match('%s*(%S+)%s*(%S+)%s?(.*)$')
  if flag == nil or flag:lower() ~= chatFlag then return end
  if cmd == nil or chatCmds[cmd:lower()] == nil then return end
  self.call(chatCmds[cmd:lower()], { ply = ply, args = args })
end

API_INFO = {
  {
    name = 'moxfield',
    deckURI = 'https://api2.moxfield.com/v3/decks/all/%s/',
    idFormat = '^https://moxfield.com/decks/(.+)$',
    parseFunc = 'parseMoxfield'
  },
  {
    name = 'archidekt',
    deckURI = 'https://archidekt.com/api/decks/%s/',
    idFormat = '^https://archidekt.com/decks/(%d+).*$',
    parseFunc = 'parseArchidekt',
    sections = { 'Commander', 'Sideboard', 'Maybeboard' }
  }
}
function getDeck(p)
  local url = p.args or ''
  local info, deckID
  for _, api in ipairs(API_INFO) do
    deckID = url:match(api.idFormat)
    if deckID ~= nil then
      info = api
      break
    end
  end
  if info == nil then
    wLog('Deck import error: input does not match a supported URL.', '', 'error')
    return
  end
  uri = info.deckURI:format(deckID)
  self.call(info.parseFunc, { uri = uri, ply = p.ply })
end

function parseMoxfield(p)
  local uri = p.uri
  local headers = { ["User-Agent"] = 'TableTopSimulator' }
  local start = os.clock()
  WebRequest.custom(uri, 'GET', true, nil, headers, function(wr)
    if wr.is_error or wr.response_code ~= 200 then
      wLog('Deck not found or API error. Code: ' .. wr.response_code)
      return
    end
    local deckData = utils.jsonDecode(wr.text)
    local sections = {}
    local numBoards = 0
    for board, data in pairs(deckData.boards) do
      n = board:lower()
      if n == 'mainboard' then n = 'deck' end
      if data.count > 0 then
        numBoards = numBoards + 1
        sections[n] = { cards = {}, count = 0 }
        for _, card in pairs(data.cards) do
          sections[n].count = sections[n].count + 1
          table.insert(sections[n].cards, {
            id = card.card.scryfall_id,
            code = card.card.set,
            number = card.card.cn,
            qty = card.quantity
          })
        end
      end
    end
    local deck = {
      name = deckData.name,
      pileCount = numBoards,
      piles = sections
    }
    local endtime = os.clock()
    wLog(endtime - start)
    fetchDeckData({ deck = deck, ply = p.ply })
  end)
end

function parseArchidekt(p)
  local uri = p.uri
  local start = os.clock()
  WebRequest.get(uri, function(wr)
    if wr.is_error or wr.response_code ~= 200 then
      wLog('Deck not found or API error. Code: ' .. wr.response_code)
      return
    end
    local deckData = utils.jsonDecode(wr.text)
    local sections = {}
    local catMap = {}
    local numBoards = 0
    for i, cat in ipairs(deckData.categories) do
      local n = cat.name:lower()
      if n == 'commander' or n == 'sideboard' or n == 'maybeboard' then
        numBoards = numBoards + 1
        sections[n] = { cards = {}, count = 0 }
        catMap[n] = n
      elseif cat.includedInDeck then
        if sections['deck'] == nil then
          wLog('created deck')
          sections['deck'] = { cards = {}, count = 0 }
          numBoards = numBoards + 1
        end
        catMap[n] = 'deck'
      end
    end
    for _, card in pairs(deckData.cards) do
      local cardCats = card.categories
      local section = nil
      for _, cat in ipairs(cardCats) do
        c = cat:lower()
        -- If valid category, add to deck (set section)
        if catMap[c] ~= nil and sections[catMap[c]] ~= nil then
          section = catMap[c]
        end
        -- If special category (not "deck"), break
        if sections[c] ~= nil then break end
      end
      if section ~= nil then
        sections[section].count = sections[section].count + 1
        table.insert(sections[section].cards, {
          code = card.card.edition.editioncode,
          number = card.card.collectorNumber,
          qty = card.quantity
        })
      end
    end
    for name, section in pairs(sections) do
      if #(section.cards) < 1 then sections[name] = nil end
    end
    local deck = {
      name = deckData.name,
      pileCount = numBoards,
      piles = sections
    }
    local endtime = os.clock()
    wLog(endtime - start)
    fetchDeckData({ deck = deck, ply = p.ply })
  end)
end

scryfall_id = 'https://api.scryfall.com/cards/%s'
scryfall_set_cn = scryfall_id:format('%s/%s')
scryfall_name = scryfall_id:format('named?exact=%s')
scryfall_name_set = scryfall_name:format('%s&set=%s')

function fetchDeckData(p)
  local deck = p.deck
  local ply = p.ply
  local piles = {}
  local idx = 0
  for name, pile in pairs(deck.piles) do
    piles[name] = {
      expected = pile.count,
      fetched = 0,
      cards = {},
      idx = idx
    }
    wLog(name)
    local i = 1
    for _, cardinfo in ipairs(pile.cards) do
      local scryfall_uri = ''
      if cardinfo.id ~= nil then
        scryfall_uri = scryfall_id:format(cardinfo.id)
      elseif cardinfo.number ~= nil and cardinfo.code ~= nil then
        scryfall_uri = scryfall_set_cn:format(cardinfo.code, cardinfo.number)
      elseif cardinfo.name ~= nil then
        if cardinfo.code ~= nil then
          scryfall_uri = scryfall_name_set:format(cardinfo.name, cardinfo.code)
        else
          scryfall_uri = scryfall_name:format(cardinfo.name)
        end
      end
      scryfall_headers = { ["User-Agent"] = 'TableTopSimulator', ["Accept"] = "application/json;q=0.9,*/*;q=0.8" } 
      WebRequest.custom(scryfall_uri, 'GET', true, nil, scryfall_headers, function(wr)
        if wr.is_error or wr.response_code ~= 200 then
          local error_msg = 'Scryfall query failed.\n  URL: %s\n  Response code: %s'
          wLog(error_msg:format(scryfall_uri, wr.response_code))
          if cardinfo.name then
            wLog(cardinfo.name)
          end
          piles[name].expected = piles[name].expected - 1
          return
        end
        card_json = utils.jsonDecode(wr.text)
        for j = 1, cardinfo.qty do
          piles[name].cards[i] = processScryfallData(card_json)
          i = i+1
        end
        -- piles[name].cards[i] = processScryfallData(card_json)
        piles[name].fetched = piles[name].fetched + 1
      end)
      -- wLog('set: '.. cardinfo.code .. ' | cn: '..cardinfo.number..' | qty: '..cardinfo.qty)
    end
    Wait.condition(function()
      n = piles[name].idx
      pos = {3*(((-1)^n) * math.floor((n+1)/2)), 2, 0}
      if #piles[name].cards == 1 then
        piles[name].cards[1]:spawn({ position = pos })
      else
        piles[name].deck = deckerDeck(piles[name].cards, { name = deck.name .. ' ' ..name })
        piles[name].deck:spawn({ position = pos })
      end
    end, function()
      return piles[name].fetched == piles[name].expected
    end,
    10,
    function() wLog('Error fetching pile: '..name) end
  )
  idx = idx + 1
end
end

--[[TESTING]]
function testDeckerDFC(p)
  local b = 'https://steamusercontent-a.akamaihd.net/ugc/1647720103762682461/35EF6E87970E2A5D6581E7D96A99F8A575B7A15F/'
  local f1 = 'https://cards.scryfall.io/large/front/f/9/f953fad3-0cd1-48aa-8ed9-d7d2e293e6e2.jpg?1637114341'
  local f2 = 'https://cards.scryfall.io/large/back/f/9/f953fad3-0cd1-48aa-8ed9-d7d2e293e6e2.jpg?1637114341'
  local a1 = deckerAsset(f1, b, { width = 1, height = 1 })
  local a2 = deckerAsset(f2, b, { width = 1, height = 1 })
  local s1 = deckerCard(a1, 1, 1, { name = 'Tovolar, Dire Overlord', AltLookAngle = Vector(0, 180, 180) }) --{x=0,y=180,z=180}})
  local s2 = deckerCard(a2, 1, 1, { name = 'Tovolar, the Midnight Scourge' })
  local states = { [2] = s2.data }
  local data = s1.data
  data.States = states
  local fullCard = deckerCard(a1, 1, 1, data)
  fullCard:spawn({ position = { 0, 2, 0 }, rotation = Vector(0, 180, 0) })
end

local CARD_FIELDS = {
  'lang', 'uri', 'layout', 'keywords', 'color_identity', 'all_parts',
  'collector_number', 'oracle_id'
}
local CARD_FACE_FIELDS = {
  'cmc', 'colors', 'defense', 'flavor_text', 'image_uris', 'loyalty',
  'mana_cost', 'name', 'oracle_text', 'power', 'toughness', 'type_line'
}
function processScryfallData(data)
  local steam = 'https://steamusercontent-a.akamaihd.net/ugc/'
  local uid = '1647720103762682461/'
  local fid = '35EF6E87970E2A5D6581E7D96A99F8A575B7A15F/'
  local cardBack = steam .. uid .. fid
  data.card_faces = data.card_faces or { data }
  local function faceData(face)
    local face_data = {}
    for _, f in ipairs(CARD_FACE_FIELDS) do
      face_data[f] = face[f] or data[f]
    end
    return face_data
  end
  -- Get all data in a consistent format.
  local faces_data = {}
  for i, f in ipairs(data.card_faces) do
    faces_data[i] = faceData(f)
  end

  local function altAngle(n) return Vector(0, 180, (180 + n) % 360) end
  local function formatName(cf)
    return string.format('%s\n%s\n%s CMC', cf.name, cf.type_line, cf.cmc)
  end
  local function formatDesc(cf, is_part)
    local text = ''
    if is_part then text = cf.name .. '\n----------\n' end
    text = text .. cf.oracle_text .. '\n'
    local stats
    if cf.power ~= nil and cf.toughness ~= nil then
      stats = cf.power .. '/' .. cf.toughness
    else
      stats = cf.loyalty or cf.defense or ''
    end
    if stats ~= '' then text = text .. '[b]' .. stats .. '[/b]' end
    return text
  end
  local function combinedDesc(cfs)
    local descs = {}
    for _, face in ipairs(cfs) do
      table.insert(descs, formatDesc(face, true))
    end
    return table.concat(descs, '\n')
  end
  local card_obj
  if data.layout == 'split' then -- handle Split cards
    local alt = altAngle(90)
    for _, kw in ipairs(data.keywords) do
      if kw == 'Aftermath' then alt = altAngle(0) end
    end
    local a = deckerAsset(faces_data[1].image_uris.large, cardBack)
    return deckerCard(a, 1, 1, {
      name = formatName(data),
      desc = combinedDesc(faces_data),
      AltLookAngle = alt
    })
  elseif data.layout == 'flip' then
    local a = deckerAsset(faces_data[1].image_uris.large, cardBack)
    local s1 = deckerCard(a, 1, 1, {
      name = formatName(faces_data[1]),
      desc = formatDesc(faces_data[1], false),
    })
    local s2 = deckerCard(a, 1, 1, {
      name = formatName(faces_data[2]),
      desc = formatDesc(faces_data[2], false),
      AltLookAngle = altAngle(180)
    })
    return deckerCard(a, 1, 1, {
      name = formatName(data),
      desc = combinedDesc(faces_data),
      States = { [2] = s1.data, [3] = s2.data }
    })
  else
    local a = deckerAsset(faces_data[1].image_uris.large, cardBack)
    return deckerCard(a, 1, 1, {
      name = formatName(faces_data[1]),
      desc = formatDesc(faces_data[1], false)
    })
  end
end

-- local card_type = 'normal'
--   if data.layout == 'split' then
--     card_type = 'split'
--     for _, v in ipairs(data.keywords) do
--       if v == 'Aftermath' then card_type = 'aftermath' end
--     end
--   end
--   local dfc_layouts = {
--     'modal_dfc', 'transform', 'meld', 'battle',
--     'double_faced_token', 'reversible_card'
--   }
--   for _, v in ipairs(dfc_layouts) do
--     if data.layout == v then card_type = 'dfc' end
--   end
--   if data.layout == 'flip' then card_type = 'flip' end
-- local CARD_TYPES = { 'normal', 'split', 'aftermath', 'flip', 'dfc' }
--[[ TODO:
Layouts with nothing special:
- normal, leveler, class, case, saga, adventure, mutate, prototype, scheme, vanguard, token, emblem, augment, host
Layouts with 2 faces or states:
- flip, transform, modal_dfc, meld, battle, double_faced_token, reversible_card
Layouts with non-0 orientation:
- split, flip, battle, planar

--]]
function getOrientation(p)
  local layout = p.data.layout
  local face_id = p.face_id
  local data = p.data
  o = 0
  local layoutMap = {
    normal,
    split,
    flip,
    transform,
    modal_dfc,
    meld,
    leveler,
    class,
    case,
    saga,
    adventure,
    mutate,
    prototype,
    battle,
    planar,
    scheme,
    vanguard,
    augment,
    host,
    reversible_card
  }
  if layout == 'split' then

  end
end


--[[ Decker.lua implementation copied from github ]]--

-- provide unique ID starting from 20 for present decks
local nextID, recheckNextID
do
  local _nextID = 20
  nextID = function()
    _nextID = _nextID + 1
    return tostring(_nextID)
  end

  local function recheckObjNextDeckID(obj)
    for deckID in pairs(obj.getData().CustomDeck or {}) do
      if deckID >= _nextID then
        _nextID = deckID
      end
    end
  end

  recheckNextID = function()
    local initialNextID = _nextID
    for _, obj in ipairs(getAllObjects()) do
      recheckObjNextDeckID(obj)
    end
    return _nextID > initialNextID
  end
end

-- Asset signature (equality comparison)
local function assetSignature(assetData)
  return table.concat({
    assetData.FaceURL,
    assetData.BackURL,
    assetData.NumWidth,
    assetData.NumHeight,
    assetData.BackIsHidden and 'hb' or '',
    assetData.UniqueBack and 'ub' or ''
  })
end
-- Asset ID storage to avoid new ones for identical assets
local idLookup = {}
local function assetID(assetData)
  local sig = assetSignature(assetData)
  local key = idLookup[sig]
  if not key then
    key = nextID()
    idLookup[sig] = key
  end
  return key
end

local assetMeta = {
  deck = function(self, cardNum, options)
    return deckerAssetDeck(self, cardNum, options)
  end
}
assetMeta = { __index = assetMeta }

-- Create a new CustomDeck asset
function deckerAsset(face, back, options)
  local asset = {}
  options = options or {}
  asset.data = {
    FaceURL = face or error('deckerAsset: faceImg link required'),
    BackURL = back or error('deckerAsset: backImg link required'),
    NumWidth = options.width or 1,
    NumHeight = options.height or 1,
    BackIsHidden = true,--options.hiddenBack or false,
    UniqueBack = options.uniqueBack or false
  }
  -- Reuse ID if asset existing
  asset.id = assetID(asset.data)
  return setmetatable(asset, assetMeta)
end

-- Pull a deckerAsset from card JSONs CustomDeck entry
local function assetFromData(assetData)
  return setmetatable({ data = assetData, id = assetID(assetData) }, assetMeta)
end

-- Create a base for JSON objects
function deckerBaseObject()
  return {
    Name = 'Base',
    Transform = {
      posX = 0,
      posY = 5,
      posZ = 0,
      rotX = 0,
      rotY = 0,
      rotZ = 0,
      scaleX = 1,
      scaleY = 1,
      scaleZ = 1
    },
    Nickname = '',
    Description = '',
    Value = 0,
    Tags = {},
    ColorDiffuse = { r = 1, g = 1, b = 1 },
    Locked = false,
    Grid = true,
    Snap = true,
    Autoraise = true,
    Sticky = true,
    Tooltip = true,
    GridProjection = false,
    Hands = true,
    XmlUI = '',
    LuaScript = '',
    LuaScriptState = '',
    GUID = 'deadbf'
  }
end

-- Typical paramters map with defaults
local commonMap = {
  name        = { field = 'Nickname', default = '' },
  value       = { field = 'Value', default = 0 },
  tags        = { field = 'Tags', default = {} },
  desc        = { field = 'Description', default = '' },
  script      = { field = 'LuaScript', default = '' },
  xmlui       = { field = 'XmlUI', default = '' },
  scriptState = { field = 'LuaScriptState', default = '' },
  locked      = { field = 'Locked', default = false },
  tooltip     = { field = 'Tooltip', default = true },
  guid        = { field = 'GUID', default = 'deadbf' },
  hands       = { field = 'Hands', default = true },
}
-- Apply some basic parameters on base JSON object
function deckerSetCommonOptions(obj, options)
  options = options or {}
  for k, v in pairs(commonMap) do
    -- can't use and/or logic cause of boolean fields
    if options[k] ~= nil then
      obj[v.field] = options[k]
    else
      obj[v.field] = v.default
    end
  end
  -- passthrough unrecognized keys
  for k, v in pairs(options) do
    if not commonMap[k] then
      obj[k] = v
    end
  end
end

-- default spawnObjectJSON/spawnObjectData params since it doesn't like blank fields
local function defaultParams(params)
  params = params or {}
  params.position = params.position or { 0, 5, 0 }
  params.rotation = params.rotation or { 0, 0, 0 }
  params.scale = params.scale or { 1, 1, 1 }
  if params.sound == nil then
    params.sound = true
  end
  return params
end

-- For copy method
local deepcopy
deepcopy = function(t)
  local copy = {}
  for k, v in pairs(t) do
    if type(v) == 'table' then
      copy[k] = deepcopy(v)
    else
      copy[k] = v
    end
  end
  return copy
end
-- meta for all Decker derived objects
local commonMeta = {
  -- return object JSON string, used cached if present
  _cache = function(self)
    if not self.json then
      self.json = JSON.encode(self.data)
    end
    return self.json
  end,
  -- invalidate JSON string cache
  _recache = function(self)
    self.json = nil
    return self
  end,
  spawn = function(self, params)
    params = defaultParams(params)
    params.data = self.data
    return spawnObjectData(params)
  end,
  spawnJSON = function(self, params)
    params = defaultParams(params)
    params.json = self:_cache()
    return spawnObjectJSON(params)
  end,
  copy = function(self)
    return setmetatable(deepcopy(self), getmetatable(self))
  end,
  setCommon = function(self, options)
    deckerSetCommonOptions(self.data, options)
    return self
  end,
}
-- apply common part on a specific metatable
local function customMeta(mt)
  for k, v in pairs(commonMeta) do
    mt[k] = v
  end
  mt.__index = mt
  return mt
end

-- DeckerCard metatable
local cardMeta = {
  setAsset = function(self, asset)
    local cardIndex = self.data.CardID:sub(-2, -1)
    self.data.CardID = asset.id .. cardIndex
    self.data.CustomDeck = { [asset.id] = asset.data }
    return self:_recache()
  end,
  getAsset = function(self)
    local deckID = next(self.data.CustomDeck)
    return assetFromData(self.data.CustomDeck[deckID])
  end,
  -- reset deck ID to a consistent value script-wise
  _recheckDeckID = function(self)
    local oldID = next(self.data.CustomDeck)
    local correctID = assetID(self.data.CustomDeck[oldID])
    if oldID ~= correctID then
      local cardIndex = self.data.CardID:sub(-2, -1)
      self.data.CardID = correctID .. cardIndex
      self.data.CustomDeck[correctID] = self.data.CustomDeck[oldID]
      if oldID ~= nil then self.data.CustomDeck[oldID] = nil end
    end
    return self
  end
}
cardMeta = customMeta(cardMeta)
-- Create a DeckerCard from an asset
function deckerCard(asset, row, col, options)
  row, col = row or 1, col or 1
  options = options or {}
  local card = deckerBaseObject()
  card.Name = 'Card'
  -- optional custom fields
  deckerSetCommonOptions(card, options)
  if options.sideways ~= nil then
    card.SidewaysCard = options.sideways
    -- FIXME passthrough set that field, find some more elegant solution
    card.sideways = nil
  end
  -- CardID string is parent deck ID concat with its 0-based index (always two digits)
  local num = (row - 1) * asset.data.NumWidth + col - 1
  num = string.format('%02d', num)
  card.CardID = asset.id .. num
  -- just the parent asset reference needed
  card.CustomDeck = { [asset.id] = asset.data }

  local obj = setmetatable({ data = card }, cardMeta)
  obj:_recache()
  return obj
end

-- DeckerDeck meta
local deckMeta = {
  count = function(self)
    return #self.data.DeckIDs
  end,
  -- Transform index into positive
  index = function(self, ind)
    if ind < 0 then
      return self:count() + ind + 1
    else
      return ind
    end
  end,
  swap = function(self, i1, i2)
    local ri1, ri2 = self:index(i1), self:index(i2)
    assert(ri1 > 0 and ri1 <= self:count(), 'DeckObj.rearrange: index ' .. i1 .. ' out of bounds')
    assert(ri2 > 0 and ri2 <= self:count(), 'DeckObj.rearrange: index ' .. i2 .. ' out of bounds')
    self.data.DeckIDs[ri1], self.data.DeckIDs[ri2] = self.data.DeckIDs[ri2], self.data.DeckIDs[ri1]
    local co = self.data.ContainedObjects
    co[ri1], co[ri2] = co[ri2], co[ri1]
    return self:_recache()
  end,
  -- rebuild self.data.CustomDeck based on contained cards
  _rescanUsedDecks = function(self)
    local cardIDs = {}
    for k, card in ipairs(self.data.ContainedObjects) do
      local cardID = next(card.CustomDeck)
      if cardID ~= nil and not cardIDs[cardID] then
        cardIDs[cardID] = card.CustomDeck[cardID]
      end
    end
    -- eeh, GC gotta earn its keep as well
    -- FIXME if someone does shitton of removals, may cause performance issues?
    self.data.CustomDeck = cardIDs
  end,
  -- rebuild self.data.DeckIDs based on contained cards
  _rescanDeckIDs = function(self)
    local deckIDs = {}
    for _, card in ipairs(self.data.ContainedObjects) do
      table.insert(deckIDs, card.CardID)
    end
    self.data.DeckIDs = deckIDs
  end,
  remove = function(self, ind, skipRescan)
    local rind = self:index(ind)
    assert(rind > 0 and rind <= self:count(), 'DeckObj.remove: index ' .. ind .. ' out of bounds')
    local card = self.data.ContainedObjects[rind]
    table.remove(self.data.DeckIDs, rind)
    table.remove(self.data.ContainedObjects, rind)
    if not skipRescan then
      self:_rescanUsedDecks()
    end
    return self:_recache()
  end,
  removeMany = function(self, ...)
    local indices = { ... }
    table.sort(indices, function(e1, e2) return self:index(e1) > self:index(e2) end)
    for _, ind in ipairs(indices) do
      self:remove(ind, true)
    end
    self:_rescanUsedDecks()
    return self:_recache()
  end,
  insert = function(self, card, ind)
    ind = ind or (self:count() + 1)
    local rind = self:index(ind)
    assert(rind > 0 and rind <= (self:count() + 1), 'DeckObj.insert: index ' .. ind .. ' out of bounds')
    table.insert(self.data.DeckIDs, rind, card.data.CardID)
    table.insert(self.data.ContainedObjects, rind, card.data)
    local id = next(card.data.CustomDeck)
    if id ~= nil and not self.data.CustomDeck[id] then
      self.data.CustomDeck[id] = card.data.CustomDeck[id]
    end
    return self:_recache()
  end,
  reverse = function(self)
    local s, e = 1, self:count()
    while s < e do
      self:swap(s, e)
      s = s + 1
      e = e - 1
    end
    return self:_recache()
  end,
  sort = function(self, sortFunction)
    table.sort(self.data.ContainedObjects, sortFunction)
    self:_rescanDeckIDs()
    return self:_recache()
  end,
  cardAt = function(self, ind)
    local rind = self:index(ind)
    assert(rind > 0 and rind <= (self:count() + 1), 'DeckObj.insert: index ' .. ind .. ' out of bounds')
    local card = setmetatable({ data = deepcopy(self.data.ContainedObjects[rind]) }, cardMeta)
    card:_recache()
    return card
  end,
  switchAssets = function(self, replaceTable)
    -- destructure replace table into
    -- [ID_to_replace] -> [ID_to_replace_with]
    -- [new_asset_ID] -> [new_asset_data]
    local idReplace = {}
    local assets = {}
    for oldAsset, newAsset in pairs(replaceTable) do
      assets[newAsset.id] = newAsset.data
      idReplace[oldAsset.id] = newAsset.id
    end
    -- update deckIDs
    for k, cardID in ipairs(self.data.DeckIDs) do
      local deckID, cardInd = cardID:sub(1, -3), cardID:sub(-2, -1)
      if idReplace[deckID] then
        self.data.DeckIDs[k] = idReplace[deckID] .. cardInd
      end
    end
    -- update CustomDeck data - nil replaced
    for replacedID in pairs(idReplace) do
      if self.data.CustomDeck[replacedID] then
        self.data.CustomDeck[replacedID] = nil
      end
    end
    -- update CustomDeck data - add replacing
    for _, replacingID in pairs(idReplace) do
      self.data.CustomDeck[replacingID] = assets[replacingID]
    end
    -- update card data
    for k, cardData in ipairs(self.data.ContainedObjects) do
      local deckID = next(cardData.CustomDeck)
      if deckID ~= nil and idReplace[deckID] then
        cardData.CustomDeck[deckID] = nil
        cardData.CustomDeck[idReplace[deckID]] = assets[idReplace[deckID]]
      end
    end
    return self:_recache()
  end,
  getAssets = function(self)
    local assets = {}
    for id, assetData in pairs(self.data.CustomDeck) do
      assets[#assets + 1] = assetFromData(assetData)
    end
    return assets
  end
}
deckMeta = customMeta(deckMeta)
-- Create DeckerDeck object from DeckerCards
function deckerDeck(cards, options)
  assert(#cards > 1, 'Trying to create a deckerdeck with less than 2 cards')
  local deck = deckerBaseObject()
  deck.Hands = false
  deck.Name = 'Deck'
  deckerSetCommonOptions(deck, options)
  deck.DeckIDs = {}
  deck.CustomDeck = {}
  deck.ContainedObjects = {}
  for _, card in ipairs(cards) do
    deck.DeckIDs[#deck.DeckIDs + 1] = card.data.CardID
    local id = next(card.data.CustomDeck)
    if id ~= nil and not deck.CustomDeck[id] then
      deck.CustomDeck[id] = card.data.CustomDeck[id]
    end
    deck.ContainedObjects[#deck.ContainedObjects + 1] = card.data
  end

  local obj = setmetatable({ data = deck }, deckMeta)
  obj:_recache()
  return obj
end

-- Create DeckerDeck from an asset using X cards on its sheet
function deckerAssetDeck(asset, cardNum, options)
  cardNum = cardNum or asset.data.NumWidth * asset.data.NumHeight
  local row, col, width = 1, 1, asset.data.NumWidth
  local cards = {}
  for k = 1, cardNum do
    cards[#cards + 1] = deckerCard(asset, row, col)
    col = col + 1
    if col > width then
      row, col = row + 1, 1
    end
  end
  return deckerDeck(cards, options)
end

deckerRescanExistingDeckIDs = recheckNextID
