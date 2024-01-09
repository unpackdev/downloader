
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Singles Going Steady
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    collection of singles written and recorded by darby trash    //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract sgs is ERC721Creator {
    constructor() ERC721Creator("Singles Going Steady", "sgs") {}
}
