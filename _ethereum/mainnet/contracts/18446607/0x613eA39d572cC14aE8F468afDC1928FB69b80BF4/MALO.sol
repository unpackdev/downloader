// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ONCHAIN MINIMALISM
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//     __    __     ______     __         ______        //
//    /\ "-./  \   /\  __ \   /\ \       /\  __ \       //
//    \ \ \-./\ \  \ \  __ \  \ \ \____  \ \ \/\ \      //
//     \ \_\ \ \_\  \ \_\ \_\  \ \_____\  \ \_____\     //
//      \/_/  \/_/   \/_/\/_/   \/_____/   \/_____/     //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract MALO is ERC721Creator {
    constructor() ERC721Creator("ONCHAIN MINIMALISM", "MALO") {}
}
