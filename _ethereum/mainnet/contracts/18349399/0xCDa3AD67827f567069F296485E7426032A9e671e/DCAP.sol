// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DC Capital Partners
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////
//          //
//          //
//    🖕    //
//          //
//          //
//////////////


contract DCAP is ERC1155Creator {
    constructor() ERC1155Creator("DC Capital Partners", "DCAP") {}
}
