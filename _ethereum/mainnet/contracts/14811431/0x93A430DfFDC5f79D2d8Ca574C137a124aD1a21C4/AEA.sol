
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ali Elena ART
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    Ali Elena ART own smart contract    //
//                                        //
//                                        //
////////////////////////////////////////////


contract AEA is ERC721Creator {
    constructor() ERC721Creator("Ali Elena ART", "AEA") {}
}
