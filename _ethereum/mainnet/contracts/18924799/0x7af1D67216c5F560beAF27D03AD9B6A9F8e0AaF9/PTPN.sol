// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peter Pan
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    Jedidiah    //
//                //
//                //
////////////////////


contract PTPN is ERC721Creator {
    constructor() ERC721Creator("Peter Pan", "PTPN") {}
}
