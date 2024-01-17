
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mainnet-test1 claim page
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    MainNet Angel trial claim page 1    //
//                                        //
//                                        //
////////////////////////////////////////////


contract MATC1 is ERC721Creator {
    constructor() ERC721Creator("Mainnet-test1 claim page", "MATC1") {}
}
