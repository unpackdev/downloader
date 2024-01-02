// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: United by the Impossible
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//      |  |      _)  |              |                        //
//      |  |   \   |   _|   -_)   _` |                        //
//     \|_/ _| _| _| \|_| \|__| \__,_|                        //
//       _ \  |  |     _|    \    -_)                         //
//     _.__/ \_, |   \__| _| _| \___|                         //
//     _ _|  ___/                       _)  |     |           //
//       |    ` \   _ \   _ \ (_-< (_-<  |   _ \  |   -_)     //
//     ___| _|_|_| .__/ \___/ ___/ ___/ _| _.__/ _| \___|     //
//                _|                                          //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract UI is ERC721Creator {
    constructor() ERC721Creator("United by the Impossible", "UI") {}
}
