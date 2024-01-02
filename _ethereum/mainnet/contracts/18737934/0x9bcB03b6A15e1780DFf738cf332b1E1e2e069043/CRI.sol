// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Coders Room: Into the Room
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Coders Room Services    //
//                            //
//                            //
////////////////////////////////


contract CRI is ERC721Creator {
    constructor() ERC721Creator("Coders Room: Into the Room", "CRI") {}
}
