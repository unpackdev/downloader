
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bellatorem
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    ░██▄░█▒░░▀█▀    //
//    ▒█▄█▒█▄▄░▒█▒    //
//                    //
//                    //
//                    //
//                    //
////////////////////////


contract BLT is ERC721Creator {
    constructor() ERC721Creator("Bellatorem", "BLT") {}
}
