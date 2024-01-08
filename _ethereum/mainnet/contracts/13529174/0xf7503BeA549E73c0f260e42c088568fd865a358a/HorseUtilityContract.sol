pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

//
//   ____ _           _                _   _   _                       _   _ _____ _____
//  / ___| |__   __ _(_)_ __   ___  __| | | | | | ___  _ __ ___  ___  | \ | |  ___|_   _|
// | |   | '_ \ / _` | | '_ \ / _ \/ _` | | |_| |/ _ \| '__/ __|/ _ \ |  \| | |_    | |
// | |___| | | | (_| | | | | |  __/ (_| | |  _  | (_) | |  \__ \  __/ | |\  |  _|   | |
//  \____|_| |_|\__,_|_|_| |_|\___|\__,_| |_| |_|\___/|_|  |___/\___| |_| \_|_|     |_|
//
//
//
//                                                 ,,  //
//                                              .//,,,,,,,,,
//                                              .//,,,,@@,,,,,,,
//                                            /////,,,,,,,,,,,,,
//                                            /////,,,,,,
//                                            /////,,,,,,
//                                          ///////,,,,,,
//                                      ///////////,,,,,,
//                        /////,,,,,,,,,,,,,,,,,,,,,,,,,,
//                      /////,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                      /////,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                      /////,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                    ////   ,,  //                ,,  //
//                    ////   ,,  //                ,,  //
//                    ////   ,,  //                ,,  //
//                    //     ,,  //                ,,  //
//                           @@  @@                @@  @@
//
// ** ChainedHorseNFT: HorseUtilityContract.sol **
// Written and developed by: Moonfarm
// Twitter: @spacesh1pdev
// Discord: Moonfarm#1138
//

