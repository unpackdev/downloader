
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hans Valør
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//    _  ______  _____   _  ______   ________     //
//    |__||__||\ |[__    |  ||__||   |  ||__/     //
//    |  ||  || \|___]    \/ |  ||___|__||  \     //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract HV77 is ERC721Creator {
    constructor() ERC721Creator(unicode"Hans Valør", "HV77") {}
}
