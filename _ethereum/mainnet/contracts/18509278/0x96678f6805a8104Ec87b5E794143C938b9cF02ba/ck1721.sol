// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CK1 DESIGNS 721
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    ck1-721 Have a Nice Day ( :    //
//                                   //
//                                   //
///////////////////////////////////////


contract ck1721 is ERC721Creator {
    constructor() ERC721Creator("CK1 DESIGNS 721", "ck1721") {}
}
