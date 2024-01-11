
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MasMax
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    you are more that you have become    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract MM is ERC721Creator {
    constructor() ERC721Creator("MasMax", "MM") {}
}
