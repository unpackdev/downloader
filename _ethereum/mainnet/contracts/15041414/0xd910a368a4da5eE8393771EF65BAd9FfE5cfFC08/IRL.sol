
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kmart IRL editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    see you again soon -kmart    //
//                                 //
//                                 //
/////////////////////////////////////


contract IRL is ERC721Creator {
    constructor() ERC721Creator("kmart IRL editions", "IRL") {}
}
