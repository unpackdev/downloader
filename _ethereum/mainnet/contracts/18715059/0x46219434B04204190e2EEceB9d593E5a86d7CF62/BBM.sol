// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bong Bong Miami
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Bing Bong     //
//                  //
//                  //
//////////////////////


contract BBM is ERC721Creator {
    constructor() ERC721Creator("Bong Bong Miami", "BBM") {}
}
