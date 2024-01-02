// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Da Goatz
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    ShaynaCreates    //
//                     //
//                     //
/////////////////////////


contract SC is ERC1155Creator {
    constructor() ERC1155Creator("Da Goatz", "SC") {}
}
