
local argparse = require ('argparse')
local pprint = require ('pprint')
local config = require ('Config')

require ('Measurement')

require ('FXsnrAnalyser')
require ('SNRRenderer')

local parser = argparse("netRun", "Run minstrel blues multi AP / multi STA mesurement")

parser:argument("input", "measurement / analyse data directory","/tmp")

local args = parser:parse()

local _, aps, stas = Config.read ( args.input )

for _, name in ipairs ( ( scandir ( args.input ) ) ) do

    if ( name ~= "." and name ~= ".."  and isDir ( args.input .. "/" .. name ) ) then

        print ( "read measurement: " .. name )
        --if ( Config.find_node ( name, nodes ) ~= nil ) then
        local measurement = Measurement.parse ( name, args.input )
        print ( measurement:__tostring () )
        --end

        print ( "Analyse SNR" )
        local analyser = FXsnrAnalyser:create ( aps, stas )
        local snrs = analyser:snrs ( measurement )
        pprint ( snrs )
        --print ( )

        --print ( "Plot SNR" )
        --local renderer = SNRRenderer:create ( snrs, aps, stas )

        --local dirname = args.input .. "/" .. measurement.node_name
        --renderer:run ( dirname )
    end
end
