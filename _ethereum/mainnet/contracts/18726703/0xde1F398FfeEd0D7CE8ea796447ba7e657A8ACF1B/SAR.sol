// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SAR
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//                //
//    ┏┓┏┓┳┓      //
//    ┗┓┣┫┣┫      //
//    ┗┛┛┗┛┗      //
//                //
//                //
//                //
//                //
//                //
////////////////////


contract SAR is ERC721Creator {
    constructor() ERC721Creator("SAR", "SAR") {}
}
