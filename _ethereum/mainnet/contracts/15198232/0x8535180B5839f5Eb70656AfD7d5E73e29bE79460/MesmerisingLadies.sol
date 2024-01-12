
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mesmerising Ladies
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Mesmerising Ladies    //
//                          //
//                          //
//////////////////////////////


contract MesmerisingLadies is ERC721Creator {
    constructor() ERC721Creator("Mesmerising Ladies", "MesmerisingLadies") {}
}
