
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EdurneNaia
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//    .___  .            .  .           //
//    [__  _|. .._.._  _ |\ | _.* _.    //
//    [___(_](_|[  [ )(/,| \|(_]|(_]    //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract EDN is ERC721Creator {
    constructor() ERC721Creator("EdurneNaia", "EDN") {}
}
