
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PRIMES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    we're gonna shake up the art world    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract AVP is ERC721Creator {
    constructor() ERC721Creator("PRIMES", "AVP") {}
}
