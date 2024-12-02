import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application.Storage;
import Toybox.Lang;

var game;
var rows = 3;
var cols = 3;
var state = 0;
var image = 0;
var tiles,tileXY,tileWH,solved;
var tileimages = new [100];
var stats;

var center = Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER;
var DS = System.getDeviceSettings();
var SW = DS.screenWidth;
var SH = DS.screenHeight;
var square = SW*0.7;
var tmp,tmp2,tmp3;
var bmsize = 454;
var showright = true;
var moves = 0;
var average = 0;
var theme = 0;
var themes = ["Just Text", "Outlines", "Solid Buttons"];
var hint = 0;
var hints = ["No Hints", "Outline Correct"];
var showing = false;

var rad = ((SH-square)*.17).toNumber();
var so = (rad*.1).toNumber();
var dimXY = [SW/2,((SH-square)*.3).toNumber()];
var showXY = [(SW/2-SW*.15).toNumber(),((SH-square)*.12).toNumber()];
var showWH = [(SW*.3).toNumber(),rad*2];
var prevdimXY = [(SW*.35).toNumber(),((SH-square)*.3).toNumber()];
var nextdimXY = [(SW*.65).toNumber(),((SH-square)*.3).toNumber()];
var previmageXY = [((SW-square)*.27).toNumber(),SH/2];
var nextimageXY = [SW-((SW-square)*.27).toNumber(),SH/2];
var newXY = [(SW/2-SW*.15).toNumber(),SH-((SH-square)*.48).toNumber()];
var newWH = [(SW*.3).toNumber(),rad*2];

var images = [
    Rez.Drawables.dog,
    Rez.Drawables.dog,
    Rez.Drawables.flower,
    Rez.Drawables.spider,
    Rez.Drawables.stones,
    Rez.Drawables.flowers,
    Rez.Drawables.bear,
    Rez.Drawables.pumpkins,
    Rez.Drawables.autumn,
    Rez.Drawables.coaster
];

class TileSliderView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        game = Storage.getValue("game");
        if (game == null) { newgame(); }
        hint = Storage.getValue("hint");
        if (hint == null) { hint = 0; }
        showright = (hint == 1);
        theme = Storage.getValue("theme");
        if (theme == null) { theme = 0; }
System.println("onLayout loading image");
        loadimage();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // state:
        // 0 = starting new game
        //     screen layout:
        //     top: shuffle button
        //     mid: grid of tiles showing image or numbers with arrows on left/right to select image
        //     bot: grid size with arrows on left/right to select grid size
        //     when an arrow is pressed, change image or grid size, rebuild tiles, redraw tiles
        //     when shuffle is pressed, shuffle the grid, redraw tiles, switch to stage 1
        // 1 = playing the game (sliding tiles)
        //     screen layout:
        //     top: new button
        //     mid: grid of tiles as large as possible for the screen
        //     bot: empty?
        //     when a tile is pressed, if 0 is on same row or column, shift values towards 0
        //     check if tiles are in order
        //     if new is pressed, call newgame
        // 2 = game over (showing final image)

        dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        dc.clear();

        hint = Storage.getValue("hint");
        if (hint == null) { hint = 0; }
        showright = (hint == 1);
        theme = Storage.getValue("theme");
        if (theme == null) { theme = 0; }

System.println("onUpdate drawing tiles");
        drawtiles(dc);

        state = game.get("state");
        moves = game.get("moves");
        stats = Storage.getValue("stats");
