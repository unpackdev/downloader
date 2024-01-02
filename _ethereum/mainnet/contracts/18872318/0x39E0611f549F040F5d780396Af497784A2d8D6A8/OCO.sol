// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: On-Chain Odysseys
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    The art of exploration and the exploration of art.    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract OCO is ERC721Creator {
    constructor() ERC721Creator("On-Chain Odysseys", "OCO") {}
}
