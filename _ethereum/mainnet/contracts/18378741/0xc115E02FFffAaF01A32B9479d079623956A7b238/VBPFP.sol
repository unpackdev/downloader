// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VB-PFP
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    VB PFP    //
//              //
//              //
//////////////////


contract VBPFP is ERC721Creator {
    constructor() ERC721Creator("VB-PFP", "VBPFP") {}
}
