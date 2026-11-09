import re, sys
sys.stdout.reconfigure(encoding='utf-8')

with open("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    content = f.read()

# Let's inspect line ranges for each section in content
# We will do clean replacements using unique anchors

# 1. Group page setup:
# Starts at: local groupSunburst = Instance.new("Frame")
# Ends at: btnClaimGroup.Activated:Connect(...) ... end
p_group_start = content.find('local groupSunburst = Instance.new("Frame")')
p_group_end = content.find('-- ==========================================================================\n-- Playtime Rewards Page')
print("Group start:", p_group_start, "end:", p_group_end)

# 2. Playtime page setup:
# Starts at: -- Top countdown bar
# Ends before: -- ==========================================================================\n-- Quests Page
p_playtime_start = content.find('-- Top countdown bar')
p_playtime_end = content.find('-- ==========================================================================\n-- Quests Page')
print("Playtime start:", p_playtime_start, "end:", p_playtime_end)

# 3. Quests page setup:
p_quests_start = content.find('local questCardContainer = Instance.new("Frame")')
p_quests_end = content.find('-- ==========================================================================\n-- Skins / Chair Shop Page')
print("Quests start:", p_quests_start, "end:", p_quests_end)

# 4. Skins page setup:
p_skins_start = content.find('local skinsScroll = Instance.new("ScrollingFrame")')
p_skins_end = content.find('-- ==========================================================================\n-- Titles Page')
print("Skins start:", p_skins_start, "end:", p_skins_end)

# 5. Titles page setup:
p_titles_start = content.find('local titlesHeader = Instance.new("Frame")')
p_titles_end = content.find('-- ==========================================================================\n-- Footballer Index Page')
print("Titles start:", p_titles_start, "end:", p_titles_end)

# 6. Index page setup:
p_index_start = content.find('local indexHeader = Instance.new("Frame")')
p_index_end = content.find('-- ==========================================================================\n-- Wheel Modal Page')
print("Index start:", p_index_start, "end:", p_index_end)

# 7. Wheel page setup:
p_wheel_start = content.find('local wheelCard = Instance.new("Frame")')
p_wheel_end = content.find('-- ==========================================================================\n-- Profile Page')
print("Wheel start:", p_wheel_start, "end:", p_wheel_end)
