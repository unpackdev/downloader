// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evil In Entertainment
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    EvilInEntertainment    //
//                           //
//                           //
///////////////////////////////


contract EvilInEntertainment is ERC1155Creator {
    constructor() ERC1155Creator("Evil In Entertainment", "EvilInEntertainment") {}
}
