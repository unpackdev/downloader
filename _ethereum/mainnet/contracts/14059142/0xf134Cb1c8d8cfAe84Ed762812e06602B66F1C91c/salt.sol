
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sand & Salt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//             _               _                       //
//      __ _  | |  ___  __ __ | |__  ___   ___  ___    //
//     / _` | | | / -_) \ \ / | / / / -_) (_-< (_-<    //
//     \__,_| |_| \___| /_\_\ |_\_\ \___| /__/ /__/    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract salt is ERC721Creator {
    constructor() ERC721Creator("Sand & Salt", "salt") {}
}
