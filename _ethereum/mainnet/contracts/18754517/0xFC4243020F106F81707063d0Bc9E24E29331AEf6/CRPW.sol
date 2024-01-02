// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stories from the Creepwoods
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    #    //
//         //
//         //
/////////////


contract CRPW is ERC721Creator {
    constructor() ERC721Creator("Stories from the Creepwoods", "CRPW") {}
}
