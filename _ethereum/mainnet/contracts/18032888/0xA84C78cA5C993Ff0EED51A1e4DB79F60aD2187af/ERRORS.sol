// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Err�ors by jodi.org
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//     /$$$$$$$$                                                         /$$                                                 /$$ /$$                                      //
//    | $$_____/                                                        | $$                                                | $$|__/                                      //
//    | $$        /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$$      | $$$$$$$  /$$   /$$             /$$  /$$$$$$   /$$$$$$$ /$$      /$$$$$$   /$$$$$$   /$$$$$$     //
//    | $$$$$    /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$ /$$_____/      | $$__  $$| $$  | $$            |__/ /$$__  $$ /$$__  $$| $$     /$$__  $$ /$$__  $$ /$$__  $$    //
//    | $$__/   | $$  \__/| $$  \__/| $$  \ $$| $$  \__/|  $$$$$$       | $$  \ $$| $$  | $$             /$$| $$  \ $$| $$  | $$| $$    | $$  \ $$| $$  \__/| $$  \ $$    //
//    | $$      | $$      | $$      | $$  | $$| $$       \____  $$      | $$  | $$| $$  | $$            | $$| $$  | $$| $$  | $$| $$    | $$  | $$| $$      | $$  | $$    //
//    | $$$$$$$$| $$      | $$      |  $$$$$$/| $$       /$$$$$$$/      | $$$$$$$/|  $$$$$$$            | $$|  $$$$$$/|  $$$$$$$| $$ /$$|  $$$$$$/| $$      |  $$$$$$$    //
//    |________/|__/      |__/       \______/ |__/      |_______/       |_______/  \____  $$            | $$ \______/  \_______/|__/|__/ \______/ |__/       \____  $$    //
//                                                                                 /$$  | $$       /$$  | $$                                                 /$$  \ $$    //
//                                                                                |  $$$$$$/      |  $$$$$$/                                                |  $$$$$$/    //
//                                                                                 \______/        \______/                                                  \______/     //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//     /$$$$$$$  /$$$$$$$$ /$$    /$$       /$$                       /$$                           /$$                                                /$$                //
//    | $$__  $$| $$_____/| $$   | $$      | $$                      | $$                          | $$                                               | $$                //
//    | $$  \ $$| $$      | $$   | $$      | $$$$$$$  /$$   /$$      | $$$$$$$   /$$$$$$   /$$$$$$$| $$   /$$  /$$$$$$   /$$$$$$  /$$$$$$   /$$$$$$  /$$$$$$              //
//    | $$  | $$| $$$$$   |  $$ / $$/      | $$__  $$| $$  | $$      | $$__  $$ |____  $$ /$$_____/| $$  /$$/ /$$__  $$ /$$__  $$|____  $$ /$$__  $$|_  $$_/              //
//    | $$  | $$| $$__/    \  $$ $$/       | $$  \ $$| $$  | $$      | $$  \ $$  /$$$$$$$| $$      | $$$$$$/ | $$$$$$$$| $$  \__/ /$$$$$$$| $$  \__/  | $$                //
//    | $$  | $$| $$        \  $$$/        | $$  | $$| $$  | $$      | $$  | $$ /$$__  $$| $$      | $$_  $$ | $$_____/| $$      /$$__  $$| $$        | $$ /$$            //
//    | $$$$$$$/| $$$$$$$$   \  $/         | $$$$$$$/|  $$$$$$$      | $$  | $$|  $$$$$$$|  $$$$$$$| $$ \  $$|  $$$$$$$| $$ /$$ |  $$$$$$$| $$        |  $$$$/            //
//    |_______/ |________/    \_/          |_______/  \____  $$      |__/  |__/ \_______/ \_______/|__/  \__/ \_______/|__/|__/  \_______/|__/         \___/              //
//                                                    /$$  | $$                                                                                                           //
//                                                   |  $$$$$$/                                                                                                           //
//                                                    \______/                                                                                                            //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ERRORS is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Err�ors by jodi.org", "ERRORS") {}
}
