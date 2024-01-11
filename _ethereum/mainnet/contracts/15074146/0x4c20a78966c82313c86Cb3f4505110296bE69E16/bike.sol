
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: biker
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    prompts: A woodblock print of a biker by the sea,by R ockwell Kent, trending on artstaion.    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract bike is ERC721Creator {
    constructor() ERC721Creator("biker", "bike") {}
}
