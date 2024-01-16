
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I Feel Things
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//      _____ ______ _______     //
//     |_   _|  ____|__   __|    //
//       | | | |__     | |       //
//       | | |  __|    | |       //
//      _| |_| |       | |       //
//     |_____|_|       |_|       //
//                               //
//                               //
//                               //
//                               //
///////////////////////////////////


contract IFT is ERC721Creator {
    constructor() ERC721Creator("I Feel Things", "IFT") {}
}