System.println("onUpdate state = "+state);

        var font = null;
        if (Toybox.Graphics has :getVectorFont) {
            System.println("got it!");
            font = Graphics.getVectorFont({:face=>["RobotoRegular"],:size=>45});
        } else {
            System.println("don't got it!");
        }
        dc.setPenWidth(3);
        switch (state) {
            case 0:
                // draw grid selection area
                if (theme != 0) {
                    dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                    dc.drawText(dimXY[0]+so, dimXY[1]+so, Graphics.FONT_SMALL, rows+"x"+cols, center);
                }
                dc.setColor(Graphics.COLOR_GREEN,-1);
                dc.drawText(dimXY[0], dimXY[1], Graphics.FONT_SMALL, rows+"x"+cols, center);
                switch (theme) {
                    case 0:
                        dc.setColor(Graphics.COLOR_BLUE,-1);
                        dc.drawText(prevdimXY[0], prevdimXY[1], Graphics.FONT_SMALL, "<", center);
                        dc.drawText(nextdimXY[0], nextdimXY[1], Graphics.FONT_SMALL, ">", center);
                        break;
                    case 1:
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawCircle(prevdimXY[0]+so, prevdimXY[1]+so, rad);
                        dc.drawCircle(nextdimXY[0]+so, nextdimXY[1]+so, rad);
                        dc.setColor(Graphics.COLOR_BLUE,-1);
                        dc.drawCircle(prevdimXY[0], prevdimXY[1], rad);
                        dc.drawCircle(nextdimXY[0], nextdimXY[1], rad);
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawText(prevdimXY[0]+so, prevdimXY[1]+so, Graphics.FONT_SMALL, "<", center);
                        dc.drawText(nextdimXY[0]+so, nextdimXY[1]+so, Graphics.FONT_SMALL, ">", center);
                        dc.setColor(Graphics.COLOR_BLUE,-1);
                        dc.drawText(prevdimXY[0], prevdimXY[1], Graphics.FONT_SMALL, "<", center);
                        dc.drawText(nextdimXY[0], nextdimXY[1], Graphics.FONT_SMALL, ">", center);
                        break;
                    case 2:
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.fillCircle(prevdimXY[0]+so, prevdimXY[1]+so, rad);
                        dc.fillCircle(nextdimXY[0]+so, nextdimXY[1]+so, rad);
                        dc.setColor(Graphics.COLOR_BLUE,-1);
                        dc.fillCircle(prevdimXY[0], prevdimXY[1], rad);
                        dc.fillCircle(nextdimXY[0], nextdimXY[1], rad);
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawText(prevdimXY[0]-so, prevdimXY[1]-so, Graphics.FONT_SMALL, "<", center);
                        dc.drawText(nextdimXY[0]-so, nextdimXY[1]-so, Graphics.FONT_SMALL, ">", center);
                        dc.setColor(Graphics.COLOR_BLACK,-1);
                        dc.drawText(prevdimXY[0], prevdimXY[1], Graphics.FONT_SMALL, "<", center);
                        dc.drawText(nextdimXY[0], nextdimXY[1], Graphics.FONT_SMALL, ">", center);
                        break;
                }

                // draw prev / next image buttons
                switch (theme) {
                    case 0:
                        dc.setColor(Graphics.COLOR_BLUE,-1);
                        dc.drawText(previmageXY[0], previmageXY[1], Graphics.FONT_SMALL, "<", center);
                        dc.drawText(nextimageXY[0], nextimageXY[1], Graphics.FONT_SMALL, ">", center);
                        break;
                    case 1:
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawCircle(previmageXY[0]+so, previmageXY[1]+so, rad);
                        dc.drawCircle(nextimageXY[0]+so, nextimageXY[1]+so, rad);
                        dc.setColor(Graphics.COLOR_BLUE,-1);
                        dc.drawCircle(previmageXY[0], previmageXY[1], rad);
                        dc.drawCircle(nextimageXY[0], nextimageXY[1], rad);
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawText(previmageXY[0]+so, previmageXY[1]+so, Graphics.FONT_SMALL, "<", center);
                        dc.drawText(nextimageXY[0]+so, nextimageXY[1]+so, Graphics.FONT_SMALL, ">", center);
                        dc.setColor(Graphics.COLOR_BLUE,-1);
                        dc.drawText(previmageXY[0], previmageXY[1], Graphics.FONT_SMALL, "<", center);
                        dc.drawText(nextimageXY[0], nextimageXY[1], Graphics.FONT_SMALL, ">", center);
                        break;
                    case 2:
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.fillCircle(previmageXY[0]+so, previmageXY[1]+so, rad);
                        dc.fillCircle(nextimageXY[0]+so, nextimageXY[1]+so, rad);
                        dc.setColor(Graphics.COLOR_BLUE,-1);
                        dc.fillCircle(previmageXY[0], previmageXY[1], rad);
                        dc.fillCircle(nextimageXY[0], nextimageXY[1], rad);
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawText(previmageXY[0]-so, previmageXY[1]-so, Graphics.FONT_SMALL, "<", center);
                        dc.drawText(nextimageXY[0]-so, nextimageXY[1]-so, Graphics.FONT_SMALL, ">", center);
                        dc.setColor(Graphics.COLOR_BLACK,-1);
                        dc.drawText(previmageXY[0], previmageXY[1], Graphics.FONT_SMALL, "<", center);
                        dc.drawText(nextimageXY[0], nextimageXY[1], Graphics.FONT_SMALL, ">", center);
                        break;
                }

                // draw start button
                switch (theme) {
                    case 0:
                        dc.setColor(Graphics.COLOR_YELLOW,-1);
                        dc.drawText(newXY[0]+newWH[0]/2, newXY[1]+newWH[1]/2, Graphics.FONT_SMALL, "Start", center);
                        break;
                    case 1:
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawRoundedRectangle(newXY[0]+so, newXY[1]+so, newWH[0], newWH[1], rad);
                        dc.setColor(Graphics.COLOR_YELLOW,-1);
                        dc.drawRoundedRectangle(newXY[0], newXY[1], newWH[0], newWH[1], rad);
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawText(newXY[0]+newWH[0]/2+so, newXY[1]+newWH[1]/2+so, Graphics.FONT_SMALL, "Start", center);
                        dc.setColor(Graphics.COLOR_YELLOW,-1);
                        dc.drawText(newXY[0]+newWH[0]/2, newXY[1]+newWH[1]/2, Graphics.FONT_SMALL, "Start", center);
                        break;
                    case 2:
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.fillRoundedRectangle(newXY[0]+so, newXY[1]+so, newWH[0], newWH[1], rad);
                        dc.setColor(Graphics.COLOR_YELLOW,-1);
                        dc.fillRoundedRectangle(newXY[0], newXY[1], newWH[0], newWH[1], rad);
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawText(newXY[0]+newWH[0]/2-so, newXY[1]+newWH[1]/2-so, Graphics.FONT_SMALL, "Start", center);
                        dc.setColor(Graphics.COLOR_BLACK,-1);
                        dc.drawText(newXY[0]+newWH[0]/2, newXY[1]+newWH[1]/2, Graphics.FONT_SMALL, "Start", center);
                        break;
                }
                break;
            case 1:
                // draw show button
                if (showing) { tmp = "Back"; }
                else { tmp = "Show"; }
                switch (theme) {
                    case 0:
                        dc.setColor(Graphics.COLOR_BLUE,-1);
                        dc.drawText(showXY[0]+showWH[0]/2, showXY[1]+showWH[1]/2, Graphics.FONT_SMALL, tmp, center);
                        break;
                    case 1:
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawRoundedRectangle(showXY[0]+so, showXY[1]+so, showWH[0], showWH[1], rad);
                        dc.setColor(Graphics.COLOR_BLUE,-1);
                        dc.drawRoundedRectangle(showXY[0], showXY[1], showWH[0], showWH[1], rad);
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawText(showXY[0]+showWH[0]/2+so, showXY[1]+showWH[1]/2+so, Graphics.FONT_SMALL, tmp, center);
                        dc.setColor(Graphics.COLOR_BLUE,-1);
                        dc.drawText(showXY[0]+showWH[0]/2, showXY[1]+showWH[1]/2, Graphics.FONT_SMALL, tmp, center);
                        break;
                    case 2:
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.fillRoundedRectangle(showXY[0]+so, showXY[1]+so, showWH[0], showWH[1], rad);
                        dc.setColor(Graphics.COLOR_BLUE,-1);
                        dc.fillRoundedRectangle(showXY[0], showXY[1], showWH[0], showWH[1], rad);
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawText(showXY[0]+showWH[0]/2-so, showXY[1]+showWH[1]/2-so, Graphics.FONT_SMALL, tmp, center);
                        dc.setColor(Graphics.COLOR_BLACK,-1);
                        dc.drawText(showXY[0]+showWH[0]/2, showXY[1]+showWH[1]/2, Graphics.FONT_SMALL, tmp, center);
                        break;
                }

                // draw moves and average
                if (font != null) {
                    if (theme != 0) {
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawAngledText(previmageXY[0]+so, previmageXY[1]+so, font, moves+"", center, 90);
                    }
                    dc.setColor(Graphics.COLOR_GREEN,-1);
                    dc.drawAngledText(previmageXY[0], previmageXY[1], font, moves+"", center, 90);
                    if (stats != null) {
                        tmp = stats[rows-3];
                        if (tmp[0] > 0) {
                            average = (tmp[0]*1.0/tmp[1]).toNumber();
                            if (theme != 0) {
                                dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                                dc.drawAngledText(nextimageXY[0]+so, nextimageXY[1]+so, font, average+"", center, 270);
                            }
                            dc.setColor(Graphics.COLOR_YELLOW,-1);
                            dc.drawAngledText(nextimageXY[0], nextimageXY[1], font, average+"", center, 270);
                        }
                    }
                }

                // draw new button
                switch (theme) {
                    case 0:
                        dc.setColor(Graphics.COLOR_YELLOW,-1);
                        dc.drawText(newXY[0]+newWH[0]/2, newXY[1]+newWH[1]/2, Graphics.FONT_SMALL, "New", center);
                        break;
                    case 1:
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawRoundedRectangle(newXY[0]+so, newXY[1]+so, newWH[0], newWH[1], rad);
                        dc.setColor(Graphics.COLOR_YELLOW,-1);
                        dc.drawRoundedRectangle(newXY[0], newXY[1], newWH[0], newWH[1], rad);
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawText(newXY[0]+newWH[0]/2+so, newXY[1]+newWH[1]/2+so, Graphics.FONT_SMALL, "New", center);
                        dc.setColor(Graphics.COLOR_YELLOW,-1);
                        dc.drawText(newXY[0]+newWH[0]/2, newXY[1]+newWH[1]/2, Graphics.FONT_SMALL, "New", center);
                        break;
                    case 2:
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.fillRoundedRectangle(newXY[0]+so, newXY[1]+so, newWH[0], newWH[1], rad);
                        dc.setColor(Graphics.COLOR_YELLOW,-1);
                        dc.fillRoundedRectangle(newXY[0], newXY[1], newWH[0], newWH[1], rad);
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawText(newXY[0]+newWH[0]/2-so, newXY[1]+newWH[1]/2-so, Graphics.FONT_SMALL, "New", center);
                        dc.setColor(Graphics.COLOR_BLACK,-1);
                        dc.drawText(newXY[0]+newWH[0]/2, newXY[1]+newWH[1]/2, Graphics.FONT_SMALL, "New", center);
                        break;
                }
                break;
            case 2:
                // draw won text
                if (theme != 0) {
                    dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                    dc.drawText(dimXY[0]+so, dimXY[1]+so, Graphics.FONT_SMALL, "You won!", center);
                }
                dc.setColor(Graphics.COLOR_GREEN,-1);
                dc.drawText(dimXY[0], dimXY[1], Graphics.FONT_SMALL, "You won!", center);

                // draw moves and average
                if (font != null) {
                    if (theme != 0) {
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawAngledText(previmageXY[0]+so, previmageXY[1]+so, font, moves+"", center, 90);
                    }
                    dc.setColor(Graphics.COLOR_GREEN,-1);
                    dc.drawAngledText(previmageXY[0], previmageXY[1], font, moves+"", center, 90);
                    if (stats != null) {
                        tmp = stats[rows-3];
                        if (tmp[0] > 0) {
                            average = (tmp[0]*1.0/tmp[1]).toNumber();
                            if (theme != 0) {
                                dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                                dc.drawAngledText(nextimageXY[0]+so, nextimageXY[1]+so, font, average+"", center, 270);
                            }
                            dc.setColor(Graphics.COLOR_YELLOW,-1);
                            dc.drawAngledText(nextimageXY[0], nextimageXY[1], font, average+"", center, 270);
                        }
                    }
                }

                // draw new button
                switch (theme) {
                    case 0:
                        dc.setColor(Graphics.COLOR_YELLOW,-1);
                        dc.drawText(newXY[0]+newWH[0]/2, newXY[1]+newWH[1]/2, Graphics.FONT_SMALL, "New", center);
                        break;
                    case 1:
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawRoundedRectangle(newXY[0]+so, newXY[1]+so, newWH[0], newWH[1], rad);
                        dc.setColor(Graphics.COLOR_YELLOW,-1);
                        dc.drawRoundedRectangle(newXY[0], newXY[1], newWH[0], newWH[1], rad);
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawText(newXY[0]+newWH[0]/2+so, newXY[1]+newWH[1]/2+so, Graphics.FONT_SMALL, "New", center);
                        dc.setColor(Graphics.COLOR_YELLOW,-1);
                        dc.drawText(newXY[0]+newWH[0]/2, newXY[1]+newWH[1]/2, Graphics.FONT_SMALL, "New", center);
                        break;
                    case 2:
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.fillRoundedRectangle(newXY[0]+so, newXY[1]+so, newWH[0], newWH[1], rad);
                        dc.setColor(Graphics.COLOR_YELLOW,-1);
                        dc.fillRoundedRectangle(newXY[0], newXY[1], newWH[0], newWH[1], rad);
                        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                        dc.drawText(newXY[0]+newWH[0]/2-so, newXY[1]+newWH[1]/2-so, Graphics.FONT_SMALL, "New", center);
                        dc.setColor(Graphics.COLOR_BLACK,-1);
                        dc.drawText(newXY[0]+newWH[0]/2, newXY[1]+newWH[1]/2, Graphics.FONT_SMALL, "New", center);
                        break;
                }
                break;
        }


    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}

