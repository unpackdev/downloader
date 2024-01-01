// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SAY NO TO WARS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Humans Say no to Wars!    //
//                              //
//                              //
//////////////////////////////////


contract NOWAR is ERC1155Creator {
    constructor() ERC1155Creator("SAY NO TO WARS", "NOWAR") {}
}
