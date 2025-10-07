-- Test text truncation
local text = "create_something_long"
local width = 22
local padding = 1
local available_width = width - (padding * 2)

print("Text: " .. text)
print("Width: " .. width)
print("Padding: " .. padding)
print("Available: " .. available_width)
print("Text length: " .. #text)

if #text > available_width then
  local display = text:sub(1, available_width - 3) .. "..."
  print("Truncated: " .. display)
  print("Display length: " .. #display)
else
  print("No truncation needed")
end
