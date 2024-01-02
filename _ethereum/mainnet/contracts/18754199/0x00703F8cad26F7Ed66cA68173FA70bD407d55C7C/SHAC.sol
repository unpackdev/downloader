// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: soukisaragi healing art collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    soukisaragi healing art collection    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract SHAC is ERC721Creator {
    constructor() ERC721Creator("soukisaragi healing art collection", "SHAC") {}
}
