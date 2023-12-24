// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hybrids
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////
//               //
//               //
//    _m_e_l_    //
//               //
//               //
///////////////////


contract HY is ERC1155Creator {
    constructor() ERC1155Creator("Hybrids", "HY") {}
}
