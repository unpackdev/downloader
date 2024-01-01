// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3D Azuki Run
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    3D Azuki Run    //
//                    //
//                    //
////////////////////////


contract AR is ERC721Creator {
    constructor() ERC721Creator("3D Azuki Run", "AR") {}
}
