// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mech Dreamweaver: Resurrections
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//     ███▄ ▄███▓▓█████▄  ██▀███  ▓█████     //
//    ▓██▒▀█▀ ██▒▒██▀ ██▌▓██ ▒ ██▒▓█   ▀     //
//    ▓██    ▓██░░██   █▌▓██ ░▄█ ▒▒███       //
//    ▒██    ▒██ ░▓█▄   ▌▒██▀▀█▄  ▒▓█  ▄     //
//    ▒██▒   ░██▒░▒████▓ ░██▓ ▒██▒░▒████▒    //
//    ░ ▒░   ░  ░ ▒▒▓  ▒ ░ ▒▓ ░▒▓░░░ ▒░ ░    //
//    ░  ░      ░ ░ ▒  ▒   ░▒ ░ ▒░ ░ ░  ░    //
//    ░      ░    ░ ░  ░   ░░   ░    ░       //
//           ░      ░       ░        ░  ░    //
//                ░                          //
//                                           //
//                                           //
///////////////////////////////////////////////


contract MDRE is ERC1155Creator {
    constructor() ERC1155Creator("Mech Dreamweaver: Resurrections", "MDRE") {}
}
