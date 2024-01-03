// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Goat AJT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//    The GOAT is at it again. Causing mischief on the blockchain. Time to respect the respected.    //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract AJT is ERC721Creator {
    constructor() ERC721Creator("The Goat AJT", "AJT") {}
}
