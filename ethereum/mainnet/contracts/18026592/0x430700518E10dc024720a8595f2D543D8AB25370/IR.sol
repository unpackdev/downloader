// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: INFRARED
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//      _____ _____      //
//     |_   _|  __ \     //
//       | | | |__) |    //
//       | | |  _  /     //
//      _| |_| | \ \     //
//     |_____|_|  \_\    //
//                       //
//                       //
//                       //
///////////////////////////


contract IR is ERC721Creator {
    constructor() ERC721Creator("INFRARED", "IR") {}
}
