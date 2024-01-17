
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: smolmei commission
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                   _           _     //
//      ____ __  ___| |_ __  ___(_)    //
//     (_-< '  \/ _ \ | '  \/ -_) |    //
//     /__/_|_|_\___/_|_|_|_\___|_|    //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract MEICMS is ERC721Creator {
    constructor() ERC721Creator("smolmei commission", "MEICMS") {}
}
