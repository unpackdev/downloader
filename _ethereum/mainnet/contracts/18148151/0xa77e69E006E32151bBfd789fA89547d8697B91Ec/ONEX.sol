// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Onchain Experiments
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////
//          //
//          //
//    💩    //
//          //
//          //
//////////////


contract ONEX is ERC1155Creator {
    constructor() ERC1155Creator("Onchain Experiments", "ONEX") {}
}
