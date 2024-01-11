
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SuperAnimationShow
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    /// Super Animation Show ///    //
//                                    //
//                                    //
////////////////////////////////////////


contract SAS is ERC721Creator {
    constructor() ERC721Creator("SuperAnimationShow", "SAS") {}
}
