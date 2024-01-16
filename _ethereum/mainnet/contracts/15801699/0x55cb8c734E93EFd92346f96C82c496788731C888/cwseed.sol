
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoWagakki SEED for Mint
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    cwseed    //
//              //
//              //
//////////////////


contract cwseed is ERC721Creator {
    constructor() ERC721Creator("CryptoWagakki SEED for Mint", "cwseed") {}
}
