
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Krista Awad Oil Paintings
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    Visual Artist. Based in La.     //
//                                    //
//                                    //
////////////////////////////////////////


contract KAOP is ERC721Creator {
    constructor() ERC721Creator("Krista Awad Oil Paintings", "KAOP") {}
}
