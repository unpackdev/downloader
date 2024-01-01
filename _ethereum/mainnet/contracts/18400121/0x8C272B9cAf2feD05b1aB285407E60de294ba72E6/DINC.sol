// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: deincarnation
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                                                                  //
//     __   ___         __        __            ___    __           //
//    |  \ |__  | |\ | /  `  /\  |__) |\ |  /\   |  | /  \ |\ |     //
//    |__/ |___ | | \| \__, /~~\ |  \ | \| /~~\  |  | \__/ | \|     //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract DINC is ERC1155Creator {
    constructor() ERC1155Creator("deincarnation", "DINC") {}
}
