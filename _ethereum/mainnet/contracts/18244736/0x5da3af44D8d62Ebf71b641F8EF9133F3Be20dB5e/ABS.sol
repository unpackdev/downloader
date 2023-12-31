// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Abstraction
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    Turn your Swirls into wonders...    //
//                                        //
//                                        //
////////////////////////////////////////////


contract ABS is ERC721Creator {
    constructor() ERC721Creator("Abstraction", "ABS") {}
}
