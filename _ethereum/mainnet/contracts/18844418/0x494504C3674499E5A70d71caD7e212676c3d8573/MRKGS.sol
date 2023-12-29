// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Markings*
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    *    //
//         //
//         //
/////////////


contract MRKGS is ERC721Creator {
    constructor() ERC721Creator("Markings*", "MRKGS") {}
}