function newgame() as Void {
    state = 0;
    inittiles();
    game = {
        "ver" => 1,
        "state" => state,
        "image" => image,
        "rows" => rows,
        "cols" => cols,
        "tiles" => tiles,
        "solved" => solved,
        "moves" => 0
    };
    Storage.setValue("game",game);
}

function inittiles() {
    tiles = [];
    solved = [];
    for (var r=0;r<rows;r++) {
        tmp = [];
        tmp2 = [];
        for (var c=0;c<cols;c++) {
            tmp.add(r*cols+c+1);
            tmp2.add(r*cols+c+1);            
        }
        tiles.add(tmp);
        solved.add(tmp2);
    }
    tiles[rows-1][cols-1] = 0;
    solved[rows-1][cols-1] = 0;
}

// load image
function loadimage() as Void {
    rows = game.get("rows");
    cols = game.get("cols");
    image = game.get("image");
    var bm,bm2;
    var w1 = (square / rows).toNumber();
    var h1 = (square / cols).toNumber();
System.println("loadimage image = "+image);
    if (image == 0) {
        var font;
        switch (rows) {
            case 2:
            case 3:
                font = Graphics.FONT_LARGE;
                break;
            case 4:
                font = Graphics.FONT_MEDIUM;
                break;
            case 5:
                font = Graphics.FONT_SMALL;
                break;
            case 6:
            default:
                font = Graphics.FONT_TINY;
                break;
        }
        if (theme == 1) { tmp2 = (w1*.1).toNumber(); }
        else { tmp2 = (w1*.05).toNumber(); }
        for (var r=0;r<rows;r++) {
            for (var c=0;c<cols;c++) {
                tmp3 = r*cols+c+1;
                bm = Graphics.createBufferedBitmap({ :width => w1, :height => h1 }).get();
                tmp = bm.getDc();
                if (theme == 2) {
                    tmp.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_WHITE);
                    tmp.clear();
                    tmp.setColor(Graphics.COLOR_DK_GRAY,-1);
                    tmp.drawText(w1/2-so, h1/2-so, font, tmp3, center);
                    tmp.setColor(Graphics.COLOR_BLACK,-1);
                    tmp.drawText(w1/2, h1/2, font, tmp3, center);
                } else {
                    tmp.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
                    tmp.clear();
                    tmp.setPenWidth(tmp2);
                    tmp.setColor(Graphics.COLOR_WHITE,-1);
                    tmp.drawRectangle(1, 1, w1-2, h1-2);
                    tmp.drawText(w1/2, h1/2, font, tmp3, center);
                }
                if (tmp3 == rows*cols) { tmp3 = 0; }
                tileimages[tmp3] = bm;
            }
        }
    } else {
        bm2 = WatchUi.loadResource(images[image]);
        tmp2 = square / bmsize;        // scale factor for full image
        var transform = new Graphics.AffineTransform();
        transform.scale(tmp2,tmp2);
        var offX,offY;
        for (var r=0;r<rows;r++) {
            for (var c=0;c<cols;c++) {
                bm = Graphics.createBufferedBitmap({ :width => w1, :height => h1 }).get();
                tmp = bm.getDc();
                tmp3 = r*cols+c+1;
                offX = (c*w1).toNumber();
                offY = (r*h1).toNumber();
                tmp.drawBitmap2(-offX, -offY, bm2, {
                    :transform => transform
                });
                if (tmp3 == rows*cols) { tmp3 = 0; }
                tileimages[tmp3] = bm;
            }
        }
    }
}

