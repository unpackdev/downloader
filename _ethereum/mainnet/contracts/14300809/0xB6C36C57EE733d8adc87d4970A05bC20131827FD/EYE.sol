
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Optics
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//     __    __   __   _______  __  ___   ___     //
//    |  |  |  | |  | |   ____||  | \  \ /  /     //
//    |  |__|  | |  | |  |__   |  |  \  V  /      //
//    |   __   | |  | |   __|  |  |   >   <       //
//    |  |  |  | |  | |  |     |  |  /  .  \      //
//    |__|  |__| |__| |__|     |__| /__/ \__\     //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract EYE is ERC721Creator {
    constructor() ERC721Creator("Optics", "EYE") {}
}
