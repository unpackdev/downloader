
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nobody's Fucking Trash Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//     ___/-\___     //
//    |---------|    //
//    | | | | | |    //
//    | | | | | |    //
//    | | | | | |    //
//    | | | | | |    //
//     |_______|     //
//                   //
//                   //
///////////////////////


contract NFTA is ERC721Creator {
    constructor() ERC721Creator("Nobody's Fucking Trash Art", "NFTA") {}
}
