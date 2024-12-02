import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Storage;
import Toybox.Math;

class TileSliderDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new TileSliderSettings(), new TileSliderMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onTap(clickEvent) as Boolean {
        var xy = clickEvent.getCoordinates();
        var state = game.get("state");
        switch (state) {
            case 0:
                // check for start/new
                if (inbox(newXY,newWH,xy)) {
System.println("tapped start");
                    state++;
                    game.put("state",state);
                    Storage.setValue("game",game);
                    shuffle();
                    WatchUi.requestUpdate();
                    return true;
                }
                // check for prev / next image
                if (inCircle(xy,previmageXY,rad)) {
System.println("tapped prev image");
                    image--;
                    if (image < 0) { image = images.size()-1; }
                    game.put("image",image);
                    Storage.setValue("game",game);
                    loadimage();
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inCircle(xy,nextimageXY,rad)) {
System.println("tapped next image");
                    image++;
                    if (image > images.size()-1) { image = 0; }
                    game.put("image",image);
                    Storage.setValue("game",game);
                    loadimage();
                    WatchUi.requestUpdate();
                    return true;
                }
                // check for prev / next dimension
                if (inCircle(xy,prevdimXY,rad)) {
System.println("tapped prev dim");
                    rows--;
                    if (rows < 3) { rows = 6; }
                    cols = rows;
                    game.put("rows",rows);
                    game.put("cols",cols);
                    inittiles();
                    game.put("tiles",tiles);
                    game.put("solved",solved);
                    Storage.setValue("game",game);
                    loadimage();
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inCircle(xy,nextdimXY,rad)) {
System.println("tapped next dim");
                    rows++;
                    if (rows > 6) { rows = 3; }
                    cols = rows;
                    game.put("rows",rows);
                    game.put("cols",cols);
                    inittiles();
                    game.put("tiles",tiles);
                    game.put("solved",solved);
                    Storage.setValue("game",game);
                    loadimage();
                    WatchUi.requestUpdate();
                    return true;
                }
                break;
            case 1:
                // check for new
                if (inbox(newXY,newWH,xy)) {
System.println("tapped new");
                    newgame();
                    WatchUi.requestUpdate();
                    return true;
                }
                // check for tile
                if (!showing) {
                    tmp = (square/rows).toNumber();
                    for (var r=0;r<rows;r++) {
                        for (var c=0;c<cols;c++) {
                            tmp3 = r*cols+c;
                            if (inbox(tileXY[tmp3],[tmp,tmp],xy)) {
System.println("tapped tile "+tmp3);
                                if (proctile(r,c)) {
                                    game.put("tiles",tiles);
                                    game.put("moves",moves);
                                    if (tiles.toString().equals(solved.toString())) {
                                        state = 2;
                                        savestats();
                                        game.put("state",state);
                                    }
                                    Storage.setValue("game",game);
                                    WatchUi.requestUpdate();
                                    return true;
                                }
                            }
                        }
                    }
                }
                // check for show
                if (inbox(showXY,showWH,xy)) {
System.println("tapped show/back");
                    showing = !showing;
                    WatchUi.requestUpdate();
                    return true;
                }
                break;
            case 2:
                if (inbox(newXY,newWH,xy)) {
System.println("tapped new");
                    newgame();
                    WatchUi.requestUpdate();
                    return true;
                }
                break;
        }
        return false;
    }

    public function inCircle(point, circle, rad) {
        var x = point[0];
        var y = point[1];
        var cx = circle[0];
        var cy = circle[1];
        return ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= rad * rad);
    }

    // Check if a point is within a box
    // boxxy = [x,y] coordinates of upper left corner of box
    // boxwh = [w,h] width and height of box
    // point = [x,y] coordinates of point to check
    public function inbox(boxxy,boxwh,point) as Boolean {
        if (point[0]<boxxy[0]) {return false;}
        if (point[0]>boxxy[0]+boxwh[0]) {return false;}
        if (point[1]<boxxy[1]) {return false;}
        if (point[1]>boxxy[1]+boxwh[1]) {return false;}
        return true;
    }

    // Check tile at inr,inc to see if it's on the same row or column as the blank tile
    // if so, shift the tiles and return true
    // else return false
    function proctile(inr,inc) as Boolean {

        tmp = inr*cols+inc;
        if (tiles[inr][inc] == 0) { return false; }
        for (var r=0;r<rows;r++) {
            if (tiles[r][inc] == 0) {
                if (r<inr) {
                    for (var i=r;i<inr;i++) {
                        tiles[i][inc] = tiles[i+1][inc];
                        moves++;
                    }
                } else {
                    for (var i=r;i>inr;i--) {
                        tiles[i][inc] = tiles[i-1][inc];
                        moves++;
                    }
                }
                tiles[inr][inc] = 0;
                return true;
            }
        }
        for (var c=0;c<cols;c++) {
            if (tiles[inr][c] == 0) {
                if (c<inc) {
                    for (var i=c;i<inc;i++) {
                        tiles[inr][i] = tiles[inr][i+1];
                        moves++;
                    }
                } else {
                    for (var i=c;i>inc;i--) {
                        tiles[inr][i] = tiles[inr][i-1];
                        moves++;
                    }
                }
                tiles[inr][inc] = 0;
                return true;
            }
        }
        return false;
    }

    function shuffle() {
        rows = game.get("rows");
        cols = game.get("cols");
        tiles = game.get("tiles");
        var found = false;
        var r = rows-1;
        var c = cols-1;
        var nr = 0;
        var nc = 0;
        for (var i=0;i<1000;i++) {
            if ((Math.rand() % 2) == 1) {
                if (r == 0) { nr = r+1; }
                else if (r == rows-1) { nr = r-1; }
                else if (Math.rand() % 2 == 1) { nr = r+1; }
                else { nr = r-1; }
                tiles[r][c] = tiles[nr][c];
                tiles[nr][c] = 0;
                r = nr;
            } else {
                if (c == 0) { nc = c+1; }
                else if (c == cols-1) { nc = c-1; }
                else if (Math.rand() % 2 == 1) { nc = c+1; }
                else { nc = c-1; }
                tiles[r][c] = tiles[r][nc];
                tiles[r][nc] = 0;
                c = nc;
            }
        }
        game.put("tiles",tiles);
        Storage.setValue("game",game);
        WatchUi.requestUpdate();
    }
}
