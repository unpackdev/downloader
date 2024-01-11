
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Still Life
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    Yet another low effort, dogshit JPEG    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract SL is ERC721Creator {
    constructor() ERC721Creator("Still Life", "SL") {}
}
