// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Béchir Boussandel
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Béchir Boussandel    //
//                         //
//                         //
/////////////////////////////


contract BBS is ERC721Creator {
    constructor() ERC721Creator(unicode"Béchir Boussandel", "BBS") {}
}
