--TODO: write code to create slime_path if the file doesn't 
--exist
vis:command_register("slime", function(argv, force, win, selection, range)  
    local slime_path = "/home/theuser/.v-slime_paste"
    local f = io.open(slime_path, "w")
    local slime_range = selection.range
    local selected_content = win.file:content(slime_range)
    -- remove empty lines from selection
    cleaned_content = string.gsub(selected_content, "\n\n","\n")
    f:write(cleaned_content)
    local success, msg, status = f:close()
end)
