
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BRAINTOADZ
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    MFN TOADZ    //
//                 //
//                 //
/////////////////////


contract TOADZ is ERC721Creator {
    constructor() ERC721Creator("BRAINTOADZ", "TOADZ") {}
}
