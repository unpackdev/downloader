
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mani
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                                                   //
//    The ASCII art is a signature detail of the Manifold Creator contract. ASCII art is used to visually identify your contract, and plus it just looks really cool. Take the time to pick some ASCII art that is meaningful and represents your work, identity, and creativity.    //
//                                                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract man is ERC721Creator {
    constructor() ERC721Creator("mani", "man") {}
}
