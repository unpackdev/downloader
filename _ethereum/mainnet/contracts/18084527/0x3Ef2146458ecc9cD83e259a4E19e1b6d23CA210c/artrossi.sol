// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art ed. by Rossi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    artrossi    //
//                //
//                //
////////////////////


contract artrossi is ERC721Creator {
    constructor() ERC721Creator("Art ed. by Rossi", "artrossi") {}
}
