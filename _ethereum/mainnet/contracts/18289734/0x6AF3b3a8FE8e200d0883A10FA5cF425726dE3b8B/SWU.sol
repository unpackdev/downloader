// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: simizuwakakao_utopia_collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    simizuwakakao_utopia_collection    //
//                                       //
//                                       //
///////////////////////////////////////////


contract SWU is ERC721Creator {
    constructor() ERC721Creator("simizuwakakao_utopia_collection", "SWU") {}
}
