# Override the default Fish greeting (the "Welcome to fish" message).
# This shows a minimal fastfetch instead, or nothing if fastfetch isn't installed.
function fish_greeting
    if type -q fastfetch
        fastfetch
    end
end
