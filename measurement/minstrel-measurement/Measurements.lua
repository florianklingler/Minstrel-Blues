require ('misc')
local pprint = require ('pprint')
require ('Measurement')

--[[
--  STA: regmon, tcpdump, cpusage
--  AP: regmon, tcpdump, cpusage, rc_stats per station
--]]

-- String name, String typ, String value
-- "expermiment_order", "List", "{1}"
-- "mac", "mac", "AA:22:BB:33:CC:44"
-- "mac_br", "mac", "AA:22:BB:33:CC:44"
-- "opposite_macs","List","{...}"
-- "opposite_macs_br","List","{...}"
-- "stations","List","{tp4300}"
MeasurementsOption = { name = nil
                     , typ = nil
                     , value = nil
                     }

-- 

Measurements = { rpc_node = nil
               , node_name = nil
               , node_mac = nil
               , node_mac_br = nil
               , opposite_macs = nil
               , opposite_macs_br = nil
               --, regmon_stats = nil
               --, tcpdump_pcaps = nil
               --, cpusage_stats = nil
               --, rc_stats = nil
               , rc_stats_enabled = nil
               , iperf_s_outs = nil
               , iperf_c_outs = nil
               , stations = nil
               , output_dir = nil
               , online = nil
               --, regmon_file = nil
               --, tcpdump_pcap_file = nil
               --, cpusage_file = nil
               --, rc_stats_files = nil
               , regmon_meas = nil
               , cpusage_meas = nil
               , tcpdump_meas = nil
               , rc_stats_meas = nil
               }

function Measurements:new (o)
    local o = o or {}
    setmetatable ( o, self )
    self.__index = self
    return o
end

function Measurements:create ( name, mac, opposite_macs, rpc, output_dir, online )
    local o = Measurements:new ( { rpc_node = rpc
                                 , node_name = name
                                 , node_mac = mac
                                 , node_mac_br = nil
                                 , opposite_macs = opposite_macs
                                 , opposite_macs_br = nil
                                 --, regmon_stats = {}
                                 --, tcpdump_pcaps = {}
                                 --, cpusage_stats = {}
                                 --, rc_stats = {}
                                 , rc_stats_enabled = false
                                 , iperf_s_outs = {}
                                 , iperf_c_outs = {}
                                 , output_dir = output_dir
                                 , online = online
                                 --, rc_stats_files = {}
                                 , regmon_meas = {}
                                 , cpusage_meas = {}
                                 , tcpdump_meas = {}
                                 , rc_stats_meas = {}
                                 } )
    return o
end

