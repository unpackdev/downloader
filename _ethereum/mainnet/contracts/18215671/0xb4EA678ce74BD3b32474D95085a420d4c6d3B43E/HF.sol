// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hoodfakas
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    Just 10,000 hoodfakas living in web3!    //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract HF is ERC721Creator {
    constructor() ERC721Creator("Hoodfakas", "HF") {}
}
