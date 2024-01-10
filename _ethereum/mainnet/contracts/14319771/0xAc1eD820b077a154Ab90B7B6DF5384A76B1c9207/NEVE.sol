
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NEVE CONTRACT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    NEVECONTRACT    //
//                    //
//                    //
////////////////////////


contract NEVE is ERC721Creator {
    constructor() ERC721Creator("NEVE CONTRACT", "NEVE") {}
}
