##########################################
# Autostart
##########################################

var autostart = func (msg=1) {
    if (getprop("/engines/engine/running")) {
        if (msg)
            gui.popupTip("Engine already running", 5);
        return;
    }

    # Filling fuel tanks
	setprop("/controls/fuel/fuel-on", 1);

    # Setting levers radios and switches for startup
    setprop("/controls/switches/magnetos", 3);
    setprop("/controls/engines/engine/throttle", 0.10);
    setprop("/controls/engines/engine/mixture", 1.00);
    setprop("/controls/flight/elevator-trim", 0.0);
    setprop("/controls/switches/master-bat", 1);
    setprop("/controls/switches/master-alt", 1);
	setprop("/controls/engines/engine/primer", 3);

    # All set, starting engine
    setprop("/controls/engines/engine/starter", 1);
    setprop("/engines/engine/auto-start", 1);

    var engine_running_check_delay = 5.0;
    settimer(func {
        if (!getprop("/engines/engine/running")) {
            gui.popupTip("The autostart failed to start the engine. You must lean the mixture and start the engine manually.", 5);
        }
        setprop("/controls/switches/starter", 0);
        setprop("/engines/engine/auto-start", 0);
    }, engine_running_check_delay);

};

##########################################
# Click Sounds
##########################################

var click = func (name, timeout=0.1, delay=0) {
    var sound_prop = "/sim/model/c152/sound/click-" ~ name;

    settimer(func {
        # Play the sound
        setprop(sound_prop, 1);

        # Reset the property after 0.2 seconds so that the sound can be
        # played again.
        settimer(func {
            setprop(sound_prop, 0);
        }, timeout);
    }, delay);
};


var reset_system = func {
    if (getprop("/fdm/jsbsim/running")) {
        pa11.autostart(0);
    }
};

setlistener("/engines/engine/running", func (node) {
    var autostart = getprop("/engines/engine/auto-start");
    var cranking  = getprop("/engines/engine/cranking");
    if (autostart and cranking and node.getBoolValue()) {
        setprop("/controls/engines/engine/starter", 0);
        setprop("/engines/engine/auto-start", 0);
    }
}, 0, 0);