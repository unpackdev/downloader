// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: offline
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                             //
//                                                                                                                                             //
//     .d88b.  d88888b d88888b db      d888888b d8b   db d88888b      d8888b. db    db      d88888D d88888b d8888b.  .d88b.       db    db     //
//    .8P  Y8. 88'     88'     88        `88'   888o  88 88'          88  `8D `8b  d8'      YP  d8' 88'     88  `8D .8P  Y8.      `8b  d8'     //
//    88    88 88ooo   88ooo   88         88    88V8o 88 88ooooo      88oooY'  `8bd8'          d8'  88ooooo 88oobY' 88    88       `8bd8'      //
//    88    88 88~~~   88~~~   88         88    88 V8o88 88~~~~~      88~~~b.    88           d8'   88~~~~~ 88`8b   88    88       .dPYb.      //
//    `8b  d8' 88      88      88booo.   .88.   88  V888 88.          88   8D    88          d8' db 88.     88 `88. `8b  d8'      .8P  Y8.     //
//     `Y88P'  YP      YP      Y88888P Y888888P VP   V8P Y88888P      Y8888P'    YP         d88888P Y88888P 88   YD  `Y88P'       YP    YP     //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract offlinezero is ERC721Creator {
    constructor() ERC721Creator("offline", "offlinezero") {}
}
