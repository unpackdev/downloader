// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kill your idols
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    X    //
//         //
//         //
/////////////


contract KYLS is ERC721Creator {
    constructor() ERC721Creator("kill your idols", "KYLS") {}
}
