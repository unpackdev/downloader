
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nifty Alphabet V1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    TangOrigina    //
//                   //
//                   //
///////////////////////


contract NFL is ERC721Creator {
    constructor() ERC721Creator("Nifty Alphabet V1", "NFL") {}
}
