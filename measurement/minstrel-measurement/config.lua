aps = { 
    { name = "lede-ap"
    , radio = "radio0"
    , ctrl_if = "br-lan"
    }
}

stations = {
    { name = "lede-sta"
    , radio = "radio0"
    , ctrl_if = "eth0"
    },

    { name = "lede-ctrl"
    , radio = "radio0"
    , ctrl_if = "eth0"
    }
}

mesh = {
    { name = "lede-ap"
    , radio = "radio0"
    , ctrl_if = "br-lan"
    },

    { name = "lede-sta"
    , radio = "radio0"
    , ctrl_if = "eth0"
    },

    { name = "lede-ctrl"
    , radio = "radio0"
    , ctrl_if = "eth0"
    }
}