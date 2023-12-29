// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hayashi's Open Edition
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    Illustration works made by Hayashi, from Taiwan.    //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract HOEW is ERC721Creator {
    constructor() ERC721Creator("Hayashi's Open Edition", "HOEW") {}
}
