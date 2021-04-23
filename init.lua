-- Remap keys to provide spacemacs-like slime experience
vis:map(vis.modes.VISUAL_LINE, "<Space>ss", ":slime<Enter>")
vis:map(vis.modes.VISUAL, "<Space>ss", ":slime<Enter>")
vis:map(vis.modes.NORMAL, "<Space>ss", "V:slime<Enter><Escape>")
vis:map(vis.modes.NORMAL, "<Space>sr", "vip:slime<Enter><Escape>")
-- TODO: add a subscription/event listener that clears the pane on close
-- TODO: if no pane is selected, use vis:info to print a help message
-- and break the execution
vis:command_register("slime", function(argv, force, win, selection, range)
    -- local slime_content_file = '.vslime_paste'
    local slime_buffer = 'slime_buffer'
    if argv[1] == "help" or argv[1] == "-h" then
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
        local cleaned_content = string.gsub(selected_content, "\n\n","\n")
        local _, count = string.gsub(cleaned_content, "\n", "")
        ftype = get_file_type()
        if ftype == "py" then
            if count > 1 and test_pyblock(cleaned_content) then
                cleaned_content = cleaned_content .. "\n"
            end
        end
        f:write(cleaned_content)
        f:close()
        -- TODO: add error handling and prompts when using tmux_send and set_pane
        -- TODO: wipe set-pane when file closes
        -- TODO: use a table to pair set-pane with files to allow multiple
        -- vis-pane -> tmux-pane pairs
        -- TODO: add error handling for files/buffers w/no name i.e. a new
        -- unsaved file/buffer
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
    local tmux_pane = get_slime_config()
    -- Make sure the buffer loads before executing paste
    os.execute("sleep 0.0001")
    tmux_snd_cmd = "tmux paste-buffer -b slime_buffer -t " .. tmux_pane
    --io.popen("tmux paste-buffer -b slime_buffer -t 1")
    io.popen(tmux_snd_cmd)
end

function get_slime_config()
    slime_config_file = make_slime_file('.vslime_config')
    local tmux_pane_handle = io.open(slime_config_file, "r")
    local tmux_pane = tmux_pane_handle:read("*a")
    return tmux_pane
end


function test_pyblock(lines)
    -- tests to see if the last line in a selection has leading spaces
    new_lines = {}
    for line in lines:gmatch("[^\n]+") do
        table.insert(new_lines, line)
    end
    -- Detect when you hit the last line
    -- When you hit the last line append to blank lines to the block
    for i, line in ipairs(new_lines) do
        if next(new_lines, i) == nil then
            if string.starts(line, " ") then
                result = true
            else
                result = nil
            end
        end
    end
    return result
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function get_file_type()
    local file_obj = vis.win.file
    local file_name = file_obj.name
    local file_pieces = {}
    for v in string.gmatch(file_name, '([^%.]+)') do
        table.insert(file_pieces, v)
    end
    file_type = file_pieces[#file_pieces]
    return file_type
end
