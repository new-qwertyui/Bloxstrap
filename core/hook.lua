export type library = {
    toggle: {
        name: string,
        subtext: string,
        callback: (() -> (boolean)),
        exception: boolean | nil,
        toggled: boolean
    },
    dropdown: {
        name: string,
        subtext: string,
        callback: (() -> (string | number)),
        exception: boolean | nil,
        value: number | string
    },
    textbox: {
        name: string,
        subtext: string,
        callback: (() -> (string | number)),
        exception: boolean | nil,
        number: boolean,
        value: number | string
    }
}

if shared.loaded then
    shared.loaded:destruct()
end
if readfile('bloxstrap/selected.txt') == 'new' then
    return loadfile('bloxstrap/core/guis/new.lua')()
end
local httpservice = cloneref(game:GetService('HttpService')) :: HttpService
local inputservice = cloneref(game:GetService('UserInputService')) :: UserInputService
local loadfile = function(file, errpath)
    if getgenv().developer then
        errpath = errpath or file:gsub('bloxstrap/', '')
        return getgenv().loadfile(file, errpath)
    else
        local result = request({
            Url = `https://raw.githubusercontent.com/qwertyui-is-back/Bloxstrap/main/{file:gsub('bloxstrap/', '')}`,
            Method = 'GET'
        })
        if result.StatusCode ~= 404 then
            return loadstring(result.Body)
        else
            error('Invalid file')
        end
    end
end
local elements = {
    windows = {},
    assets = {
        intergrations = 'rbxassetid://94186399020089',
        ['engine settings'] = 'rbxassetid://94903440484497',
        mods = 'rbxassetid://126821269590599',
        appearence = 'rbxassetid://98935832640924',
        behaviour = 'rbxassetid://137701271745658',
        exit = 'rbxassetid://98193757882443'
    },
    configs = isfile('bloxstrap/logs/profile.json') and httpservice:JSONDecode(readfile('bloxstrap/logs/profile.json')) or {},
    tweenspeed = 0.2,
    saving = false,
    drags = {},
    enabled = false,
    modules = {},
    actualwins = {},
    configlib = loadfile('bloxstrap/core/config.lua')(),
    gui = nil
} :: table

local guitype = readfile('bloxstrap/selected.txt')
local oldgui = loadfile(`bloxstrap/core/guis/{guitype}.lua`)()
elements.gui = oldgui

function elements.callback(api, ...)
    local suc, res = pcall(api, ...)
    if not suc then
        --error(res)
    end
end

local window 
if guitype == 'old' then
    window = oldgui:MakeWindow({
        Title = 'Bloxstrap',
        SubTitle = ''
    })
else
    --loadstring(game:HttpGet('https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua'))():SetLibrary(oldgui)
    window = oldgui:CreateWindow({
        Title = 'Bloxstrap',
        SubTitle = '',
        TabWidth = 160,
        Size = UDim2.fromOffset(720, 460),
        Acrylic = false,
        Theme = 'Darker',
        MinimizeKey = Enum.KeyCode.RightShift
    })
    --savemanager:SetLibrary(oldgui)
end

if elements.uiscaler then
    local scalecon = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
        elements.uiscaler.Scale = workspace.CurrentCamera.ViewportSize.Y / 700
    end)
    elements.uiscaler = workspace.CurrentCamera.ViewportSize.Y / 700
end

function elements:clean(cons)
    for _, v in cons do
        if typeof(v) == 'Instance' then
            pcall(function()
                v:Destroy()
            end)
        elseif type(v) == 'thread' then
            pcall(task.cancel, v)
        else
            v:Disconnect() 
        end
    end
    table.clear(cons)
end


for i,v in {'Intergrations', 'Mods', 'Engine Settings', 'Appearence', 'Behaviour'} do
    local tabname = v:lower():gsub(' ', '')
    local args = {
        Title = v,
        Icon = elements.assets[v:lower()]
    }
    elements.actualwins[tabname] = guitype == 'old' and window:MakeTab(args) or window:AddTab(args)
    elements.windows[tabname] = {}
end

