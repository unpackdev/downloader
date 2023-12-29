// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Foundations of Creator Economy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//    This collection presents a model of the Creator Economy. It shows how nfts/ordinals can serve as a store of value. This allows for a better content model than the advertising revenue model that has dominated social media networks.    //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FIDE is ERC721Creator {
    constructor() ERC721Creator("Foundations of Creator Economy", "FIDE") {}
}
