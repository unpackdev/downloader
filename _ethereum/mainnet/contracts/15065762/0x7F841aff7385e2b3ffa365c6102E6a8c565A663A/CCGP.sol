
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CurioCity Grand Prize
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    CurioCity Grand Prize 1 of 1    //
//                                    //
//                                    //
////////////////////////////////////////


contract CCGP is ERC721Creator {
    constructor() ERC721Creator("CurioCity Grand Prize", "CCGP") {}
}
