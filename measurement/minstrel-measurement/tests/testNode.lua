require ('Node')
require ('net')

local iface = NetIF:create("lo0" , "127.0.0.1", nil)
node = Node:create("TestNode", iface, iface)
assert ( node ~= nil )
assert ( node.ctrl ~= nil )
assert ( node.ctrl.iface == "lo0" )
assert ( node.ctrl.addr == "127.0.0.1" )
assert ( node.ctrl.mon == nil )
assert ( node.ctrl.phy == nil )

local ctrl = NetIF:create("eth0") 
node = Node:create("TestNode", ctrl)

-- these tests may differ on each system

local ctrl_addr = Net.get_addr ( "eth0" ) 

assert ( node ~= nil )
assert ( node.ctrl ~= nil )
assert ( node.ctrl.iface == "eth0" )
assert ( node.ctrl.addr == ctrl_addr )
assert ( node.ctrl.mon == nil )
assert ( node.ctrl.phy == nil )

assert ( node.wifis ~= nil )
assert ( table_size ( node.wifis ) > 0 )

if ( Net.get_hostname () == "sinope" ) then
    local wlan_addr = Net.get_addr ( "wlan1" ) 
    print ( node:__tostring() )
    assert ( node.wifis[1].iface == "wlan1" )
    assert ( node.wifis[1].addr == wlan_addr )
    assert ( node.wifis[1].mon == "mon1" )
    assert ( node.wifis[1].phy == "phy1" )
else
    print ( node:__tostring() )
end
