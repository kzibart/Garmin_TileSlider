import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Application.Storage;

class TileSliderMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) {
        switch (item.getId()) {
            case "theme":
                theme = (theme + 1) % themes.size();
                Storage.setValue("theme",theme);
                item.setSubLabel(themes[theme]);
                if (game.get("image") == 0) {
                    loadimage();
                }
                break;
            case "hint":
                hint = (hint + 1) % hints.size();
                Storage.setValue("hint",hint);
                item.setSubLabel(hints[hint]);
                break;
            case "stats":
                showstats();
                break;
        }
    }

    public function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}