
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Works of Korbinian Vogt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Works of Korbinian Vogt.    //
//                                //
//                                //
////////////////////////////////////


contract WOKV is ERC721Creator {
    constructor() ERC721Creator("Works of Korbinian Vogt", "WOKV") {}
}
