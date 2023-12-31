// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Milan
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//              .__  .__                         //
//      _____   |__| |  |   _____      ____      //
//     /     \  |  | |  |   \__  \    /    \     //
//    |  Y Y  \ |  | |  |__  / __ \_ |   |  \    //
//    |__|_|  / |__| |____/ (____  / |___|  /    //
//          \/                   \/       \/     //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract mild is ERC721Creator {
    constructor() ERC721Creator("Milan", "mild") {}
}
