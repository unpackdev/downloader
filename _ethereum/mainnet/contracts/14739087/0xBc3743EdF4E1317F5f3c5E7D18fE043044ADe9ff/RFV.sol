
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RFV
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Risk-free value    //
//                       //
//                       //
///////////////////////////


contract RFV is ERC721Creator {
    constructor() ERC721Creator("RFV", "RFV") {}
}
