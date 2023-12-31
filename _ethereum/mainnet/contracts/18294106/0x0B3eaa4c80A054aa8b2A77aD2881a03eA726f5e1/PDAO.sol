// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 📸 | Phtography DAO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    📸    //
//          //
//          //
//////////////


contract PDAO is ERC721Creator {
    constructor() ERC721Creator(unicode"📸 | Phtography DAO", "PDAO") {}
}
