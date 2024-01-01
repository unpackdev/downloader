// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wolf Nkole Helzle Editions by GRM
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//     +-+-+-+ +-+-+-+-+-+-+-+-+ +-+-+ +-+-+-+    //
//     |W|N|H| |E|d|i|t|i|o|n|s| |b|y| |G|R|M|    //
//     +-+-+-+ +-+-+-+-+-+-+-+-+ +-+-+ +-+-+-+    //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract GRMWNHE is ERC1155Creator {
    constructor() ERC1155Creator("Wolf Nkole Helzle Editions by GRM", "GRMWNHE") {}
}
