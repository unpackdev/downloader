
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Airdrops
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Airdrops from Bhare.    //
//                            //
//                            //
////////////////////////////////


contract BAIR is ERC721Creator {
    constructor() ERC721Creator("Airdrops", "BAIR") {}
}
