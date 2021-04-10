-- Remap keys to provide spacemacs-like slime experience
-- comment these this out to turn off, or change them to 
-- something you like better.
vis:map(vis.modes.VISUAL_LINE, "<Space>ss", ":slime<Enter>") 
vis:map(vis.modes.VISUAL, "<Space>ss", ":slime<Enter>") 
vis:map(vis.modes.NORMAL, "<Space>ss", "V:slime<Enter><Escape>") 
vis:map(vis.modes.NORMAL, "<Space>sr", "vip:slime<Enter><Escape>") 

--TODO: add a subscription/event listener that clears the pane when the file close
--TODO: if no pane is selected, use vis:info to print a help message and break the execution
vis:command_register("slime", function(argv, force, win, selection, range)  
    -- local slime_content_file = '.vslime_paste'
    local slime_buffer = 'slime_buffer'
    if argv[1] == "help" or argv[1] == "h" then
        help_msg = " Vslime: Slime for the vis editor\
        \n :slime\n  Sends the current selection to the designated tmux pane\
        \n :slime set-pane <num>\n  Sets the target tmux pane\
        \n :slime get-pane\n  Displays the current target tmux pane\
        \n :slime help\n  Display this help menu\
        \n (END)"
        vis:message(help_msg)
    elseif argv[1] == "set-pane" then
        target_pane = argv[2]
        slime_config_file = make_slime_file('.vslime_config')
        local f = io.open(slime_config_file, "w")
        f:write(target_pane)
        f:close()
        vis:info("Tmux target pane set to: " .. target_pane)
    elseif argv[1] == "get-pane" then
        target_pane = get_slime_config()
        vis:info("Tmux target pane: " .. target_pane) 
    else

        -- TODO: Put the saving of the selection in it's own function
        -- Make this it's own function then embed within send-tmux
        slime_content_file = make_slime_file('.vslime_paste')
        local f = io.open(slime_content_file, "w")
        local selected_content = win.file:content(selection.range)
        -- remove empty lines from selection
        -- TODO: If it's a python file AND the last line has more leading
        -- spaces than the first, add two lines with just an empt space
        local cleaned_content = string.gsub(selected_content, "\n\n","\n")
        f:write(cleaned_content)
        f:close()
        -- this works to prevent read prior to write but it's sloppy
        -- TODO: Add pane numbers to this function
        -- TODO: turn paste file into function param with default
        -- TODO: Turn slime buffer into local var
        local tmux_pane = get_slime_config()
        send_tmux()
    end
end)

-- Helper Functions --
function make_slime_file(file)
    local sh_handle = io.popen("echo $HOME")
    local home = sh_handle:read("*a") 
    home = string.gsub(home, "\n","")
    local slime_file = home .. "/" ..  file
    return slime_file
end


function send_tmux()
    io.popen("tmux load-buffer -b slime_buffer ~/.vslime_paste")
    -- Make sure the buffer loads before executing paste
    os.execute("sleep 0.0001")
    io.popen("tmux paste-buffer -b slime_buffer -t 1")
end

-- This can probably be deleted    
function make_tmux_cmd()
    local cmd = 'tmux list-panes -t "$TMUX_PANE" -F "#S" | head -n2'
    local tmux_session_handle = io.popen(cmd)
    local tmux_session = tmux_session_handle:read("*a")
    -- get tmux current window number
    local cmd = "tmux list-windows | grep active.$ | cut -c 2"
    local tmux_handle = io.popen(cmd)
    -- io.popen usually returns a file, you have to convert it to text
    local tmux_window = tmux_handle:read("*a")
    local tmux_pane = get_slime_config()
    local tmux_prefix = "tmux send-keys -t "
    local tmux_conf = tmux_session .. ":" .. tmux_window .. "." .. tmux_pane .. " "
    local tmux_cmd = tmux_prefix .. tmux_conf
    local tmux_cmd = string.gsub(tmux_cmd, "\n","")
    return tmux_cmd
end

function get_slime_config()
    slime_config_file = make_slime_file('.vslime_config')
    local tmux_pane_handle = io.open(slime_config_file, "r")
    local tmux_pane = tmux_pane_handle:read("*a")
    return tmux_pane
end
