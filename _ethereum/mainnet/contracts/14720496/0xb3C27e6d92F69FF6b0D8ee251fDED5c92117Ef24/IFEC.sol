
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In Flight Entertainment Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    TAKE FLIGHT.         //
//                         //
//    WITH LOVE, ROLLER    //
//                         //
//                         //
/////////////////////////////


contract IFEC is ERC721Creator {
    constructor() ERC721Creator("In Flight Entertainment Collection", "IFEC") {}
}
