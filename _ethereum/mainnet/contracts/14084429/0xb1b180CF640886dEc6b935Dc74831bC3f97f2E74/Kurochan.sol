
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kurochan
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    Kurochan    //
//                //
//                //
////////////////////


contract Kurochan is ERC721Creator {
    constructor() ERC721Creator("Kurochan", "Kurochan") {}
}
