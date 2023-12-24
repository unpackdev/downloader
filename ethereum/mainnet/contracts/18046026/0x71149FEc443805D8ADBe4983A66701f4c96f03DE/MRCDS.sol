// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mercedes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//                                                //
//                                 |              //
//     _ _  ___  ___  ___  ___  ___| ___  ___     //
//    | | )|___)|   )|    |___)|   )|___)|___     //
//    |  / |__  |    |__  |__  |__/ |__   __/     //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract MRCDS is ERC721Creator {
    constructor() ERC721Creator("Mercedes", "MRCDS") {}
}
