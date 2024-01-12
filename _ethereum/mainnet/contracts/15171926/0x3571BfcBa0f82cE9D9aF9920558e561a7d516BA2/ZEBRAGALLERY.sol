
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ZEBRAGALLERY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    ZEBRAGALLERY    //
//                    //
//                    //
////////////////////////


contract ZEBRAGALLERY is ERC721Creator {
    constructor() ERC721Creator("ZEBRAGALLERY", "ZEBRAGALLERY") {}
}
