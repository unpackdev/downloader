// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mech Dreamweaver: Dark Fate
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//     ███▄ ▄███▓▓█████▄ ▓█████▄   █████▒    //
//    ▓██▒▀█▀ ██▒▒██▀ ██▌▒██▀ ██▌▓██   ▒     //
//    ▓██    ▓██░░██   █▌░██   █▌▒████ ░     //
//    ▒██    ▒██ ░▓█▄   ▌░▓█▄   ▌░▓█▒  ░     //
//    ▒██▒   ░██▒░▒████▓ ░▒████▓ ░▒█░        //
//    ░ ▒░   ░  ░ ▒▒▓  ▒  ▒▒▓  ▒  ▒ ░        //
//    ░  ░      ░ ░ ▒  ▒  ░ ▒  ▒  ░          //
//    ░      ░    ░ ░  ░  ░ ░  ░  ░ ░        //
//           ░      ░       ░                //
//                ░       ░                  //
//                                           //
//                                           //
///////////////////////////////////////////////


contract MDDF is ERC1155Creator {
    constructor() ERC1155Creator("Mech Dreamweaver: Dark Fate", "MDDF") {}
}
