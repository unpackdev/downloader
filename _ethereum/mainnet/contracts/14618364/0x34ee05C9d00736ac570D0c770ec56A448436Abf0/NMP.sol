
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nooners Melting Pot
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//     __    __     ______     __         ______      //
//    /\ "-./  \   /\  ___\   /\ \       /\__  _\     //
//    \ \ \-./\ \  \ \  __\   \ \ \____  \/_/\ \/     //
//     \ \_\ \ \_\  \ \_____\  \ \_____\    \ \_\     //
//      \/_/  \/_/   \/_____/   \/_____/     \/_/     //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract NMP is ERC721Creator {
    constructor() ERC721Creator("Nooners Melting Pot", "NMP") {}
}
