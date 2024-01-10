
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OGJefe
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    Jefe    //
//            //
//            //
////////////////


contract Jefe is ERC721Creator {
    constructor() ERC721Creator("OGJefe", "Jefe") {}
}