if guitype == 'old' then
    for i,v in elements.windows do
        function v:addmodule(args)
            local api = {
                toggled = false,
                cons = {}
            }
            local actualapi = elements.actualwins[i]:AddSection(args.name)
            function api:addtoggle(args)
                local fakeapi = {toggled = false, cons = {}}
                elements.modules[args.name] = fakeapi
                local togglename = args.name
                local toggledef = args.default
                local togglecallback = args.callback or function() end
                local toggle = elements.actualwins[i]:AddToggle({
                    Title = togglename,
                    Callback = function(call)
                        api.toggled = call
                        if not api.toggled then
                            elements:clean(fakeapi.cons)
                        end
                        task.spawn(togglecallback, api.toggled)
                    end,
                    Default = toggledef
                })
                function fakeapi:setstate(bool)
                    toggle:Toggle(bool or not fakeapi.toggled)
                end
                function fakeapi:retoggle()
                    if fakeapi.toggled then
                        toggle:Toggle(false)
                        toggle:Toggle(true)
                    end
                end
                return fakeapi
            end

            local modtoggle = api:addtoggle({
                name = 'Enabled',
                callback = function(call: boolean)
                    api.toggled = call
                    if args.callback then
                        task.spawn(args.callback, api.toggled)
                    end
                end,
                exception = true
            })
            
            function api:retoggle(...)
                modtoggle:retoggle(...)
            end

            api.cons = modtoggle.cons

            function api:adddropdown(args)
                local fakeapi = {value = ''}
                elements.modules[args.name] = fakeapi
                local textbox = elements.actualwins[i]:AddDropdown({
                    Title = args.name,
                    Options = args.list,
                    Callback = function(val)
                        fakeapi.value = val
                        if args.callback then
                            task.spawn(elements.callback, args.callback, val, true)
                        end
                    end,
                    Default = args.default
                })
                function fakeapi:setvalue(...)
                    textbox:Set(...)
                end
                return fakeapi
            end
            function api:addtextbox(args)
                local fakeapi = {value = ''}
                elements.modules[args.name] = fakeapi
                local textbox = elements.actualwins[i]:AddTextBox({
                    Title = args.name,
                    Callback = function(val)
                        fakeapi.value = val
                        if args.callback then
                            task.spawn(elements.callback, args.callback, val, true)
                        end
                    end,
                    Default = args.default
                })
                function fakeapi:setvalue(...)
                    textbox:Set(...)
                end
                return fakeapi
            end
            return api
        end
    end
else
    for i,v in elements.windows do
        function v:addmodule(arguments)
            local moduleapi = {
                toggled = false,
                cons = {}
            }
            function moduleapi:addtoggle(args)
                if oldgui.Options[args.name] then
                    warn('sorted mod'.. elements.modules[args.name])
                    elements.modules[args.name].callback = args.callback
                    return elements.modules[args.name]
                end
                local api = {
                    toggled = false, 
                    cons = {},
                    callback = args.callback or function() end
                }
                elements.modules[args.name] = api
                local moduletoggle = elements.actualwins[i]:AddToggle(args.name, {
                    Title = args.name, 
                    Description = args.subtext 
                })
                function api:setstate(bool)
                    moduletoggle:SetValue(bool or not api.toggled)
                end
                moduletoggle:OnChanged(function()
                    api.toggled = oldgui.Options[args.name].Value
                    if not api.toggled then
                        elements:clean(api.cons)
                    end
                    task.spawn(elements.callback, api.callback, api.toggled)
                end)
                function api:retoggle()
                    if api.toggled and api.callback then
                        api:setstate(false)
                        api:setstate(true)
                    end
                end
                if args.default then
                    oldgui.Options[args.name]:SetValue(args.default)
                end
                return api
            end
            
            local modtoggle = moduleapi:addtoggle({
                name = arguments.name,
                callback = function(call: boolean)
                    moduleapi.toggled = call
                    if arguments.callback then
                        task.spawn(arguments.callback, moduleapi.toggled)
                    end
                end,
                exception = true
            })
            
            function moduleapi:retoggle(...)
                modtoggle:retoggle(...)
            end

            moduleapi.cons = modtoggle.cons

            function moduleapi:adddropdown(args)
                local api = {
                    array = args.list or {},
                    value = args.default or args.list[1]
                }
                elements.modules[args.name] = api
                local dropdown = elements.actualwins[i]:AddDropdown(args.name, {
                    Title = args.name,
                    Values = api.array,
                    Multi = false
                })

                if api.value then
                    dropdown:SetValue(api.value)
                end

                dropdown:OnChanged(function(val)
                    api.value = val
                    if args.callback then
                        task.spawn(elements.callback, args.callback, val)
                    end
                end)

                function api:setvalue(val)
                    dropdown:SetValue(val)
                end
                return api
            end

            function moduleapi:addtextbox(args)
                local api = {}
                elements.modules[args.name] = api
                local box = elements.actualwins[i]:AddInput(args.name, {
                    Title = args.name,
                    Default = args.default,
                    Numeric = args.number or false,
                    Finished = true,
                    Callback = function(val)
                        api.value = val
                        if args.callback then
                            task.spawn(elements.callback, args.callback, api.value, true)
                        end
                    end
                })         
                function api:setvalue(val)
                    box:SetValue(val)
                end 
                return api
            end

            return moduleapi
        end
    end
end

shared.loaded = {}

function shared.loaded:destruct()
    elements.gui:Destroy()
    shared.loaded = nil
end

function elements:notify(args)
    if guitype == 'fluent' then
        oldgui:Notify({
            Title = args.Title or args.title or 'Bloxstrap',
            Content = args.Description or args.Desc or args.subtext or args.Text,
            Duration = args.duration or args.Duration or 7
        })
    else
        cloneref(game:GetService('StarterGui')):SetCore('SendNotification', {
            Title = args.Title or args.title or 'Bloxstrap',
            Text = args.Description or args.Desc or args.subtext,
            Duration = args.duration or args.Duration or 7
        })
    end
end

return elements