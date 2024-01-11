
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Charades
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                //
//    Charades                                                                                                                                                                                                                                    //
//    A 1 /1 collection that is emergent from a deep rooted affinity for  word play  that exploits multiple meanings of a term. A daring attempt , seeking to represent absolute truths symbolically through language and metaphorical images.    //
//                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CRD is ERC721Creator {
    constructor() ERC721Creator("Charades", "CRD") {}
}
