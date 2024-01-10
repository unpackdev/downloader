
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CartoonArt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    Collection of cartoon art. Make with love.     //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract CRNART is ERC721Creator {
    constructor() ERC721Creator("CartoonArt", "CRNART") {}
}
