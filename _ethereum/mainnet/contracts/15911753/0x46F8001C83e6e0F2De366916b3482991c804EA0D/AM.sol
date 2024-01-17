
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AMY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                      //
//                                                                                                      //
//    The token symbol will be displayed on Etherscan when others come to view your smart contract.     //
//                                                                                                      //
//                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AM is ERC721Creator {
    constructor() ERC721Creator("AMY", "AM") {}
}
