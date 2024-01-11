
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kreo_meta
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//                          //
//      _                   //
//     | |___ _ ___ ___     //
//     | / / '_/ -_) _ \    //
//     |_\_\_| \___\___/    //
//                          //
//                          //
//                          //
//                          //
//////////////////////////////


contract kreo is ERC721Creator {
    constructor() ERC721Creator("kreo_meta", "kreo") {}
}
