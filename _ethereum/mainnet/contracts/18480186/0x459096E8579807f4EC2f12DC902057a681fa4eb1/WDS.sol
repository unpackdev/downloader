// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: woods
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    woods                //
//    fernando gallegos    //
//    2023 -               //
//                         //
//                         //
/////////////////////////////


contract WDS is ERC721Creator {
    constructor() ERC721Creator("woods", "WDS") {}
}
