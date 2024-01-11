
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: https://EthereumNetwork.org
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    Welcome To The CPU Show - https://EthereumNetwork.org    //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract ETHNET is ERC721Creator {
    constructor() ERC721Creator("https://EthereumNetwork.org", "ETHNET") {}
}
