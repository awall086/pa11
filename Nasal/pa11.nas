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
    setprop("/controls/switches/starter", 1);
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
    var sound_prop = "/sim/model/pa11/sound/click-" ~ name;

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

var update_pax = func {
    var state = 0;
    state = bits.switch(state, 0, getprop("pax/pilot/present"));
    state = bits.switch(state, 1, getprop("pax/co-pilot/present"));
    setprop("/payload/pax-state", state);
};

############################################
# Static objects: Place
############################################

var StaticModel = {
    new: func (name, file) {
        var m = {
            parents: [StaticModel],
            model: nil,
            model_file: file,
			object_name: name
        };

        setlistener("/sim/" ~ name ~ "/enable", func (node) {
            if (node.getBoolValue()) {
                m.add();
            }
            else {
                m.remove();
            }
        });

        return m;
    },

    add: func {
        var manager = props.globals.getNode("/models", 1);
        var i = 0;
        for (; 1; i += 1) {
            if (manager.getChild("model", i, 0) == nil) {
                break;
            }
        }
        var position = geo.aircraft_position().set_alt(getprop("/position/ground-elev-m"));
        me.model = geo.put_model(me.model_file, position, getprop("/orientation/heading-deg"));
    },

    remove: func {
        if (me.model != nil) {
            me.model.remove();
            me.model = nil;
        }
    }
};

StaticModel.new("coneR", "Aircraft/pa11/Models/Exterior/safety-cone/safety-cone_R.xml");
StaticModel.new("coneL", "Aircraft/pa11/Models/Exterior/safety-cone/safety-cone_L.xml");

#following ground equipement stuff placing was only possible by the help of the work by: Melchior Franz, Anders Gidenstam, Detelf Faber, onox. Thanks!
#wheel chocks======================================================

var chocks001_model = {
       index:   0,
       add:   func {
  var manager = props.globals.getNode("/models", 1);
                var i = 0;
                for (; 1; i += 1)
                   if (manager.getChild("model", i, 0) == nil)
                      break;

		var chocks001 = geo.aircraft_position().set_alt(
				props.globals.getNode("/position/ground-elev-m").getValue());

		geo.put_model("Aircraft/pa11/Models/Exterior/chocks/LWchocks.ac", chocks001,
				props.globals.getNode("/orientation/heading-deg").getValue());
					 me.index = i;
          },

       remove:   func {
                #print("chocks001_model.remove");
             props.globals.getNode("/models", 1).removeChild("model", me.index);
          },
};

var init_common = func {
	setlistener("/sim/chocks001/enable", func(n) {
		if (n.getValue()) {
				chocks001_model.add();
		} else  {
			chocks001_model.remove();
		}
	});
}
settimer(init_common,0);

var chocks002_model = {
       index:   0,
       add:   func {
  var manager = props.globals.getNode("/models", 1);
                var i = 0;
                for (; 1; i += 1)
                   if (manager.getChild("model", i, 0) == nil)
                      break;

		var chocks002 = geo.aircraft_position().set_alt(
				props.globals.getNode("/position/ground-elev-m").getValue());

		geo.put_model("Aircraft/pa11/Models/Exterior/chocks/RWchocks.ac", chocks002,
				props.globals.getNode("/orientation/heading-deg").getValue());
					 me.index = i;
          },

       remove:   func {
                #print("chocks002_model.remove");
             props.globals.getNode("/models", 1).removeChild("model", me.index);
          },
};

var init_common = func {
	setlistener("/sim/chocks002/enable", func(n) {
		if (n.getValue()) {
				chocks002_model.add();
		} else  {
			chocks002_model.remove();
		}
	});
}
settimer(init_common,0);


var reset_system = func {
    if (getprop("/fdm/jsbsim/running")) {
        pa11.autostart(0);
    }
};

setlistener("/pax/pilot/present", update_pax, 0, 0);
setlistener("/pax/co-pilot/present", update_pax, 0, 0);
update_pax();

setlistener("/engines/engine/running", func (node) {
    var autostart = getprop("/engines/engine/auto-start");
    var cranking  = getprop("/engines/engine/cranking");
    if (autostart and cranking and node.getBoolValue()) {
        setprop("/controls/engines/engine/starter", 0);
        setprop("/engines/engine/auto-start", 0);
    }
}, 0, 0);