// draw the tiles at x,y for w,h
function drawtiles(dc) as Void {
    rows = game.get("rows");
    cols = game.get("cols");
    state = game.get("state");
    tiles = game.get("tiles");
    solved = game.get("solved");
    var drawgrid = true;
    var drawblank = false;
    var showgood = false;
    switch (state) {
        case 0:
            drawgrid = true;
            drawblank = true;
            showgood = false;
            break;
        case 1:
            drawgrid = true;
            drawblank = false;
            showgood = showright;
            break;
        case 2:
            drawgrid = false;
            drawblank = true;
            showgood = false;
            break;
    }
    if (state == 1 and showing) {
        tiles = solved;
        showgood = false;
    }
    var w1 = (square / rows).toNumber();
    var h1 = (square / cols).toNumber();
    var bm;
    var tx = ((SW-square)/2).toNumber();
    var ty = ((SW-square)/2).toNumber();
    tileWH = [w1,h1];
    tileXY = [];
    for (var r=0;r<rows;r++) {
        for (var c=0;c<cols;c++) {
            tmp = (tx+c*h1).toNumber();
            tmp2 = (ty+r*w1).toNumber();
            tileXY.add([tmp,tmp2]);
            tmp3 = tiles[r][c];
            if (tmp3 != 0 or drawblank) {
                if (theme != 0) {
                    dc.setColor(Graphics.COLOR_DK_GRAY,-1);
                    dc.fillRectangle(tmp+so, tmp2+so, w1, h1);
                }
                dc.drawBitmap2(tmp,tmp2,tileimages[tmp3],{});
            }
        }
    }
    if (drawgrid) {
        dc.setPenWidth(1);
        for (var r=0;r<rows;r++) {
            for (var c=0;c<cols;c++) {
                tmp3 = r*cols+c;
                if (showgood and tiles[r][c] == solved[r][c] and tiles[r][c] != 0) { dc.setColor(Graphics.COLOR_GREEN,-1); }
                else { dc.setColor(Graphics.COLOR_BLACK,-1); }
                dc.drawRectangle(tileXY[tmp3][0],tileXY[tmp3][1],tileWH[0],tileWH[1]);
            }
        }
    }
}

