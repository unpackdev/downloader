// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artist Code Limited Edition
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    Artist Code Limited Edition    //
//                                   //
//                                   //
///////////////////////////////////////


contract ACLE is ERC1155Creator {
    constructor() ERC1155Creator("Artist Code Limited Edition", "ACLE") {}
}
