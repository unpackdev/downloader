// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OG
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    ________    ________     //
//    \_____  \  /  _____/     //
//     /   |   \/   \  ___     //
//    /    |    \    \_\  \    //
//    \_______  /\______  /    //
//            \/        \/     //
//                             //
//                             //
/////////////////////////////////


contract OG is ERC721Creator {
    constructor() ERC721Creator("OG", "OG") {}
}
