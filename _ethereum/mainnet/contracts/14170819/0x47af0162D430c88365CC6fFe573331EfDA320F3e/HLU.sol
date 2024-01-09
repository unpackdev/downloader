
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hello Universe
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    BankYu    //
//              //
//              //
//////////////////


contract HLU is ERC721Creator {
    constructor() ERC721Creator("Hello Universe", "HLU") {}
}
