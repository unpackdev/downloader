
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Water Is Bliss
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                   _                //
//                  | |               //
//    __      ____ _| |_ ___ _ __     //
//    \ \ /\ / / _` | __/ _ \ '__|    //
//     \ V  V / (_| | ||  __/ |       //
//      \_/\_/ \__,_|\__\___|_|       //
//                                    //
//                                    //
////////////////////////////////////////


contract water is ERC721Creator {
    constructor() ERC721Creator("Water Is Bliss", "water") {}
}
