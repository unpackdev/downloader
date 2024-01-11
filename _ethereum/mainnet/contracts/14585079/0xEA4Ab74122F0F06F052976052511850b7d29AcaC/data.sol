
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Data Entry
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//                //
//     |  |-      //
//    (|(||_(|    //
//                //
//                //
//                //
//                //
////////////////////


contract data is ERC721Creator {
    constructor() ERC721Creator("Data Entry", "data") {}
}
