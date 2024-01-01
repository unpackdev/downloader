// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BASKITCH
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    BASKITCH    //
//                //
//                //
////////////////////


contract BASK is ERC721Creator {
    constructor() ERC721Creator("BASKITCH", "BASK") {}
}
