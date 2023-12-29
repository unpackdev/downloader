// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ackstract Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    offerings to the Muse    //
//                             //
//                             //
/////////////////////////////////


contract acked is ERC721Creator {
    constructor() ERC721Creator("Ackstract Editions", "acked") {}
}
