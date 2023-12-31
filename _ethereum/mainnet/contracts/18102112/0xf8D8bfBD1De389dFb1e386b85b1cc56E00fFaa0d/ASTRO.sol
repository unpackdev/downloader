// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Asteroid Belt
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    105 109 115 99 104 109 101 99 107 108 101 115    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract ASTRO is ERC1155Creator {
    constructor() ERC1155Creator("The Asteroid Belt", "ASTRO") {}
}
