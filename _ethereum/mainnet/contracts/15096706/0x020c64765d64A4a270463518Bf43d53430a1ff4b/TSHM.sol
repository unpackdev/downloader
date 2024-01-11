
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tiger Streak Honorary Members
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    TIGER STREAK    //
//                    //
//                    //
////////////////////////


contract TSHM is ERC721Creator {
    constructor() ERC721Creator("Tiger Streak Honorary Members", "TSHM") {}
}
