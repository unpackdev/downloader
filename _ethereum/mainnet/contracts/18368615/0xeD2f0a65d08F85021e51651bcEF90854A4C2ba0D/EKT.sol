// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EMILY_KNIGHTS_ORIGINAL_TEST
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    EmilyKnights    //
//                    //
//                    //
////////////////////////


contract EKT is ERC721Creator {
    constructor() ERC721Creator("EMILY_KNIGHTS_ORIGINAL_TEST", "EKT") {}
}
