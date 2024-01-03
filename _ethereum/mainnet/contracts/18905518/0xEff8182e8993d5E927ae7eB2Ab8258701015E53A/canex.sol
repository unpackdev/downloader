// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cananapo exchange
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//    This is where I will mint items to exchange with others    //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract canex is ERC721Creator {
    constructor() ERC721Creator("cananapo exchange", "canex") {}
}
