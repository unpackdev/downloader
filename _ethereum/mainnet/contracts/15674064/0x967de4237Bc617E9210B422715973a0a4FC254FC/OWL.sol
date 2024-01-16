
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OWALA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    E L V N T H     //
//                    //
//                    //
////////////////////////


contract OWL is ERC721Creator {
    constructor() ERC721Creator("OWALA", "OWL") {}
}
