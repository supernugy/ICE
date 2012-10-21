
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// The main GUI class.
module gui2.guisystem;

import gui2.event;
import gui2.rootwidget;
import gui2.slotwidget;
import util.yaml;


/// The main GUI class. Manages widgets, emits events, etc.
class GUISystem
{
    /// The root of the widget tree.
    SlotWidget rootSlot_;

public:
    /// Construct the GUISystem.
    this()
    {
        //TODO the rootSlot_ widget should have a fixed layout
        rootSlot_ = new SlotWidget(YAMLNode(), this);
    }

    /// Load a widget tree connectable to a SlotWidget from YAML.
    RootWidget loadWidgetTree(YAMLNode source)
    {
        assert(false, "TODO");
    }

    /// Get the root SlotWidget.
    @property SlotWidget rootSlot()
    {
        return rootSlot_;
    }

package:
    /// Update layout of all widgets (e.g. after a new RootWidget is connected).
    void updateLayout()
    {
        // Reusing the same instances every time to avoid unnecessary allocation.
        static MinimizeEvent minimizeEvent;
        static ExpandEvent expandEvent;
        if(null is minimizeEvent){minimizeEvent = new MinimizeEvent();}
        if(null is expandEvent)  {expandEvent   = new ExpandEvent();}
        rootSlot_.handleEvent(minimizeEvent);
        rootSlot_.handleEvent(expandEvent);
    }
}
