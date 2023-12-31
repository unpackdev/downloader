// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test NFT for livepeer tokengate
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    This is a test smart contract for livepeer tokengate.    //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract TSTLIVEPEER is ERC1155Creator {
    constructor() ERC1155Creator("test NFT for livepeer tokengate", "TSTLIVEPEER") {}
}
