// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Americana
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                       //
//                                                                                                       //
//    Let's change the world with crypto.  Advocating continually for the rights of crypto hodlers.      //
//                                                                                                       //
//                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Americana is ERC721Creator {
    constructor() ERC721Creator("Americana", "Americana") {}
}
