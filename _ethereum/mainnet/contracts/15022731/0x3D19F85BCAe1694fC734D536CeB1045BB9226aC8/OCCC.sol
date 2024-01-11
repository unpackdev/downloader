
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Occultastic
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//     ▄▀▀▀▀▄   ▄▀▄▄▄▄   ▄▀▄▄▄▄   ▄▀▄▄▄▄      //
//    █      █ █ █    ▌ █ █    ▌ █ █    ▌     //
//    █      █ ▐ █      ▐ █      ▐ █          //
//    ▀▄    ▄▀   █        █        █          //
//      ▀▀▀▀    ▄▀▄▄▄▄▀  ▄▀▄▄▄▄▀  ▄▀▄▄▄▄▀     //
//             █     ▐  █     ▐  █     ▐      //
//             ▐        ▐        ▐            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract OCCC is ERC721Creator {
    constructor() ERC721Creator("The Occultastic", "OCCC") {}
}
