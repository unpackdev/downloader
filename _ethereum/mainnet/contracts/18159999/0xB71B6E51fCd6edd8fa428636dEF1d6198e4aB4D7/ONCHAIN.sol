// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: On Chain
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    on chain    //
//                //
//                //
////////////////////


contract ONCHAIN is ERC721Creator {
    constructor() ERC721Creator("On Chain", "ONCHAIN") {}
}
