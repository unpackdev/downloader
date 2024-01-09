
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Your Fave Potato
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Your Fave Potato    //
//                        //
//                        //
////////////////////////////


contract Potato is ERC721Creator {
    constructor() ERC721Creator("Your Fave Potato", "Potato") {}
}
