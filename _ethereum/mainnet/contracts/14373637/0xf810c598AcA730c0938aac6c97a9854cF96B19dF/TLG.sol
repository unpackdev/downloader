
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Last GigaByte
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//     +-++-++-+ +-++-++-++-+ +-++-++-++-++-++-++-++-+    //
//     |T||h||e| |L||a||s||t| |G||i||g||a||b||y||t||e|    //
//     +-++-++-+ +-++-++-++-+ +-++-++-++-++-++-++-++-+    //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract TLG is ERC721Creator {
    constructor() ERC721Creator("The Last GigaByte", "TLG") {}
}
