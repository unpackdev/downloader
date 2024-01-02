// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Star Pass
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Here's your Star pass...    //
//                                //
//                                //
////////////////////////////////////


contract STAR is ERC721Creator {
    constructor() ERC721Creator("Star Pass", "STAR") {}
}
