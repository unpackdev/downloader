// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Investixs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    Investixs    //
//                 //
//                 //
/////////////////////


contract Investixs is ERC721Creator {
    constructor() ERC721Creator("Investixs", "Investixs") {}
}