// update game stats
// stats is a two-dimensional array
// the first dimension elements represent grid sizes of 3x3, 4x4, 5x5, and 6x6
// the second dimsnsion elements represent total moves and number of games
// you can divide moves by games to get average moves per game
function savestats() {
    tmp = game.get("rows")-3;
    moves = game.get("moves");
    stats = Storage.getValue("stats");
    if (stats == null) {
        stats = [[0,0],[0,0],[0,0],[0,0]];
    }
    stats[tmp][0] += moves;
    stats[tmp][1]++;
    Storage.setValue("stats",stats);
}

function showstats() {
    stats = Storage.getValue("stats");
    if (stats == null) { return; }
    var menu = new WatchUi.CustomMenu(45, Graphics.COLOR_BLACK,{
        :title => new $.DrawableMenuTitle(),
        :titleItemHeight => 70
    });
    menu.addItem(new $.CustomItem(0,"Grid",0,0));
    var labels = ["3x3","4x4","5x5","6x6"];
    for (var i=0;i<stats.size();i++) {
        menu.addItem(new $.CustomItem(i+1,labels[i],stats[i][0],stats[i][1]));
    }
    WatchUi.pushView(menu, new $.TileSliderStatsDelegate(), WatchUi.SLIDE_UP);
    WatchUi.requestUpdate();
}


