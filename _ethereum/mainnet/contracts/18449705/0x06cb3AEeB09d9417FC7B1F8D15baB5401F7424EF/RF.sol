// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flavio Reber Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    Flavio Reber Editions minted on Manifold    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract RF is ERC721Creator {
    constructor() ERC721Creator("Flavio Reber Editions", "RF") {}
}
