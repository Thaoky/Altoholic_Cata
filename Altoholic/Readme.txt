Altoholic - local fork
======================

Altoholic was written by Thaoky. This tree is a personal fork of Thaoky/Altoholic_Cata,
kept running on Classic clients. Upstream lives at:

    https://github.com/Thaoky/Altoholic_Cata

The previous version of this file was the readme shipped with the 2008 release. It
described AceComm, uncompressed transfers, counters that no longer exist and a language
list that was never accurate for this tree, so it has been replaced rather than patched.
Everything below was checked against the code in this folder.


-------------------------------------------------------------------------------
1. What it does today
-------------------------------------------------------------------------------

Altoholic records what each of your characters owns and knows, and shows it to you while
you are logged in on a different one. It does not scan anything by itself: the DataStore_*
modules do the storing, Altoholic is the interface on top of them.

Tabs, in the order they appear:

  Summary       One line per character: level, money, /played, rest xp, bag space,
                average item level, professions. Subtotals per realm, grand totals per
                account. Right-clicking a realm line offers "Update from ...", which is
                the account sharing entry point.

  Characters    One character at a time: bags, bank and keyring, quest log, talents,
                auctions and bids, mailbox, spellbook, and known recipes per profession.
                The icons across the top switch between those views and carry their own
                filter menus.

  Search        Searches bags, banks and mailboxes across every known character, or the
                bundled loot tables, in an auction-house style list. Filters by name
                (partial matches work), item level, slot, type and rarity. Known recipes
                can be searched too.

  Guild         Guild members with their alts and average item level, guild bank tabs and
                when they were last visited, and profession links for guildmates who also
                run Altoholic.

  Achievements  Achievement progress per character.

  Agenda        Profession cooldowns, dungeon resets, calendar events and item timers,
                with configurable warnings.

  Grids         One grid per subject, comparing every character side by side:
                attunements, currencies, dailies, dungeons, equipment, keys, reputations
                and tradeskills.

  Options       Altoholic's own settings plus the DataStore modules' settings, all hosted
                inside this tab rather than in Blizzard's interface options.

Slash commands (/alto or /altoholic):

    /alto show           show the window
    /alto hide           hide it
    /alto toggle         toggle it
    /alto search <text>  search bags for <text>, of any length
    /alto sharing        open the account sharing panel directly

Account sharing, in short: one account requests data from another, on the same realm, one
direction at a time, and it is a snapshot rather than a subscription. Both sides must tick
"Account Sharing Enabled" first. Data now travels serialised and deflate-compressed over
the addon channel; the "uncompressed, AceComm" description in the old readme has been
untrue for years.

Localisation: enUS is the reference and is complete. deDE, esES, esMX, frFR, itIT, koKR,
ptBR, ruRU, zhCN and zhTW exist and are inherited from upstream, at whatever coverage
upstream left them; itIT and ruRU also carry the strings added by this fork. Any key a
locale does not define falls back to English.

Clients: the toc claims 11508 (Classic Era), 20505 (Burning Crusade) and 50504 (Mists of
Pandaria). Only the first two have been run. Mists is inherited from upstream and is
untested here - see the comment at the top of Altoholic.toc.


-------------------------------------------------------------------------------
2. What I changed
-------------------------------------------------------------------------------

Grouped by area. Upstream bugs that were fixed in passing are marked as such; the rest is
either a port to current APIs or a local addition.

Account sharing
  - Ported the whole feature to the current comm and DataStore APIs. It was left behind
    when DataStore moved on and did not run at all.
  - Moved its saved state out of the removed AceDB layer into Altoholic_Sharing_Options.
  - Fixed an inverted check that guarded the sharing window, and an error when scrolling
    an empty content pane.
  - Only DataStore tables that are indexed by character id are offered for sharing; the
    others cannot be imported meaningfully.
  - Wrote the in-panel help that walks through each step of a request. The panel used to
    show a bare status line and nothing else.
  - Added a transfer watchdog. Every step of the protocol waits for the other side, and
    nothing said what to do if that side logged out: the window stayed on the step it had
    reached with the send button disabled, permanently. A 45 second timer now abandons the
    request, keeps and finalises whatever had already arrived, explains what happened and
    re-enables the button.
  - The Account Name field now defaults to the name used most recently on this realm.
    Reusing the same name is what updates a group instead of creating a second one, so the
    field defaulting to empty worked against the intended use.
  - Cascading checkboxes in the shared content list, and a list that fits its pane.