contract HorseUtilityContract {
    //SVG-parts
    string constant svgStart =
        "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 32 32'>";
    string constant svgEnd = "</svg>";
    string constant base =
        "<path fill='url(#body-color)' d='M19 7h1v1h-1zm2 0h1v1h-1zm-2 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm-1 0h1v1H9zm0 1h1v1H9zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1H9zm0-1h1v1H9zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-3 3h1v1H9zm0 1h1v1H9zm0 1h1v1H9zm0 1h1v1H9zm2 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm8 0h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm2 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1z' /><path fill='#000' opacity='.35' d='M21 7h1v1h-1zm0 14h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm-10 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1z' /><path fill='url(#hoof-color)' d='M9 25h1v1H9zm2 0h1v1h-1zm8 0h1v1h-1zm2 0h1v1h-1z' /><path fill='#000' d='M21 10h1v1h-1z' />";

    // attribute svgs
    string[] private maneColorSvgs = [
        "#000",
        "#da5d97",
        "#806bd5",
        "#b05ecd",
        "#f25a5f",
        "#ff8c2f",
        "#fff",
        "#00b7e6",
        "#3fa966",
        "#3d6ccd",
        "#ebbd54"
    ];
    string[] private patternColorSvgs = [
        "#643323",
        "#333",
        "#72d2ff",
        "#f1c5d1",
        "#dad4f7",
        "#6ecb63",
        "#da3832",
        "#fffac8",
        "#df6436",
        "#50b7e6",
        "#ff0075",
        "#fff"
    ];
    string[] private hoofColorSvgs = [
        "#000",
        "#544116",
        "#22577a",
        "#7e5b24",
        "#004927",
        "#008762",
        "#d53832",
        "#b0c7e6",
        "#76267b",
        "#e6adb0",
        "#ebbd54"
    ];
    string[] private bodyColorSvgs = [
        "#dfc969",
        "#685991",
        "#6d6e71",
        "#845f36",
        "#fff",
        "#6ecb63",
        "#b4255b",
        "#418151",
        "#007791",
        "#ebbd54"
    ];
    string[] private headAccessorySvgs = [
        "",
        "<path fill='#912b61' d='M19 8h1v1h-1zM19 7h1v1h-1zM20 7h1v1h-1zM21 7h1v1h-1zM21 8h1v1h-1zM20 8h1v1h-1zM22 8h1v1h-1zM23 8h1v1h-1zM24 8h1v1h-1zM22 7h1v1h-1z' />",
        "<path fill='#da3832' d='M19 8h1v1h-1zM19 7h1v1h-1zM20 7h1v1h-1z' /><path fill='#fae84b' d='M20 8h1v1h-1zM21 8h1v1h-1zM21 7h1v1h-1z' /><path fill='#4a549f' d='M22 7h1v1h-1zM22 8h1v1h-1z' /><path fill='#119b55' d='M23 8h1v1h-1zM24 8h1v1h-1z' /><path fill='#3e4e9c' d='M21 6h1v1h-1zM21 5h1v1h-1zM20 5h1v1h-1zM22 5h1v1h-1z' />",
        "<path fill='#ebbd54' d='M18 15h1v1h-1zM18 16h1v1h-1zM19 17h1v1h-1zM20 18h1v1h-1zM21 18h1v1h-1zM22 18h1v1h-1zM22 19h1v1h-1zM21 19h1v1h-1z' />",
        "<path fill='#1fafff' d='M22 9h1v1h-1zM22 8h1v1h-1zM23 8h1v1h-1zM23 7h1v1h-1zM24 7h1v1h-1zM24 6h1v1h-1zM24 5h1v1h-1z' />",
        "<path fill='#ebbc53' d='M26 10h1v1h-1zM25 11h1v1h-1zM27 10h1v1h-1zM27 12h1v1h-1zM28 12h1v1h-1zM28 11h1v1h-1zM29 12h1v1h-1zM29 11h1v1h-1zM30 11h1v1h-1z' /><path fill='#d53931' d='M27 11h1v1h-1zM26 11h1v1h-1z' /><path fill='#ebbc53' d='M28 10h1v1h-1z' />",
        "<path fill='#000' d='M18 8h1v1h-1zM19 8h1v1h-1zM19 7h1v1h-1zM19 6h1v1h-1zM20 6h1v1h-1zM20 7h1v1h-1zM19 5h1v1h-1zM20 5h1v1h-1zM21 5h1v1h-1zM22 5h1v1h-1zM20 8h1v1h-1zM21 8h1v1h-1zM21 7h1v1h-1zM21 6h1v1h-1zM22 8h1v1h-1zM22 7h1v1h-1zM22 6h1v1h-1zM23 8h1v1h-1z' />",
        "<path fill='#af3034' d='M19 9h1v1h-1zM19 8h1v1h-1zM19 7h1v1h-1zM19 6h1v1h-1z' /><path fill='#7c231f' d='M21 8h1v1h-1zM21 7h1v1h-1zM21 6h1v1h-1z' />",
        "<path fill='#2d388b' d='M17 9h1v1h-1zM17 8h1v1h-1zM18 9h1v1h-1z' /><path fill='#ebbd54' d='M19 7h1v1h-1z' /><path fill='#2d388b' d='M19 6h1v1h-1zM19 5h1v1h-1zM19 4h1v1h-1zM18 4h1v1h-1zM17 4h1v1h-1zM17 5h1v1h-1zM20 5h1v1h-1zM21 6h1v1h-1zM20 6h1v1h-1zM20 7h1v1h-1zM21 7h1v1h-1z' /><path fill='#ebbd54' d='M21 8h1v1h-1z' /><path fill='#2d388b' d='M22 8h1v1h-1zM22 7h1v1h-1zM24 7h1v1h-1zM23 8h1v1h-1zM20 8h1v1h-1zM19 9h1v1h-1zM19 8h1v1h-1z' />",
        "<path fill='#e65157' d='M21 10h1v1h-1zM22 10h1v1h-1zM23 10h1v1h-1zM24 10h1v1h-1zM25 10h1v1h-1zM26 10h1v1h-1zM27 10h1v1h-1zM28 10h1v1h-1zM29 10h1v1h-1zM30 10h1v1h-1zM31 10h1v1h-1z' />",
        "<path fill='#7f5748' d='M19 9h1v1h-1zM19 8h1v1h-1zM20 7h1v1h-1z' /><path fill='#b2b6ba' d='M20 8h1v1h-1z' /><path fill='#7f5748' d='M20 9h1v1h-1zM21 9h1v1h-1zM21 8h1v1h-1z' /><path fill='#b2b6ba' d='M19 7h1v1h-1zM19 6h1v1h-1zM19 5h1v1h-1z' /><path fill='#8e959c' d='M22 6h1v1h-1zM22 5h1v1h-1z' /><path fill='#7f5748' d='M21 7h1v1h-1zM22 7h1v1h-1zM22 8h1v1h-1zM22 9h1v1h-1zM23 8h1v1h-1zM23 9h1v1h-1z' />",
        "<path fill='#ebbd54' d='M18 4h1v1h-1zM19 5h1v1h-1zM20 5h1v1h-1zM21 5h1v1h-1zM22 5h1v1h-1zM23 4h1v1h-1zM22 3h1v1h-1zM21 3h1v1h-1zM20 3h1v1h-1zM19 3h1v1h-1z' />",
        "<path fill='#86c661' d='M25 14h1v1h-1zm0 1h1v1h-1z' /><path fill='#04b3e9' d='M25 16h1v1h-1z' /><path fill='#86c661' d='M25 19h1v1h-1zm0-1h1v1h-1z' /><path fill='#04b3e9' d='M25 21h1v1h-1z' /><path fill='#fbee41' d='M24 12h1v1h-1zm0 2h1v1h-1z' /><path fill='#f58220' d='M24 13h1v1h-1z' /><path fill='#fbee41' d='M24 16h1v1h-1zm0 2h1v1h-1zm0-3h1v1h-1z' /><path fill='#ef4354' d='M23 12h1v1h-1z' /><path fill='#f58220' d='M23 16h1v1h-1z' /><path fill='#ef4354' d='M23 15h1v1h-1zm0 2h1v1h-1zm0 2h1v1h-1zm0-6h1v1h-1z' />",
        "<path fill='#ebbd54' d='M19 9h1v1h-1zM19 8h1v1h-1zM19 7h1v1h-1zM19 6h1v1h-1zM20 7h1v1h-1zM20 8h1v1h-1zM20 9h1v1h-1zM21 9h1v1h-1zM21 8h1v1h-1zM21 7h1v1h-1zM21 6h1v1h-1zM22 7h1v1h-1zM22 8h1v1h-1zM22 9h1v1h-1zM23 6h1v1h-1zM23 7h1v1h-1zM23 8h1v1h-1zM23 9h1v1h-1z' />"
    ];
    string[] private bodyAccessorySvgs = [
        "",
        "<path fill='#898989' d='M12 16h1v1h-1zM12 17h1v1h-1zM12 18h1v1h-1zM12 19h1v1h-1zM12 20h1v1h-1zM17 20h1v1h-1zM17 19h1v1h-1zM17 18h1v1h-1zM17 17h1v1h-1z' /><path fill='#221f20' d='M14 17h1v1h-1z' /><path fill='#fff' d='M14 16h1v1h-1zM15 16h1v1h-1zM16 16h1v1h-1zM16 17h1v1h-1zM16 18h1v1h-1zM16 19h1v1h-1zM16 20h1v1h-1zM14 20h1v1h-1zM14 19h1v1h-1zM14 18h1v1h-1zM13 18h1v1h-1zM13 17h1v1h-1zM13 16h1v1h-1zM13 19h1v1h-1zM13 20h1v1h-1z' /><path fill='#221f20' d='M15 17h1v1h-1zM15 18h1v1h-1zM15 19h1v1h-1zM15 20h1v1h-1z' /><path fill='#898989' d='M17 16h1v1h-1z' />",
        "<path fill='#af7139' d='M9 23h1v1H9zM9 24h1v1H9zM9 25h1v1H9zM10 25h1v1h-1z' /><path fill='#643323' d='M11 23h1v1h-1zM11 24h1v1h-1zM11 25h1v1h-1zM12 25h1v1h-1z' /><path fill='#af7139' d='M19 23h1v1h-1zM19 24h1v1h-1zM19 25h1v1h-1zM20 25h1v1h-1z' /><path fill='#643323' d='M21 23h1v1h-1zM21 24h1v1h-1zM21 25h1v1h-1zM22 25h1v1h-1z' />",
        "<path fill='#ff8c2f' d='M15 16h1v1h-1z' /><path fill='#e65157' d='M15 15h1v1h-1z' /><path fill='#ff8c2f' d='M14 15h1v1h-1z' /><path fill='#fff560' d='M14 16h1v1h-1z' /><path fill='#94ce6e' d='M13 16h1v1h-1z' /><path fill='#fff560' d='M13 15h1v1h-1z' /><path fill='#94ce6e' d='M12 15h1v1h-1z' /><path fill='#1db1e3' d='M12 16h1v1h-1zM11 15h1v1h-1z' /><path fill='#e65157' d='M14 14h1v1h-1z' /><path fill='#ff8c2f' d='M13 14h1v1h-1z' /><path fill='#fff560' d='M12 14h1v1h-1z' /><path fill='#94ce6e' d='M11 14h1v1h-1z' /><path fill='#1db1e3' d='M10 14h1v1h-1z' /><path fill='#e65157' d='M12 13h1v1h-1z' /><path fill='#ff8c2f' d='M11 13h1v1h-1z' /><path fill='#fff560' d='M10 13h1v1h-1z' /><path fill='#94ce6e' d='M9 13h1v1H9z' /><path fill='#1db1e3' d='M8 13h1v1H8z' /><path fill='#e65157' d='M10 12h1v1h-1z' /><path fill='#ff8c2f' d='M9 12h1v1H9z' /><path fill='#fff560' d='M8 12h1v1H8z' /><path fill='#94ce6e' d='M7 12h1v1H7z' /><path fill='#1db1e3' d='M6 12h1v1H6z' /><path fill='#e65157' d='M8 11h1v1H8z' /><path fill='#ff8c2f' d='M7 11h1v1H7z' /><path fill='#fff560' d='M6 11h1v1H6z' /><path fill='#94ce6e' d='M5 11h1v1H5z' /><path fill='#1db1e3' d='M4 11h1v1H4z' /><path fill='#e65157' d='M5 10h1v1H5z' /><path fill='#ff8c2f' d='M4 10h1v1H4z' /><path fill='#fff560' d='M3 10h1v1H3z' /><path fill='#94ce6e' d='M2 10h1v1H2z' /><path fill='#1db1e3' d='M1 10h1v1H1z' /><path fill='#e65157' d='M2 9h1v1H2z' /><path fill='#ff8c2f' d='M1 9h1v1H1z' /><path fill='#fff560' d='M0 9h1v1H0z' />",
        "<path fill='#fdef38' d='M14 12h1v1h-1zM13 12h1v1h-1zM12 11h1v1h-1zM9 13h1v1H9zM9 14h1v1H9zM10 15h1v1h-1zM13 17h1v1h-1zM13 18h1v1h-1zM14 19h1v1h-1zM14 20h1v1h-1zM15 21h1v1h-1zM23 18h1v1h-1zM23 17h1v1h-1zM22 16h1v1h-1zM23 24h1v1h-1zM24 24h1v1h-1zM25 23h1v1h-1zM26 23h1v1h-1zM25 14h1v1h-1zM24 13h1v1h-1zM13 23h1v1h-1zM14 24h1v1h-1zM15 24h1v1h-1zM19 17h1v1h-1zM19 16h1v1h-1zM19 15h1v1h-1zM18 14h1v1h-1zM18 13h1v1h-1z' />",
        "<path fill='#4487ab' d='M15 16h1v1h-1z' /><path fill='#addbfb' d='M14 16h1v1h-1zM14 14h1v1h-1z' /><path fill='#4487ab' d='M15 14h1v1h-1zM15 13h1v1h-1zM14 13h1v1h-1zM13 14h1v1h-1z' /><path fill='#addbfb' d='M13 13h1v1h-1z' /><path fill='#4487ab' d='M12 13h1v1h-1z' /><path fill='#addbfb' d='M12 14h1v1h-1zM11 13h1v1h-1zM11 12h1v1h-1zM10 13h1v1h-1zM9 12h1v1H9zM8 11h1v1H8z' /><path fill='#4487ab' d='M8 10h1v1H8zM9 13h1v1H9z' /><path fill='#addbfb' d='M9 11h1v1H9zM10 12h1v1h-1z' /><path fill='#4487ab' d='M14 12h1v1h-1zM13 12h1v1h-1z' /><path fill='#addbfb' d='M12 12h1v1h-1z' /><path fill='#4487ab' d='M12 11h1v1h-1zM11 11h1v1h-1zM10 11h1v1h-1z' /><path fill='#addbfb' d='M11 14h1v1h-1zM10 14h1v1h-1z' /><path fill='#4487ab' d='M15 15h1v1h-1z' /><path fill='#addbfb' d='M14 15h1v1h-1zM13 15h1v1h-1zM12 15h1v1h-1z' /><path fill='#4487ab' d='M9 10h1v1H9z' />",
        "<path fill='#afadb0' d='M14 15h1v1h-1zM15 15h1v1h-1zM15 14h1v1h-1zM14 14h1v1h-1zM14 13h1v1h-1zM15 13h1v1h-1zM16 13h1v1h-1zM16 14h1v1h-1zM14 12h1v1h-1zM13 12h1v1h-1zM13 13h1v1h-1zM13 14h1v1h-1zM12 14h1v1h-1zM12 13h1v1h-1zM12 12h1v1h-1zM11 12h1v1h-1zM11 13h1v1h-1zM11 14h1v1h-1z' /><path fill='#f25a5f' d='M10 13h1v1h-1z' /><path fill='#f3cb4e' d='M10 12h1v1h-1zM9 12h1v1H9z' /><path fill='#f25a5f' d='M9 13h1v1H9z' /><path fill='#f3cb4e' d='M8 13h1v1H8zM8 12h1v1H8zM7 12h1v1H7zM7 13h1v1H7zM6 13h1v1H6zM10 14h1v1h-1zM9 14h1v1H9zM8 14h1v1H8z' />",
        "<path d='M14 15h1v1h-1zM14 14h1v1h-1zM13 14h1v1h-1zM13 15h1v1h-1zM12 15h1v1h-1zM12 14h1v1h-1zM11 14h1v1h-1zM11 15h1v1h-1zM11 16h1v1h-1zM11 17h1v1h-1zM11 18h1v1h-1zM14 13h1v1h-1zM14 12h1v1h-1zM13 12h1v1h-1zM13 13h1v1h-1zM12 13h1v1h-1zM13 11h1v1h-1zM13 10h1v1h-1zM14 10h1v1h-1zM14 11h1v1h-1zM13 9h1v1h-1zM15 11h1v1h-1zM15 10h1v1h-1z' /><path fill='#f8e100' d='M14 10h1v1h-1z' />",
        "<path fill='#221f20' d='M15 16h1v1h-1z' /><path fill='#5d5e60' d='M14 16h1v1h-1zM14 14h1v1h-1z' /><path fill='#221f20' d='M15 14h1v1h-1zM15 13h1v1h-1zM14 13h1v1h-1zM13 14h1v1h-1z' /><path fill='#5d5e60' d='M13 13h1v1h-1z' /><path fill='#221f20' d='M12 13h1v1h-1z' /><path fill='#5d5e60' d='M12 14h1v1h-1zM11 13h1v1h-1zM11 12h1v1h-1zM10 13h1v1h-1zM9 12h1v1H9zM8 11h1v1H8z' /><path fill='#221f20' d='M8 10h1v1H8zM9 13h1v1H9z' /><path fill='#5d5e60' d='M9 11h1v1H9zM10 12h1v1h-1z' /><path fill='#221f20' d='M14 12h1v1h-1zM13 12h1v1h-1z' /><path fill='#5d5e60' d='M12 12h1v1h-1z' /><path fill='#221f20' d='M12 11h1v1h-1zM11 11h1v1h-1zM10 11h1v1h-1z' /><path fill='#5d5e60' d='M11 14h1v1h-1zM10 14h1v1h-1z' /><path fill='#221f20' d='M15 15h1v1h-1z' /><path fill='#5d5e60' d='M14 15h1v1h-1zM13 15h1v1h-1zM12 15h1v1h-1z' /><path fill='#221f20' d='M9 10h1v1H9z' />"
    ];
    string[] private patternSvgs = [
        "<path fill='url(#pattern-color)' d='M19 7h1v1h-1zM21 7h1v1h-1zM23 10h1v1h-1zM24 10h1v1h-1zM19 12h1v1h-1zM19 13h1v1h-1zM21 14h1v1h-1zM21 15h1v1h-1zM19 17h1v1h-1zM20 18h1v1h-1zM16 18h1v1h-1zM16 17h1v1h-1zM14 16h1v1h-1zM13 17h1v1h-1zM14 20h1v1h-1zM13 20h1v1h-1zM18 20h1v1h-1zM19 21h1v1h-1zM21 24h1v1h-1zM21 23h1v1h-1zM9 20h1v1H9zM9 21h1v1H9zM11 16h1v1h-1zM11 17h1v1h-1z' />",
        "<path fill='url(#pattern-color)' d='M19 14h1v1h-1zM21 17h1v1h-1zM18 19h1v1h-1zM20 20h1v1h-1zM14 16h1v1h-1zM12 19h1v1h-1zM11 17h1v1h-1zM16 20h1v1h-1zM9 23h1v1H9z' />",
        "<path fill='url(#pattern-color)' d='M16 16h1v1h-1zM15 17h1v1h-1zM16 17h1v1h-1zM16 18h1v1h-1zM16 19h1v1h-1zM17 19h1v1h-1zM17 20h1v1h-1zM15 18h1v1h-1zM15 19h1v1h-1zM16 20h1v1h-1zM15 20h1v1h-1zM14 20h1v1h-1zM13 20h1v1h-1zM12 20h1v1h-1zM11 20h1v1h-1zM11 21h1v1h-1zM11 22h1v1h-1zM11 23h1v1h-1zM11 24h1v1h-1zM9 24h1v1H9zM9 23h1v1H9zM9 22h1v1H9zM9 21h1v1H9zM9 20h1v1H9zM10 20h1v1h-1zM10 19h1v1h-1zM9 19h1v1H9zM9 18h1v1H9zM9 17h1v1H9zM10 17h1v1h-1zM10 16h1v1h-1zM11 16h1v1h-1zM12 16h1v1h-1zM13 16h1v1h-1zM14 16h1v1h-1zM15 16h1v1h-1zM14 17h1v1h-1zM14 18h1v1h-1zM14 19h1v1h-1zM13 19h1v1h-1zM13 18h1v1h-1zM13 17h1v1h-1zM12 17h1v1h-1zM12 18h1v1h-1zM12 19h1v1h-1zM11 19h1v1h-1zM11 18h1v1h-1zM11 17h1v1h-1zM10 18h1v1h-1z' />",
        "<path fill='url(#pattern-color)' d='M24 10h1v1h-1zM19 7h1v1h-1zM21 7h1v1h-1z' />",
        "<path fill='url(#pattern-color)' d='M9 19h1v1H9zM10 19h1v1h-1zM11 18h1v1h-1zM12 18h1v1h-1zM13 17h1v1h-1zM14 17h1v1h-1zM15 17h1v1h-1zM16 18h1v1h-1zM17 18h1v1h-1zM18 18h1v1h-1zM19 19h1v1h-1zM20 19h1v1h-1zM21 18h1v1h-1zM19 12h1v1h-1zM20 13h1v1h-1zM21 14h1v1h-1zM21 15h1v1h-1zM17 20h1v1h-1zM16 20h1v1h-1zM15 20h1v1h-1zM9 22h1v1H9zM9 23h1v1H9zM9 24h1v1H9z' />",
        "<path fill='url(#pattern-color)' d='M12 16h1v1h-1zM11 17h1v1h-1zM10 18h1v1h-1zM9 19h1v1H9zM9 23h1v1H9zM12 20h1v1h-1zM13 19h1v1h-1zM14 18h1v1h-1zM15 17h1v1h-1zM15 16h1v1h-1zM18 16h1v1h-1zM18 17h1v1h-1zM18 18h1v1h-1zM18 19h1v1h-1zM17 20h1v1h-1zM21 17h1v1h-1zM20 16h1v1h-1zM20 15h1v1h-1zM19 14h1v1h-1zM19 11h1v1h-1zM20 12h1v1h-1zM21 13h1v1h-1zM19 22h1v1h-1zM21 24h1v1h-1zM11 22h1v1h-1z'/>",
        "<path fill='url(#pattern-color)' d='M9 18h1v1H9zM10 17h1v1h-1zM11 18h1v1h-1zM12 17h1v1h-1zM13 18h1v1h-1zM14 17h1v1h-1zM15 18h1v1h-1zM16 17h1v1h-1zM17 18h1v1h-1zM18 17h1v1h-1zM19 18h1v1h-1zM20 17h1v1h-1zM21 18h1v1h-1zM10 19h1v1h-1zM9 20h1v1H9zM11 20h1v1h-1zM12 19h1v1h-1zM13 20h1v1h-1zM14 19h1v1h-1zM15 20h1v1h-1zM16 19h1v1h-1zM17 20h1v1h-1zM18 19h1v1h-1zM19 20h1v1h-1zM20 19h1v1h-1zM21 20h1v1h-1zM21 16h1v1h-1zM19 16h1v1h-1zM20 15h1v1h-1zM19 14h1v1h-1zM20 13h1v1h-1zM19 12h1v1h-1zM19 22h1v1h-1zM19 24h1v1h-1zM9 22h1v1H9zM9 24h1v1H9zM11 24h1v1h-1zM11 22h1v1h-1zM21 22h1v1h-1zM21 24h1v1h-1z' />",
        "<path fill='url(#pattern-color)' d='M12 17h1v1h-1zM12 18h1v1h-1zM11 18h1v1h-1zM11 19h1v1h-1zM12 19h1v1h-1zM12 20h1v1h-1zM13 20h1v1h-1zM13 19h1v1h-1zM14 19h1v1h-1zM15 19h1v1h-1zM15 18h1v1h-1zM14 18h1v1h-1zM13 18h1v1h-1zM13 17h1v1h-1zM16 16h1v1h-1zM17 16h1v1h-1zM18 16h1v1h-1zM18 17h1v1h-1zM17 17h1v1h-1zM19 17h1v1h-1zM21 12h1v1h-1zM21 13h1v1h-1zM21 14h1v1h-1zM20 14h1v1h-1zM20 13h1v1h-1zM21 19h1v1h-1zM20 19h1v1h-1zM20 20h1v1h-1zM21 20h1v1h-1zM19 21h1v1h-1zM19 22h1v1h-1zM19 20h1v1h-1z'/>",
        "",
        "<path fill='url(#pattern-color)' d='M21 9h1v1h-1zM20 9h1v1h-1zM20 10h1v1h-1zM20 11h1v1h-1zM21 11h1v1h-1z' /><path fill='#fff' d='M21 10h1v1h-1z' /><path fill='url(#pattern-color)'  d='M22 11h1v1h-1zM22 10h1v1h-1zM22 9h1v1h-1zM23 10h1v1h-1zM23 11h1v1h-1zM24 10h1v1h-1zM24 11h1v1h-1zM20 13h1v1h-1zM20 14h1v1h-1zM20 15h1v1h-1zM20 16h1v1h-1zM19 16h1v1h-1zM18 16h1v1h-1zM17 16h1v1h-1zM16 16h1v1h-1zM15 16h1v1h-1zM14 16h1v1h-1zM13 16h1v1h-1zM12 16h1v1h-1zM11 16h1v1h-1zM10 16h1v1h-1zM11 17h1v1h-1zM10 18h1v1h-1zM10 19h1v1h-1zM14 17h1v1h-1zM13 18h1v1h-1zM13 19h1v1h-1zM17 17h1v1h-1zM16 18h1v1h-1zM16 19h1v1h-1zM19 17h1v1h-1zM19 18h1v1h-1zM19 19h1v1h-1z' />"
    ];
    string[] private tailSvgs = [
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM9 17H8v-1h1zM8 18H7v-1h1zM9 18H8v-1h1zM9 19H8v-1h1zM8 19H7v-1h1zM8 20H7v-1h1zM9 20H8v-1h1zM9 21H8v-1h1zM8 21H7v-1h1zM8 22H7v-1h1zM7 22H6v-1h1zM8 23H7v-1h1zM7 23H6v-1h1zM7 24H6v-1h1zM8 24H7v-1h1zM7 25H6v-1h1z' />",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM9 17H8v-1h1zM9 18H8v-1h1zM8 18H7v-1h1zM8 19H7v-1h1zM8 20H7v-1h1zM8 21H7v-1h1zM9 21H8v-1h1zM9 20H8v-1h1zM9 19H8v-1h1zM8 22H7v-1h1zM7 22H6v-1h1zM7 21H6v-1h1zM6 21H5v-1h1zM6 20H5v-1h1z' />",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM10 16H9v-1h1zM10 15H9v-1h1z'/>",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM9 17H8v-1h1zM8 18H7v-1h1zM9 18H8v-1h1zM9 19H8v-1h1zM8 19H7v-1h1zM8 20H7v-1h1zM9 20H8v-1h1zM9 21H8v-1h1zM8 21H7v-1h1zM8 22H7v-1h1zM7 22H6v-1h1zM8 23H7v-1h1zM7 23H6v-1h1zM7 24H6v-1h1zM8 24H7v-1h1zM7 25H6v-1h1zM7 26H6v-1h1zM6 26H5v-1h1zM5 26H4v-1h1zM4 26H3v-1h1zM3 26H2v-1h1zM6 25H5v-1h1zM6 24H5v-1h1zM5 25H4v-1h1zM2 26H1v-1h1zM1 26H0v-1h1zM4 25H3v-1h1z' />",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1z' />",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM9 17H8v-1h1zM9 18H8v-1h1zM9 20H8v-1h1zM9 21H8v-1h1z' />",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM9 17H8v-1h1zM9 18H8v-1h1zM9 20H8v-1h1zM9 21H8v-1h1z' />",
        "<path fill='url(#mane-color)' d='M10 17H9v-1h1zM9 18H8v-1h1zM9 17H8v-1h1zM8 18H7v-1h1zM9 19H8v-1h1zM9 20H8v-1h1zM9 21H8v-1h1zM9 22H8v-1h1zM8 20H7v-1h1zM8 22H7v-1h1zM9 23H8v-1h1zM9 24H8v-1h1z'/>"
    ];

    string[] private maneSvgs = [
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zm-2 1h-1V9h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm2-1h-1v-1h1zm1 0h-1v-1h1zm0-1h-1v-1h1zm0-1h-1v-1h1zm0-1h-1v-1h1zm4-3h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM21 10h-1V9h1zM19 10h-1V9h1zM19 11h-1v-1h1zM19 12h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM19 15h-1v-1h1zM19 16h-1v-1h1zM18 16h-1v-1h1zM17 16h-1v-1h1zM16 16h-1v-1h1zM16 17h-1v-1h1zM15 17h-1v-1h1zM14 17h-1v-1h1zM14 18h-1v-1h1zM15 18h-1v-1h1zM15 19h-1v-1h1zM14 19h-1v-1h1zM14 20h-1v-1h1zM14 21h-1v-1h1zM13 20h-1v-1h1zM13 21h-1v-1h1zM13 22h-1v-1h1zM13 23h-1v-1h1zM15 16h-1v-1h1zM17 15h-1v-1h1zM18 15h-1v-1h1zM18 14h-1v-1h1zM18 13h-1v-1h1zM18 12h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM19 10h-1V9h1zM19 11h-1v-1h1zM19 12h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM19 15h-1v-1h1zM19 16h-1v-1h1zM18 16h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM19 10h-1V9h1zM19 11h-1v-1h1zM19 12h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM19 15h-1v-1h1zM19 16h-1v-1h1zM18 16h-1v-1h1zM17 16h-1v-1h1zM17 17h-1v-1h1zM16 17h-1v-1h1zM16 18h-1v-1h1zM16 19h-1v-1h1zM15 18h-1v-1h1zM15 19h-1v-1h1zM15 20h-1v-1h1zM15 21h-1v-1h1zM15 22h-1v-1h1zM15 23h-1v-1h1zM15 24h-1v-1h1zM16 16h-1v-1h1zM15 16h-1v-1h1zM15 17h-1v-1h1zM14 17h-1v-1h1zM14 18h-1v-1h1zM14 19h-1v-1h1zM14 20h-1v-1h1zM14 21h-1v-1h1zM14 22h-1v-1h1zM14 23h-1v-1h1zM17 15h-1v-1h1zM18 15h-1v-1h1zM18 14h-1v-1h1zM18 13h-1v-1h1zM18 12h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM19 10h-1V9h1zM19 11h-1v-1h1zM19 12h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM19 10h-1V9h1zM19 11h-1v-1h1zM19 12h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM19 15h-1v-1h1zM19 16h-1v-1h1zM18 16h-1v-1h1zM17 16h-1v-1h1zM16 16h-1v-1h1zM17 15h-1v-1h1zM18 15h-1v-1h1zM18 14h-1v-1h1zM18 13h-1v-1h1zM18 12h-1v-1h1zM15 16h-1v-1h1zM24 13h-1v-1h1zM24 14h-1v-1h1zM24 15h-1v-1h1zM25 13h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM19 10h-1V9h1zM18 10h-1V9h1zM18 12h-1v-1h1zM19 11h-1v-1h1zM19 12h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM19 15h-1v-1h1zM18 14h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zM19 10h-1V9h1zM19 11h-1v-1h1zM19 13h-1v-1h1zM19 14h-1v-1h1zM19 16h-1v-1h1zM18 16h-1v-1h1zM22 9h-1V8h1z' />",
        "<path fill='url(#mane-color)' d='M21 9h-1V8h1zm-2 1h-1V9h1zm-1 0h-1V9h1zm0 2h-1v-1h1zm1-1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm0 1h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm-1 0h-1v-1h1zm4-1h-1v-1h1zm-2 0h-1v-1h1zm10-2h-1v-1h1zm1 0h-1v-1h1zm-1 1h-1v-1h1zm0 1h-1v-1h1zm-6-1h-1v-1h1zm4-5h-1V8h1z' />"
    ];
    string[] private backgroundSvgs = [
        "<rect width='32' height='32' fill='#fff9d0' />",
        "<rect width='32' height='32' fill='#dfefff' />",
        "<rect width='32' height='32' fill='#aaffcf' />",
        "<rect width='32' height='32' fill='#efefcf' />",
        "<rect width='32' height='32' fill='#dadee9' />",
        "<rect width='32' height='32' fill='#ddadaf' />",
        "<rect width='32' height='32' fill='#ffefcf' />",
        "<rect width='32' height='32' fill='#bbe4ea' />",
        "<rect width='32' height='32' fill='#ffefbf' />",
        "<rect width='32' height='32' fill='#ffdfff' />"
    ];

    string[] private utilitySvgs = [
        "",
        "<path fill='#7f5748' d='M28 3h1v1h-1zM28 4h1v1h-1zM27 2h1v1h-1zM29 2h1v1h-1z' /><path fill='#ffda69' d='M29 3h1v1h-1zM29 5h1v1h-1zM27 3h1v1h-1zM27 5h1v1h-1z' />",
        "<path fill='#93d0f3' d='M27 23h1v1h-1zM27 24h1v1h-1zM28 22h1v1h-1z' /><path fill='#a4d18a' d='M28 21h1v1h-1z' /><path fill='#ffea84' d='M27 22h1v1h-1z' /><path fill='#93d0f3' d='M27 25h1v1h-1zM26 25h1v1h-1zM28 25h1v1h-1zM26 22h1v1h-1z' />",
        "<path fill='#ffda69' d='M27 20h1v1h-1zM26 21h1v1h-1z' /><path fill='#7f5748' d='M27 21h1v1h-1z' /><path fill='#ffda69' d='M28 21h1v1h-1zM28 22h1v1h-1zM27 22h1v1h-1zM26 22h1v1h-1zM27 23h1v1h-1zM27 24h1v1h-1zM26 25h1v1h-1zM27 25h1v1h-1zM28 25h1v1h-1z' />",
        "<path fill='#ffda69' d='M27 18h1v1h-1zM28 20h1v1h-1zM27 22h1v1h-1zM27 23h1v1h-1zM26 23h1v1h-1zM26 24h1v1h-1z' /><path fill='#d9554d' d='M27 24h1v1h-1z' /><path fill='#ffda69' d='M28 24h1v1h-1z' /><path fill='#a85f44' d='M28 25h1v1h-1zM27 25h1v1h-1zM26 25h1v1h-1zM25 25h1v1h-1zM29 25h1v1h-1z' />",
        "<path fill='#4dc7f6' d='M26 16h1v1h-1z' /><path fill='#555' d='M27 24h1v1h-1zm1-1h1v1h-1zm1-1h1v1h-1zm1-1h1v1h-1zm1-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm-1-1h1v1h-1zm-1-1h1v1h-1zm-1-1h1v1h-1zm-1 0h1v1h-1zm0 8h1v1h-1zm0 2h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm3 0h1v1h-1zm1 0h1v1h-1z' /><path fill='#4dc7f6' d='M25 17h1v1h-1z' /><path fill='#56b746' d='M24 18h1v1h-1zm0 1h1v1h-1z' /><path fill='#4dc7f6' d='M24 20h1v1h-1zm1 1h1v1h-1zm1 1h1v1h-1z' /><path fill='#56b746' d='M27 22h1v1h-1z' /><path fill='#4dc7f6' d='M28 22h1v1h-1zm1-1h1v1h-1z' /><path fill='#56b746' d='M30 20h1v1h-1z' /><path fill='#4dc7f6' d='M30 19h1v1h-1z' /><path fill='#56b746' d='M30 18h1v1h-1z' /><path fill='#4dc7f6' d='M29 17h1v1h-1zm-1-1h1v1h-1z' /><path fill='#56b746' d='M27 16h1v1h-1z' /><path fill='#4dc7f6' d='M26 17h1v1h-1z' /><path fill='#56b746' d='M26 18h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm1 1h1v1h-1z' /><path fill='#4dc7f6' d='M26 19h1v1h-1zm-1 1h1v1h-1zm1 1h1v1h-1z' /><path fill='#56b746' d='M27 21h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1z' /><path fill='#4dc7f6' d='M29 20h1v1h-1z' /><path fill='#56b746' d='M29 19h1v1h-1zm0-1h1v1h-1z' /><path fill='#4dc7f6' d='M28 18h1v1h-1z' /><path fill='#56b746' d='M27 18h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1z' />",
        "<path fill='#000' d='M27 8h1v1h-1zM26 7h1v1h-1zM28 7h1v1h-1zM22 4h1v1h-1zM21 3h1v1h-1zM23 3h1v1h-1zM28 3h1v1h-1zM27 2h1v1h-1zM29 2h1v1h-1z' />",
        "<path fill='#555' d='M27 25h1v1h-1zM27 24h1v1h-1zM27 23h1v1h-1zM27 22h1v1h-1zM26 25h1v1h-1zM26 22h1v1h-1zM28 22h1v1h-1zM28 25h1v1h-1z' /><path fill='#27aae1' d='M26 18h1v1h-1zM25 19h1v1h-1zM25 20h1v1h-1zM26 21h1v1h-1zM27 21h1v1h-1zM28 21h1v1h-1zM29 20h1v1h-1zM29 19h1v1h-1zM29 18h1v1h-1zM28 17h1v1h-1zM27 17h1v1h-1zM26 17h1v1h-1zM25 18h1v1h-1zM26 19h1v1h-1zM26 20h1v1h-1zM27 20h1v1h-1zM28 20h1v1h-1zM28 19h1v1h-1z' /><path fill='#fff' d='M28 18h1v1h-1z' /><path fill='#27aae1' d='M27 18h1v1h-1zM27 19h1v1h-1z' />",
        "<path fill='#75c164' d='M27 25h1v1h-1zM27 24h1v1h-1zM27 23h1v1h-1z' /><path fill='#ffda6a' d='M27 22h1v1h-1z' /><path fill='#ee2636' d='M27 21h1v1h-1z' /><path fill='#ffda6a' d='M27 20h1v1h-1z' /><path fill='#fff' d='M26 20h1v1h-1z' /><path fill='#ffda6a' d='M26 21h1v1h-1z' /><path fill='#fff' d='M26 22h1v1h-1zM28 22h1v1h-1z' /><path fill='#ffda6a' d='M28 21h1v1h-1z' /><path fill='#fff' d='M28 20h1v1h-1z' /><path fill='#75c164' d='M28 24h1v1h-1z' />",
        "<path fill='#1c75bc' d='M27 22h1v1h-1zm-1 1h1v1h-1zm0 1h1v1h-1zm1 1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1-1h1v1h-1zm0-1h1v1h-1zm-1-1h1v1h-1z' /><path fill='#00aeef' d='M27 23h1v1h-1zm1 0h1v1h-1z' /><path fill='#fbb040' d='M29 23h1v1h-1z' /><path fill='#00aeef' d='M29 24h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1z' />",
        "<path fill='#754c29' d='M26 24h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm-1 1h1v1h-1zm-1 0h1v1h-1z' /><path fill='#a97c50' d='M28 23h1v1h-1zm-1-1h1v1h-1zm1-1h1v1h-1zm1 0h1v1h-1zm1-1h1v1h-1z' /><path fill='#75c164' d='M30 19h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1z' />",
        "<path fill='#8b5e3c' d='M26 25h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm-2 0h1v1h-1zm-1 0h1v1h-1z' /><path fill='#ffda6a' d='M27 22h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm-3 0h1v1h-1zm1-1h1v1h-1zm1 0h1v1h-1z' /><path fill='#8b5e3c' d='M26 24h1v1h-1z' /><path fill='#414042' d='M27 24h1v1h-1zm1 0h1v1h-1z' /><path fill='#8b5e3c' d='M28 23h1v1h-1zm2-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm1 1h1v1h-1zm0 1h1v1h-1z' />",
        "<path fill='#a97c50' d='M29 25h1v1h-1zm-2 0h1v1h-1z' /><path fill='#4eb74a' d='M24 23h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm2 0h1v1h-1z' /><path fill='#408251' d='M27 24h1v1h-1zm0-1h1v1h-1zm1-1h1v1h-1zm1 0h1v1h-1zm1 2h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1z' /><path fill='#4eb74a' d='M31 24h1v1h-1z' />",
        "<path fill='#f57f20' d='M26 25h1v1h-1zM28 25h1v1h-1z' /><path fill='#fff' d='M29 23h1v1h-1zM29 22h1v1h-1zM29 24h1v1h-1zM28 24h1v1h-1zM27 24h1v1h-1zM26 24h1v1h-1zM26 23h1v1h-1zM25 23h1v1h-1zM25 22h1v1h-1zM25 21h1v1h-1zM25 20h1v1h-1zM26 20h1v1h-1zM26 21h1v1h-1zM26 22h1v1h-1zM27 23h1v1h-1zM28 23h1v1h-1z' /><path fill='#ebbd54' d='M24 21h1v1h-1z' />",
        "<path fill='#939598' opacity='.5' d='M26 23h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm1 0h1v1h-1zm0 2h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm-1-1h1v1h-1zm-1 1h1v1h-1zm-1-1h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm-1-1h1v1h-1zm-1 1h1v1h-1zm0 1h1v1h-1zm0 1h1v1h-1zm1-1h1v1h-1z' /><path fill='#fff200' d='M30 19h1v1h-1zm-2 0h1v1h-1z' />"
    ];

    // attribute names
    string[] private patternNames = [
        "giraffe",
        "small spots",
        "two tone",
        "tips",
        "curves",
        "stripes",
        "racing",
        "big spots",
        "butt naked",
        "death"
    ];
    string[] private headAccessoryNames = [
        "none",
        "purple cap",
        "propeller cap",
        "golden necklace",
        "unicorn horn",
        "flame breath",
        "top hat",
        "devil horns",
        "wizard hat",
        "laser",
        "viking helmet",
        "golden halo",
        "rainbow puke",
        "crown"
    ];
    string[] private bodyAccessoryNames = [
        "none",
        "winner",
        "bravery boots",
        "rainbow",
        "charged",
        "wings",
        "speed booster",
        "black cat",
        "hell wings"
    ];
    string[] private maneColorNames = [
        "black",
        "strawberry",
        "blackberry",
        "juneberry",
        "cranberry",
        "cloudberry",
        "snowberry",
        "blueberry",
        "caperberry",
        "dewberry",
        "gold"
    ];
    string[] private patternColorNames = [
        "brown",
        "dark",
        "light blue",
        "pink",
        "purple",
        "green",
        "red",
        "cream",
        "orange",
        "blue",
        "deep pink",
        "white"
    ];
    string[] private hoofColorNames = [
        "black",
        "dark brown",
        "dark blue",
        "brown",
        "dark green",
        "light green",
        "red",
        "light purple",
        "purple",
        "pink",
        "gold"
    ];
    string[] private bodyColorNames = [
        "giraffe",
        "butterfly",
        "elephant",
        "bear",
        "polar bear",
        "frog",
        "lobster",
        "turtle",
        "whale",
        "gold"
    ];
    string[] private tailNames = [
        "normal",
        "pointy",
        "dog",
        "long",
        "bun",
        "baked",
        "pile",
        "dragon"
    ];
    string[] private maneNames = [
        "normal",
        "messy",
        "tidy",
        "overwhelming",
        "short",
        "bearded",
        "dragon",
        "baked",
        "mother of dragons"
    ];
    string[] private backgroundNames = [
        "curd",
        "starlight",
        "seafoam",
        "ghost green",
        "fog",
        "chestnut",
        "sand",
        "ice",
        "banana",
        "grape"
    ];
    string[] private utilityNames = [
        "none",
        "butterfly of fortune",
        "martini with alcohol",
        "grail of gold",
        "bonfire from hell",
        "globe of nastyness",
        "bats of mayhem",
        "orb of future",
        "flower of goodwill",
        "bowl of gold fish",
        "bonsai of life",
        "chest with bling",
        "turtle of speed",
        "duck of doom",
        "ghost of death"
    ];

    // attribute rarities
    uint256[] private maneColorRarities = [
        4000,
        1000,
        1000,
        1000,
        800,
        800,
        500,
        300,
        300,
        200,
        100
    ];
    uint256[] private patternColorRarities = [
        3000,
        1700,
        1350,
        900,
        800,
        800,
        500,
        300,
        200,
        200,
        150,
        100
    ];
    uint256[] private hoofColorRarities = [
        3500,
        1500,
        1100,
        1000,
        1000,
        500,
        500,
        400,
        200,
        200,
        100
    ];
    uint256[] private bodyColorRarities = [
        2900,
        1500,
        1500,
        1500,
        700,
        600,
        500,
        500,
        200,
        100
    ];
    uint256[] private backgroundRarities = [
        1000,
        1000,
        1000,
        1000,
        1000,
        1000,
        1000,
        1000,
        1000,
        1000
    ];
    uint256[] private tailRarities = [
        3000,
        2000,
        1500,
        1200,
        1000,
        750,
        350,
        200
    ];
    uint256[] private maneRarities = [
        3000,
        1800,
        1600,
        900,
        800,
        700,
        600,
        400,
        200
    ];
    uint256[] private patternRarities = [
        2000,
        1500,
        1500,
        1100,
        1000,
        800,
        800,
        500,
        500,
        300
    ];
    uint256[] private headAccessoryRarities = [
        3100,
        1500,
        1000,
        800,
        700,
        700,
        500,
        550,
        250,
        300,
        300,
        150,
        100,
        50
    ];
    uint256[] private bodyAccessoryRarities = [
        2500,
        2300,
        1400,
        1000,
        800,
        800,
        600,
        400,
        200
    ];
    uint256[] private utilityRarities = [
        3700,
        1000,
        900,
        500,
        400,
        500,
        200,
        600,
        900,
        500,
        300,
        250,
        100,
        100,
        50
    ];

    // amount of attributes
    uint8 constant maneColorCount = 11;
    uint8 constant patternColorCount = 12;
    uint8 constant hoofColorCount = 11;
    uint8 constant bodyColorCount = 10;
    uint8 constant backgroundCount = 10;
    uint8 constant tailCount = 8;
    uint8 constant maneCount = 9;
    uint8 constant patternCount = 10;
    uint8 constant headAccessoryCount = 14;
    uint8 constant bodyAccessoryCount = 9;
    uint8 constant utilityCount = 15;

    /**
     * Use:
     * Get a random attribute using the rarities defined
     */
    function getRandomIndex(
        uint256[] memory attributeRarities,
        uint8 attributeCount,
        uint256 randomNumber
    ) private pure returns (uint8 index) {
        uint256 random10k = randomNumber % 10000;
        uint256 steps = 0;
        for (uint8 i = 0; i < attributeCount; i++) {
            uint256 currentRarity = attributeRarities[i] + steps;
            if (random10k < currentRarity) {
                return i;
            }
            steps = currentRarity;
        }
        return 0;
    }

    /**
     * Use:
     * Get random attributes for each different property of the token
     *
     * Comment:
     * Can only be used by the TokenContract defined by address tokenContract
     */
    function getRandomAttributes(uint256 randomNumber)
        public
        view
        returns (
            uint8 maneColor,
            uint8 patternColor,
            uint8 hoofColor,
            uint8 bodyColor,
            uint8 background,
            uint8 tail,
            uint8 mane,
            uint8 pattern,
            uint8 headAccessory,
            uint8 bodyAccessory,
            uint8 utility
        )
    {
        maneColor = getRandomManeColor(randomNumber);
        randomNumber = randomNumber / 10;
        patternColor = getRandomPatternColor(randomNumber);
        randomNumber = randomNumber / 10;
        hoofColor = getRandomHoofColor(randomNumber);
        randomNumber = randomNumber / 10;
        bodyColor = getRandomBodyColor(randomNumber);
        randomNumber = randomNumber / 10;
        background = getRandomBackground(randomNumber);
        randomNumber = randomNumber / 10;
        tail = getRandomTail(randomNumber);
        randomNumber = randomNumber / 10;
        mane = getRandomMane(randomNumber);
        randomNumber = randomNumber / 10;
        pattern = getRandomPattern(randomNumber);
        randomNumber = randomNumber / 10;
        headAccessory = getRandomHeadAccessory(randomNumber);
        randomNumber = randomNumber / 10;
        bodyAccessory = getRandomBodyAccessory(randomNumber);
        randomNumber = randomNumber / 10;
        utility = getRandomUtility(randomNumber);

        return (
            maneColor,
            patternColor,
            hoofColor,
            bodyColor,
            background,
            tail,
            mane,
            pattern,
            headAccessory,
            bodyAccessory,
            utility
        );
    }

    function getRandomManeColor(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return getRandomIndex(maneColorRarities, maneColorCount, randomNumber);
    }

    function getRandomPatternColor(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return
            getRandomIndex(
                patternColorRarities,
                patternColorCount,
                randomNumber
            );
    }

    function getRandomHoofColor(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return getRandomIndex(hoofColorRarities, hoofColorCount, randomNumber);
    }

    function getRandomBodyColor(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return getRandomIndex(bodyColorRarities, bodyColorCount, randomNumber);
    }

    function getRandomBackground(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return
            getRandomIndex(backgroundRarities, backgroundCount, randomNumber);
    }

    function getRandomTail(uint256 randomNumber) private view returns (uint8) {
        return getRandomIndex(tailRarities, tailCount, randomNumber);
    }

    function getRandomMane(uint256 randomNumber) private view returns (uint8) {
        return getRandomIndex(maneRarities, maneCount, randomNumber);
    }

    function getRandomPattern(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return getRandomIndex(patternRarities, patternCount, randomNumber);
    }

    function getRandomHeadAccessory(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return
            getRandomIndex(
                headAccessoryRarities,
                headAccessoryCount,
                randomNumber
            );
    }

    function getRandomBodyAccessory(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return
            getRandomIndex(
                bodyAccessoryRarities,
                bodyAccessoryCount,
                randomNumber
            );
    }

    function getRandomUtility(uint256 randomNumber)
        private
        view
        returns (uint8)
    {
        return getRandomIndex(utilityRarities, utilityCount, randomNumber);
    }

    /**
     * Use:
     * Get the attribute name for the properties of the token
     *
     * Comment:
     * Can only be used by the TokenContract defined by address tokenContract
     */
    function getManeColor(uint8 index) public view returns (string memory) {
        return maneColorNames[index];
    }

    function getPatternColor(uint8 index) public view returns (string memory) {
        return patternColorNames[index];
    }

    function getHoofColor(uint8 index) public view returns (string memory) {
        return hoofColorNames[index];
    }

    function getBodyColor(uint8 index) public view returns (string memory) {
        return bodyColorNames[index];
    }

    function getBackground(uint8 index) public view returns (string memory) {
        return backgroundNames[index];
    }

    function getTail(uint8 index) public view returns (string memory) {
        return tailNames[index];
    }

    function getMane(uint8 index) public view returns (string memory) {
        return maneNames[index];
    }

    function getPattern(uint8 index) public view returns (string memory) {
        return patternNames[index];
    }

    function getHeadAccessory(uint8 index) public view returns (string memory) {
        return headAccessoryNames[index];
    }

    function getBodyAccessory(uint8 index) public view returns (string memory) {
        return bodyAccessoryNames[index];
    }

    function getUtility(uint8 index) public view returns (string memory) {
        return utilityNames[index];
    }

    /**
     * Use:
     * Get the attribute svg for a different property of the token
     *
     * Comment:
     * Can only be used by the TokenContract defined by address tokenContract
     */
    function renderHorse(
        bytes memory colors,
        uint8 background,
        uint8 tail,
        uint8 mane,
        uint8 pattern,
        uint8 headAccessory,
        uint8 bodyAccessory,
        uint8 utility
    ) public view returns (bytes memory) {
        bytes memory start = abi.encodePacked(
            svgStart,
            colors,
            backgroundSvgs[background],
            base,
            patternSvgs[pattern]
        );
        return
            abi.encodePacked(
                start,
                tailSvgs[tail],
                maneSvgs[mane],
                headAccessorySvgs[headAccessory],
                bodyAccessorySvgs[bodyAccessory],
                utilitySvgs[utility],
                svgEnd
            );
    }

    /**
     * Use:
     * Create color definitions for the svg
     */
    function packColor(string memory colorName, string memory colorSvg)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                "<linearGradient id='",
                colorName,
                "'><stop stop-color='",
                colorSvg,
                "'/></linearGradient>"
            );
    }

    /**
     * Use:
     * Pack all colors together
     */
    function renderColors(
        uint8 maneColor,
        uint8 patternColor,
        uint8 hoofColor,
        uint8 bodyColor
    ) public view returns (bytes memory) {
        return
            abi.encodePacked(
                "<defs>",
                packColor("mane-color", maneColorSvgs[maneColor]),
                packColor("pattern-color", patternColorSvgs[patternColor]),
                packColor("hoof-color", hoofColorSvgs[hoofColor]),
                packColor("body-color", bodyColorSvgs[bodyColor]),
                "</defs>"
            );
    }
}
