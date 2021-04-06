--TODO: write code to create slime_path if the file doesn't 
--exist
vis:command_register("slime", function(argv, force, win, selection, range)  
    local sh_handle = io.popen("echo $HOME")
    local home = sh_handle:read("*a") 
    home = string.gsub(home, "\n","")
    local slime_file = ".v-slime_paste"
    local slime_path = home .. "/" ..  slime_file
    local f = io.open(slime_path, "w")
    local selected_content = win.file:content(selection.range)
    -- remove empty lines from selection
    cleaned_content = string.gsub(selected_content, "\n\n","\n")
    f:write(cleaned_content)
    f:write(home)
    --Right now we're manually setting session
    --TODO: review the vim slime function to get session, window and pane prompt for the first send
    --e.g. create variables for this, if they are null when command is run, prompt for them:
    --TODO: Also createa a function change the destination
    -- break this into invidiual vars then concat into one statement
    -- 4 = session, 1 = window, 2 = pane
    -- use current session and window, prompt for pane
    io.popen("tmux send-keys -t 4:1.2 " .. "'" .. cleaned_content .. "'" .. " ")
    io.popen("tmux send-keys -t 4:1.2 C-m")
    -- TODO: with python function, figure out how to put in hard return at end -- look at vim slime for ideas

    local success, msg, status = f:close()
end)