Professions and recipes
  - Enchanting on old clients is served by the craft window, not the tradeskill window.
    Its recipes are now stored with the item they create where there is one, found by item
    name, and the craft list no longer inherits leftovers from the tradeskill scan.
  - Recipe searches are case insensitive, resolve the crafted item before filtering, and
    re-run themselves when item names arrive late from the server.
  - Recipe ids are read independently of the previous entry, and recipes whose difficulty
    the client does not colour are stored rather than dropped.

Summary and item level
  - Item level is computed manually when the API returns zeroes, and the guild broadcast
    of it is hardened against missing data.
  - The average item level tooltip now shows Burning Crusade tier references on Burning
    Crusade clients. The vanilla branch tested "below Wrath", which swallowed TBC.
  - Stored equipment is no longer wiped when the item cache is cold.

Guild
  - Our own guild and our guilded alts are resolved through DataStore's lookups, by the
    guild id they were registered under, instead of over the network.

Options
  - The DataStore option panels are reachable from the options tab.
  - The options icons open the options tab instead of erroring.
  - The module shortcuts in the character tab menus work again. They were guarded by a
    test on a global that no longer exists, so the "Options" heading was drawn above
    nothing at all. (upstream bug)
  - Restored the AutoQuery checkbox. It wrote to a path nothing reads, so the option could
    never be turned on and the feature behind it was unreachable. It now reads and writes
    Altoholic_SearchTab_Options, loading Altoholic_Search on demand when needed.
    Note that the three checkboxes below it in the same panel are still inert - they have
    the same fault and have been left alone. (upstream bug)
  - Fixed "week starts on Monday" erroring on click. (upstream bug)

Other fixes
  - The real main bank size is used instead of hardcoded values.
  - Reputations are saved on Classic Era, and factions that do not exist in the running
    version of the game are skipped.
  - Search results no longer compare a nil name while sorting. (upstream bug)
  - tonumber() base error in GetNumPointsSpent. (upstream bug)
  - Dropped the last AceDB leftovers.

Command line
  - /alto search takes the whole rest of the line. It used to split on the first space and
    pass only the second word through, so a two word search silently searched for one word
    and anything longer was truncated. The old readme documented this as a two word limit;
    it is now unlimited.
  - Added /alto sharing.

Strings and localisation
  - The account sharing help, the send/request button labels, the transfer status lines
    and "Shared Content" were English literals in the code. They are locale keys now, with
    Italian and Russian translations. Colour codes are inline in the strings so that
    translators can move the highlighted words.

Known, not fixed
  - Altoholic's own addon:ToggleOption() is a stub: it reads the checkbox and returns
    without writing anywhere. Twelve checkboxes inherit the template that calls it, and
    all of them are inert. Only AutoQuery was rewired; the rest still do nothing.
  - L["NEW_VERSION_AVAILABLE"] and L["OFFICIAL_SOURCES"] are used in Core.lua but defined
    in no locale file. The branch is unreachable today because the variable it tests is
    never assigned, so nothing prints the raw keys yet.
  - The DataStore_Talents folder carries a stray copy of DataStore_Quests - its lua, four
    toc files and an Options.xml declaring the same parentKey. It is inert only because
    WoW ignores toc files whose name does not match the folder.
  - Mists of Pandaria is claimed by the toc and has never been run.


-------------------------------------------------------------------------------
Installing
-------------------------------------------------------------------------------

Copy the addon folders - AddonFactory, Altoholic*, DataStore* - into
Interface\AddOns, each one directly under AddOns with no extra directory level in
between.
