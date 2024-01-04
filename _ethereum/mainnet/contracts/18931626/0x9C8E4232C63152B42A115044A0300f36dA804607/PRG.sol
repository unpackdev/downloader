// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PRG Photography
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//     +-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+    //
//     |P|R|G| |P|h|o|t|o|g|r|a|p|h|y|    //
//     +-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+    //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract PRG is ERC1155Creator {
    constructor() ERC1155Creator("PRG Photography", "PRG") {}
}
