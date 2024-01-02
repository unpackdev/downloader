// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TESTA
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////
//               //
//               //
//    ANITEST    //
//               //
//               //
///////////////////


contract TESTA is ERC1155Creator {
    constructor() ERC1155Creator("TESTA", "TESTA") {}
}
