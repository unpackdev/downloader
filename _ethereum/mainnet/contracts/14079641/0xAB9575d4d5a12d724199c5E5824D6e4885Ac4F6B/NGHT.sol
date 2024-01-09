
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nightwalkers
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//                                                    ☽           //
//                                                                //
//            __       ___                      ___  __   __      //
//    |\ | | / _` |__|  |  |  |  /\  |    |__/ |__  |__) /__`     //
//    | \| | \__> |  |  |  |/\| /~~\ |___ |  \ |___ |  \ .__/     //
//                                                                //
//                      Chung Huynh / 2022                        //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract NGHT is ERC721Creator {
    constructor() ERC721Creator("Nightwalkers", "NGHT") {}
}
