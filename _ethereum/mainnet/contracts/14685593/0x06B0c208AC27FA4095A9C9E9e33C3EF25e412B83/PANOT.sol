
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PANOT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//     __   _        _ ___     //
//     )_) /_) )\ ) / ) )      //
//    /   / / (  ( (_/ (       //
//                             //
//                             //
//                             //
/////////////////////////////////


contract PANOT is ERC721Creator {
    constructor() ERC721Creator("PANOT", "PANOT") {}
}
