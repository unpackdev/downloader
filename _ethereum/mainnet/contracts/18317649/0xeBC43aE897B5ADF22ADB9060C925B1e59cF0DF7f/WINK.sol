// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fonzinomics
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    ⛓️🥶FONZI SCHEME🥶⛓️    //
//                            //
//                            //
////////////////////////////////


contract WINK is ERC721Creator {
    constructor() ERC721Creator("Fonzinomics", "WINK") {}
}