class TileSliderSettings extends WatchUi.Menu2 {
    public function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("Settings");

        var themeicon = new $.CustomIcon(theme);
        var hinticon = new $.CustomIcon(hint);
        var statsicon = new $.CustomIcon(0);

        Menu2.addItem(new WatchUi.IconMenuItem("Theme", themes[theme], "theme", themeicon, null));
        Menu2.addItem(new WatchUi.IconMenuItem("Hints", hints[hint], "hint", hinticon, null));
        Menu2.addItem(new WatchUi.IconMenuItem("Stats", "Show statistics", "stats", statsicon, null));
    }
}

class CustomIcon extends WatchUi.Drawable {
    private var _index as Number;

    public function initialize(index as Number) {
        _index = index;
        Drawable.initialize({});
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(-1,-1);
        dc.clear();
    }
}

class TileSliderStatsDelegate extends WatchUi.Menu2InputDelegate {
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) {
        return;
    }

    public function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class DrawableMenuTitle extends WatchUi.Drawable {
    public function initialize() {
        Drawable.initialize({});
    }
    
    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(dc.getWidth()/2,(dc.getHeight()*.7).toNumber(),Graphics.FONT_SMALL,"Statistics",center);
        dc.setPenWidth(3);
        dc.drawLine(0,dc.getHeight(),dc.getWidth(),dc.getHeight());
    }
}

class CustomItem extends WatchUi.CustomMenuItem {
    private var _id as Number;
    private var _label as String;
    private var _moves as Number;
    private var _games as Number;

    public function initialize(id as Number, label as String, moves as Number, games as Number) {
        CustomMenuItem.initialize(id, {});
        _id = id;
        _label = label;
        _moves = moves;
        _games = games;
    }

    public function draw(dc as Dc) as Void {
        // Fill background horizontally based on percentage
        var w = dc.getWidth();
        var h = dc.getHeight();
        var bx = w/8;
        var bw = w*6/8;
        var lx = bx;
        var gx = (w*.6).toNumber();
        var ax = bx+bw;
        var avg = 0;
        var g = _games;
        if (_id == 0) {
            g = "Games";
            avg = "Avg";
        } else {
            if (g > 0) { avg = (_moves*1.0/_games).toNumber(); }
        }
        dc.setColor(Graphics.COLOR_BLUE,-1);
        dc.drawText(lx,h/2,Graphics.FONT_TINY,_label,Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE,-1);
        dc.drawText(gx,h/2,Graphics.FONT_TINY,g,Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_YELLOW,-1);
        dc.drawText(ax,h/2,Graphics.FONT_TINY,avg,Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
