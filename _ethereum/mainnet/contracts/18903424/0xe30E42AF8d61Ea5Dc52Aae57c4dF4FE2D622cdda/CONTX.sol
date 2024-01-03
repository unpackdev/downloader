// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Contextually out of Context
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//     _______  _______  __    _  _______  __   __     //
//    |       ||       ||  |  | ||       ||  |_|  |    //
//    |       ||   _   ||   |_| ||_     _||       |    //
//    |       ||  | |  ||       |  |   |  |       |    //
//    |      _||  |_|  ||  _    |  |   |   |     |     //
//    |     |_ |       || | |   |  |   |  |   _   |    //
//    |_______||_______||_|  |__|  |___|  |__| |__|    //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract CONTX is ERC1155Creator {
    constructor() ERC1155Creator("Contextually out of Context", "CONTX") {}
}
