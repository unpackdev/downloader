// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HOP
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    HOUSEOFPOO24    //
//                    //
//                    //
////////////////////////


contract HOP is ERC1155Creator {
    constructor() ERC1155Creator("HOP", "HOP") {}
}
