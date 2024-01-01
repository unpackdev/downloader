// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Low Effort Pizza
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    // ""--.._            //
//    ||  (_)  _ "-._       //
//    ||    _ (_)    '-.    //
//    ||   (_)   __..-'     //
//     \\__..--""           //
//                          //
//                          //
//////////////////////////////


contract LEPizza is ERC721Creator {
    constructor() ERC721Creator("Low Effort Pizza", "LEPizza") {}
}