function read_stations ( input_dir )
    local fname = input_dir .. "/stations.txt"
    if ( isFile ( fname ) ) then
        local file = io.open ( fname, "r" )
        if ( file ~= nil ) then
            local content  = file:read ( "*a" )
            if ( content ~= nil ) then
                local stations = split ( content, "\n" )
                if ( stations [ #stations ] == "" ) then
                    stations [ #stations ] = nil
                end
                return stations
            end
        end
    end
    return nil
end

function Measurements:add_key ( key, output_dir )

    if ( output_dir == nil ) then
        return false, "output dir unset"
    end

    local base_dir = output_dir .. "/" .. self.node_name
    if ( key ~= nil ) then
        local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-regmon_stats.txt"
        self.regmon_meas [ key ] = RegmonMeas:create ( key, fname )

        local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-cpusage_stats.txt"
        self.cpusage_meas [ key ] = CpusageMeas:create ( key, fname )

        local fname = output_dir .. "/" .. self.node_name 
                    .. "/" .. self.node_name .. "-" .. key .. ".pcap"
        self.tcpdump_meas [ key ] = TcpdumpPcapsMeas:create ( key, fname )
    end

    local stations = read_stations ( output_dir )
    for _, station in ipairs ( stations ) do
        if ( self.rc_stats_meas == nil ) then
            self.rc_stats_meas = {}
        end
        if ( self.rc_stats_meas [ station ] == nil ) then
            self.rc_stats_meas [ station ] = {}
        end
        if ( key ~= nil ) then
            local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-rc_stats-"
                                   .. station .. ".txt"
            self.rc_stats_meas [ station ] [ key ] = RcStatsMeas:create ( station, key, fname )
        end
    end

end

function read_keys ( input_dir )
    local fname = input_dir .. "/experiment_order.txt"
    if ( isFile ( fname ) ) then
        local file = io.open ( fname, "r" )
        if ( file ~= nil ) then
            local content = file:read ("*a")
            if ( content ~= nil ) then
                local keys = split ( content, "\n" )
                if ( keys [ #keys ] == "" ) then
                    keys [ #keys ] = nil
                end
                return keys
            end
        end
    end
    return nil
end

function Measurements.parse ( name, input_dir, key, online )

    function init_measurements ( measurements, name, input_dir, key )
        -- load single measurement
        if ( key ~= nil ) then

            measurements:add_key ( key, input_dir )
        
            --measurements.regmon_stats [ key ] = ""
            --measurements.cpusage_stats [ key ] = ""
            --local stations = read_stations ( input_dir )
            --for _, station in ipairs ( stations ) do
            --    if ( measurements.rc_stats [ station ] == nil ) then
            --        measurements.rc_stats [ station ] = {}
            --    end
            --    measurements.rc_stats [ station ] [ key ] = ""
            --end
            --measurements.tcpdump_pcaps [ key ] = ""
            measurements.iperf_s_outs [ key ] = ""
            measurements.iperf_c_outs [ key ] = ""
        end
    end

    local measurements = Measurements:create ( name, nil, nil, nil, input_dir, online )

    --measurements.tcpdump_pcaps = {}
    if ( key ~= nil ) then
        init_measurements ( measurements, name, input_dir, key )
        measurements:read ()
    else
        local keys = read_keys ( input_dir )
        if ( keys ~= nil ) then
        for _, key in ipairs ( keys ) do
                init_measurements ( measurements, name, input_dir, key )
            end
        end
        measurements:read ()
    end
    return measurements
end

function Measurements:read ()
    if ( self.output_dir == nil ) then
        return false, "output dir unset"
    end

    local base_dir = self.output_dir .. "/" .. self.node_name

    -- mac
    local fname = base_dir .. "/mac.txt"
    local file = io.open ( fname )
    if ( file ~= nil ) then
        self.node_mac = file:read ( "*a" )
        if ( self.node_mac ~= nil ) then
            self.node_mac = string.sub ( self.node_mac, 1, string.len ( self.node_mac) - 1 )
        end
        file:close()
    end
    -- mac for bridged setups ( tshark filters by bridge mac )
    local fname = base_dir .. "/mac_br.txt"
    if ( isFile ( fname ) ) then
        local file = io.open ( fname )
        if ( file ~= nil ) then
            self.node_mac_br = file:read ( "*a" )
            if ( self.node_mac_br ~= nil ) then
                self.node_mac_br = string.sub ( self.node_mac_br, 1, string.len ( self.node_mac_br) - 1 )
            end
            file:close()
        end
    end

    -- opposite macs
    local fname = base_dir .. "/opposite_macs.txt"
    local file = io.open ( fname )
    if ( file ~= nil ) then
        local content = file:read ( "*a" )
        if ( content ~= nil ) then
            self.opposite_macs = split ( content, "\n" )
            table.remove ( self.opposite_macs, #self.opposite_macs )
        end
        file:close()
    end
    -- opposite macs for bridged setups ( tshark filters by bridge mac )
    local fname = base_dir .. "/opposite_macs_br.txt"
    if ( isFile ( fname ) == true ) then
        local file = io.open ( fname )
        if ( file ~= nil ) then
            local content = file:read ( "*a" )
            if ( content ~= nil ) then
                self.opposite_macs_br = split ( content, "\n" )
                table.remove ( self.opposite_macs_br, #self.opposite_macs )
            end
            file:close()
        end
    end

    -- regmon stats
    for key, stats in pairs ( self.regmon_meas ) do
        self.add_key ( self, key, self.output_dir )
        meas : read ()
    end

--    for key, stats in pairs ( self.regmon_stats ) do
--        local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-regmon_stats.txt"
--        local file = io.open ( fname, "r" )
--        if ( file ~= nil ) then
--            stats = file:read ( "*a" )
--            self.regmon_stats [ key ] = stats
--            file:close ()
--        end
--    end

    -- cpusage stats
    for key, meas in pairs ( self.cpusage_meas ) do
        meas : read ()
    end
    --for key, stats in pairs ( self.cpusage_stats ) do
    --    local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-cpusage_stats.txt"
    --    local file = io.open ( fname, "r" )
    --    if ( file ~= nil ) then
    --        stats = file:read ( "*a" )
    --        self.cpusage_stats [ key ] = stats
    --        file:close ()
    --    end
    --end

    -- tcpdump pcap
    for key, meas in pairs ( self.tcpdump_meas ) do
        meas : read ()
    end

--    for key, stats in pairs ( self.tcpdump_pcaps ) do
--        local fname = self.output_dir .. "/" .. self.node_name 
--                    .. "/" .. self.node_name .. "-" .. key .. ".pcap"
--        local file = io.open (fname, "rb")
--        if ( file ~= nil ) then
--            stats = file:read ("*a")
--            self.tcpdump_pcaps [ key ] = stats
--            file:close ()
--        else
--            self.tcpdump_pcaps [ key ] = ""
--        end
--    end

    -- rc_stats
    if ( self.rc_stats_enabled == true ) then
        for _, station in ipairs ( self.stations ) do
            if ( self.rc_stats_meas ~= nil and self.rc_stats_meas [ station ] ~= nil ) then
                for key, meas in pairs ( self.rc_stats_meas [ station ] ) do
                    meas : read ()
                end
            end
        end
    end
    --if ( self.rc_stats_enabled == true ) then
    --    for _, station in ipairs ( self.stations ) do
    --        if ( self.rc_stats ~= nil and self.rc_stats [ station ] ~= nil ) then
    --            for key, stats in pairs ( self.rc_stats [ station ] ) do
    --                local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-rc_stats-"
    --                        .. station .. ".txt"
    --                local file = io.open(fname, "r")
    --                if ( file ~= nil ) then
    --                    stats = file:read ( "*a" )
    --                    self.rc_stats [ station ] [ key ] = stats
    --                    file:close ()
    --                end
    --            end
    --        end
    --    end
    --end

    -- iperf server out
    for key, stats in pairs ( self.iperf_s_outs ) do
        local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-iperf-server.txt"
        local file = io.open ( fname, "r" )
        if ( file ~= nil ) then
            stats = file:read ( "*a" )
            self.iperf_s_outs [ key ] = stats
            file:close ()
        end
    end

    -- iperf server out
    for key, stats in pairs ( self.iperf_c_outs ) do
        local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-iperf-client.txt"
        local file = io.open ( fname, "r" )
        if ( file ~= nil ) then
            stats = file:read ( "*a" )
            self.iperf_c_outs [ key ] = stats
            file:close ()
        end
    end

    return true, nil
end

function Measurements:is_open ( key )
    return self.regmon_meas [  key ].online_file ~= nil and self.tcdump_pcap_file ~= nil
    --return self.regmon_file ~= nil and self.tcdump_pcap_file ~= nil
end


function Measurements:write ( online, finish, key )
    if ( online == nil ) then online = false end
    if ( finish == nil ) then finish = true end
    if ( self.output_dir == nil ) then self.output_dir = "/tmp" end

    if ( key ~= nil and self.regmon_meas [ key ] == nil ) then
        self.add_key ( self, key, self.output_dir )
    end

    local base_dir = self.output_dir .. "/" .. self.node_name

    if ( self:is_open ( key ) == false and isDir ( base_dir ) == false ) then
        local status, err = lfs.mkdir ( base_dir )
        if ( status == false ) then 
            return false, err
        end
    end

    if ( self:is_open ( key ) == false ) then
        -- mac
        if ( self.node_mac ~= nil ) then
            local fname = base_dir .. "/mac.txt"
            local file = io.open ( fname, "w" )
            if ( file ~= nil ) then
                file:write ( self.node_mac .. '\n' )
                file:close ()
            end
        end
        if ( self.node_mac_br ~= nil ) then
            local fname = base_dir .. "/mac_br.txt"
            local file = io.open ( fname, "w" )
            if ( file ~= nil ) then
                file:write ( self.node_mac_br .. '\n' )
                file:close ()
            end
        end

        -- opposite macs
        if ( self.opposite_macs ~= nil ) then
            local fname = base_dir .. "/opposite_macs.txt"
            local file = io.open ( fname, "w" )
            if ( file ~= nil ) then
                for _, mac in ipairs ( self.opposite_macs ) do
                    file:write ( mac .. '\n' )
                end
                file:close ()
            end
        end
        if ( self.opposite_macs_br ~= nil ) then
            local fname = base_dir .. "/opposite_macs_br.txt"
            local file = io.open ( fname, "w" )
            if ( file ~= nil ) then
                for _, mac in ipairs ( self.opposite_macs_br ) do
                    file:write ( mac .. '\n' )
                end
                file:close ()
            end
        end

        -- regmon stats
        if ( online == true ) then
            self.regmon_meas [ key ] : open_online ()
            --local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-regmon_stats.txt"
            --self.regmon_file = io.open ( fname, "w" )
        end

        -- cpusage stats
        if ( online == true ) then
            self.cpusage_meas [ key ] : open_online ()
            --local fname = base_dir .. "/" .. self.node_name .. "-" .. key  .. "-cpusage_stats.txt"
            --self.cpusage_file = io.open ( fname, "w" )
        end

        -- tcpdump pcap
        if ( online == true ) then
            self.tcpdump_meas [ key ] : open_online ()
            --local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. ".pcap"
            --self.tcpdump_pcap_file = io.open ( fname, "w")
        end

        -- rc_stats
        if ( online == true ) then
            if ( self.rc_stats_enabled == true ) then
                for _, station in ipairs ( self.stations ) do
                    if ( self.rc_stats_meas ~= nil and self.rc_stats_meas [ station ] ~= nil
                         and self.rc_stats_meas [ station ] [ key ] ~= nil ) then
                         --fixme: not reached
                        self.rc_stats_meas [ station ] [ key ] : open_online ()
                    end
                end
            end
        end
        --if ( self.rc_stats_enabled == true ) then
        --    for _, station in ipairs ( self.stations ) do
        --        if ( self.rc_stats ~= nil and self.rc_stats [ station ] ~= nil ) then
        --            if ( online == true ) then
        --                local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-rc_stats-"
        --                          .. station .. ".txt"
        --                self.rc_stats_files [ station ] = io.open ( fname, "w" )
        --            end
        --        end
        --    end
        --end
    end

    -- regmon stats
    self.regmon_meas [ key ] : write ( online )
    if ( finish == true ) then
        self.regmon_meas [ key ]:close_online ()
    end

--    if ( online == false ) then
--        for key, stats in pairs ( self.regmon_stats ) do
--            local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-regmon_stats.txt"
--            self.regmon_file = io.open ( fname, "w" )
--            self.regmon_file:write ( stats )
--            self.regmon_file:close ()
--        end
--    else
--        self.regmon_file:write ( self.regmon_stats [ key ] )
--        if ( finish == true ) then
--            self.regmon_meas [ key ]:close_online ()
--            self.regmon_file:close ()
--        end
--    end

    -- cpusage stats
    self.cpusage_meas [ key ] : write ( online )
    if ( finish == true ) then
        self.cpusage_meas [ key ]:close_online ()
    end
    --if ( online == false ) then
    --    for key, stats in pairs ( self.cpusage_stats ) do
    --        local fname = base_dir .. "/" .. self.node_name .. "-" .. key  .. "-cpusage_stats.txt"
    --        self.cpusage_file = io.open ( fname, "w" )
    --        self.cpusage_file:write ( stats )
    --        self.cpusage_file:close ()
    --    end
    --else
    --    self.cpusage_file:write ( self.cpusage_stats [ key ] )
    --    if ( finish == true ) then
    --        self.cpusage_file:close ()
    --    end
    --end
    
    -- tcpdump pcap
    self.tcpdump_meas [ key ] : write ( online )
    if ( finish == true ) then
        self.tcpdump_meas [ key ]:close_online ()
    end
--    if ( online == false ) then
--        for key, stats in pairs ( self.tcpdump_pcaps ) do
--            local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. ".pcap"
--            self.tcpdump_pcap_file = io.open ( fname, "w")
--            self.tcpdump_pcap_file:write ( stats )
--            self.tcpdump_pcap_file:close ()
--        end
--   else
--        self.tcpdump_pcap_file:write ( self.tcpdump_pcaps [ key ] )
--        if ( finish == true ) then
--            self.tcpdump_pcap_file:close ()
--        end
--   end

    -- rc_stats
    if ( self.rc_stats_enabled == true ) then
        for _, station in ipairs ( self.stations ) do
            if ( self.rc_stats_meas ~= nil and self.rc_stats_meas [ station ] ~= nil
                 and self.rc_stats_meas [ station ] [ key ] ~= nil ) then
                --fixme: never reached
                self.rc_stats_meas [ station ] [ key ] : write ( online )
                if ( finish == true ) then
                    self.rc_stats_meas [ station ] [ key ] : close_online ()
                end
            end
        end
    end
    --if ( self.rc_stats_enabled == true ) then
    --    for _, station in ipairs ( self.stations ) do
    --        if ( self.rc_stats ~= nil and self.rc_stats [ station ] ~= nil ) then
    --            if ( online == false ) then
    --                for key, stats in pairs ( self.rc_stats [ station ] ) do
    --                    local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-rc_stats-"
    --                        .. station .. ".txt"
    --                    self.rc_stats_files [ station ] = io.open ( fname, "w" )
    --                    self.rc_stats_files [ station ]:write ( stats )
    --                    self.rc_stats_files [ station ]:close ()
    --                end
    --            else
    --                self.rc_stats_files [ station ]:write ( self.rc_stats [ station ] [ key ] )
    --                if ( finish == true ) then
    --                    self.rc_stats_files [ station ]:close ()
    --                end
    --            end
    --        end
    --    end
    --end

    if ( online == false or finish == true ) then
        -- iperf server out
        for key, stats in pairs ( self.iperf_s_outs ) do
            local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-iperf_server.txt"
            local file = io.open ( fname, "w")
            if ( file ~= nil )  then
                file:write ( stats )
                file:close ()
            end
        end

        -- iperf client out
        for key, stats in pairs ( self.iperf_c_outs ) do
            local fname = base_dir .. "/" .. self.node_name .. "-" .. key .. "-iperf_client.txt"
            local file = io.open ( fname, "w")
            if ( file ~= nil )  then
                file:write ( stats )
                file:close ()
            end
        end
    end

    return true
end

function Measurements:__tostring () 
    local out = "Measurements\n==========\n"
    out = out .. self.node_name .. "\n"
    out = out .. ( self.node_mac or "no mac set" ) .. "\n"
    out = out .. ( self.node_mac_br or "no mac (bridged) set" ) .. "\n"
    -- regmon stats
    out = out .. "regmon: " .. table_size ( self.regmon_meas ) .. " stats\n"
    --out = out .. "regmon: " .. table_size ( self.regmon_stats ) .. " stats\n"
    local key
    local stat
    for _, meas in pairs ( self.regmon_meas ) do
        out = out .. meas : __tostring ()
    end
    --for key, stat in pairs ( self.regmon_stats ) do
    --    out = out .. "regmon-" .. key .. ": " .. string.len(stat) .. " bytes\n"
        --print (stat)
    --end
    -- cpusage stats
    out = out .. "cpusage: " .. table_size ( self.cpusage_meas ) .. " stats\n"
    --out = out .. "cpusage: " .. table_size ( self.cpusage_stats ) .. " stats\n"
    for _, meas in pairs ( self.cpusage_meas ) do
        out = out .. meas : __tostring ()
    end
    --for key, stat in pairs ( self.cpusage_stats ) do
    --    out = out .. "cpusage_stats-" .. key .. ": " .. string.len(stat) .. " bytes\n"
    --    for _, str in ipairs ( split ( stat, "\n" ) ) do
    ----        local cpustat = parse_cpusage ( str )
    ----        print (cpustat)
    --    end
    --end
    -- tcpdump pcap
    -- -- pcap.DLT = { EN10MB=DLT_EN10MB, [DLT_EN10MB] = "EN10MB", ... }
    out = out .. "pcaps: " .. table_size ( self.tcpdump_meas ) .. " stats\n"
    --out = out .. "pcaps: " .. table_size ( self.tcpdump_pcaps ) .. " stats\n"
    for _, meas in pairs ( self.tcpdump_meas ) do
        out = out .. meas : __tostring ()
    end
    --for key, stats in pairs ( self.tcpdump_pcaps ) do
    --    out = out .. "tcpdump_pcap-" .. key .. ": " .. string.len ( stats ) .. " bytes\n"
    --end
    -- rc_stats
    if ( self.rc_stats_enabled == true ) then
        for _, station in ipairs ( self.stations ) do
            out = out .. "rc_stats:" .. table_size ( self.rc_stats_meas [ station ] ) .. " stats\n"
            --out = out .. "rc_stats:" .. table_size ( self.rc_stats [ station ] ) .. " stats\n"
            if ( self.rc_stats_meas ~= nil and self.rc_stats_meas [ station ] ~= nil ) then
                for _, meas in pairs ( self.rc_stats_meas [ station ] ) do
                    out = out .. meas : __tostring ()
                end
            end
            --if ( self.rc_stats ~= nil and self.rc_stats [ station ] ~= nil) then
            --    for key, stat in pairs ( self.rc_stats [ station ] ) do
            --        out = out .. "rc_stats-" .. station .. "-" .. key .. ": " .. string.len ( stat ) .. " bytes\n"
            --        -- if (stat ~= nil) then print (stat) end
            --    end
            --end
        end
    end
    -- iperf server out
    for key, stat in pairs ( self.iperf_s_outs ) do
        out = out .. "iperf-server-" .. key .. ": " .. stat .. "\n"
    end
    -- iperf client out
    for key, stat in pairs ( self.iperf_c_outs ) do
        out = out .. "iperf-client-" .. key .. ": " .. stat .. "\n"
    end

    return out 
end

function Measurements:enable_rc_stats ( stations )
    if ( stations == nil or stations == {} ) then
        self.rc_stats_enabled = false
        return
    end
    self.rc_stats_enabled = true
    self.stations = stations
    for _, station in ipairs ( stations ) do
        self.rc_stats_meas [ station ] = {}
        --self.rc_stats [ station ] = {}
    end
end

function Measurements:start ( phy, key )
    self.add_key ( self, key, self.output_dir )
    -- regmon 
    --self.regmon_stats [ key ] = ""
    local regmon_pid = self.rpc_node.start_regmon_stats ( phy )
    -- cpusage
    --self.cpusage_stats [ key ] = ""
    local cpusage_pid = self.rpc_node.start_cpusage ( phy )
    -- tcpdump
    --self.tcpdump_pcaps [ key ] = ""
    local  fname = nil
    if ( self.online == false ) then
        local fname = "/tmp/" .. self.node_name .. "-" .. key .. ".pcap"
        local tcpdump_pid = self.rpc_node.start_tcpdump ( phy, fname )
    else
        local tcpdump_pid = self.rpc_node.start_tcpdump ( phy )
    end
    -- rc stats
    if ( self.rc_stats_enabled == true ) then
        for _, station in ipairs ( self.stations ) do
            --self.rc_stats [ station ] [ key ] = ""
            local rc_stats_pid = self.rpc_node.start_rc_stats ( phy, station )
        end
    end
    return true
end

function Measurements:stop ( phy, key )
    -- regmon 
    local exit_code = self.rpc_node.stop_regmon_stats ( phy )
    -- cpusage
    local exit_code = self.rpc_node.stop_cpusage ( phy )
    -- tcpdump
    local exit_code = self.rpc_node.stop_tcpdump ( phy )
    -- rc_stats
    if ( self.rc_stats_enabled == true ) then
        for _, station in ipairs ( self.stations ) do
            local exit_code = self.rpc_node.stop_rc_stats ( phy, station )
        end
    end
end

function Measurements:fetch ( phy, key )
    local running = true
    local stats = nil
    -- regmon
    if ( self.regmon_meas [ key ] == nil ) then
        self.add_key ( self, key, self.output_dir )
    end
    stats = self.rpc_node.get_regmon_stats ( phy, self.online )
    if ( stats ~= nil ) then
        self.regmon_meas [ key ].stats = ( self.regmon_meas [ key ].stats or "" ) .. stats
        --self.regmon_stats [ key ] = self.regmon_stats [ key ] .. stats
    else
        --running = false
    end
    -- cpusage
    stats = self.rpc_node.get_cpusage ( phy, self.online )
    if ( stats ~= nil ) then
        self.cpusage_meas [ key ].stats = ( self.cpusage_meas [ key ].stats or "" ) .. stats
        --self.cpusage_stats [ key ] = self.cpusage_stats [ key ] .. stats 
    end
    -- tcpdump
    local fname = nil
    if ( self.online == false ) then
        fname = "/tmp/" .. self.node_name .."-" .. key .. ".pcap"
    end
    stats = self.rpc_node.get_tcpdump ( phy, fname )
    if ( stats ~= nil ) then
        self.tcpdump_meas [ key ].stats = ( self.tcpdump_meas [ key ].stats or "" ) .. stats
        --self.tcpdump_pcaps [ key ] = self.tcpdump_pcaps [ key ] .. stats 
    else
        running = false
    end
    
    -- rc_stats
    if ( self.rc_stats_enabled == true ) then
        for _, station in ipairs ( self.stations ) do
            if ( self.rc_stats_meas == nil
                 or self.rc_stats_meas [ station ] == nil
                 or self.rc_stats_meas [ station ] [ key ] == nil ) then
                self.add_key ( self, key, self.output_dir )
            end
            local stats = self.rpc_node.get_rc_stats ( phy, station, self.online )
            if ( stats ~= nil
                and self.rc_stats_meas ~= nil and self.rc_stats_meas [ station ] ~= nil
                and self.rc_stats_meas [ station ] [ key ] ~= nil ) then
                -- fixme: never reached
                self.rc_stats_meas [ station ] [ key ].stats 
                    = ( self.rc_stats_meas [ station ] [ key ].stats or "" )
                      .. stats
                --self.rc_stats [ station ] [ key ] = self.rc_stats [ station ] [ key ] .. stats
            else
                running = false
            end
        end
    end

    return running

    -- iperf server out
    -- iperf client out
    -- already done by wait_iperf_c and stop_iperf_s
end

function Measurements:cleanup ( phy, key )
    self.rpc_node.cleanup_cpusage ( phy )
    self.rpc_node.cleanup_regmon ( phy )
    if ( self.rc_stats_enabled == true ) then
        for _, station in ipairs ( self.stations ) do
            self.rpc_node.cleanup_rc_stats ( phy, station )
        end
    end
    self.rpc_node.cleanup_tcpdump ( phy )
end

function Measurements.resume ( output_dir, online )
    local keys = nil
    for _, name in ipairs ( ( scandir ( output_dir ) ) ) do
        if ( name ~= "." and name ~= ".."  and isDir ( output_dir .. "/" .. name )
             and Config.find_node ( name, nodes ) ~= nil ) then
            local measurement = Measurements.parse ( name, output_dir, nil, online )
            for key, pcap in pairs ( measurement.tcpdump_meas ) do
            --for key, pcap in pairs ( measurement.tcpdump_pcaps ) do
                if ( pcap == nil or pcap == "" ) then
                    if ( keys == nil ) then
                        keys = {}
                        keys [1] = {}
                    end
                    if ( Misc.index_of ( key, keys [1] ) == nil ) then
                        keys [1] [ #keys [1] + 1 ] = key
                    end
                end
            end
        end
    end
    return keys
end