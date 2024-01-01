// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Interactive art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Another Acid Boy art    //
//                            //
//                            //
////////////////////////////////


contract IA is ERC721Creator {
    constructor() ERC721Creator("Interactive art", "IA") {}
}
