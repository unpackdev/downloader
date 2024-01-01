// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fonts
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////
//         //
//         //
//    !    //
//         //
//         //
/////////////


contract FON is ERC1155Creator {
    constructor() ERC1155Creator("Fonts", "FON") {}
}
