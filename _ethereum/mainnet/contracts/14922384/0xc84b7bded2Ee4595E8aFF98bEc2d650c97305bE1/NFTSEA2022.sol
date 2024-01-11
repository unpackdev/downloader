
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blockparty x NFTSEA 2022
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//                                                //
//     _      _____ _____  ____  _____ ____       //
//    / \  /|/    //__ __\/ ___\/  __//  _ \      //
//    | |\ |||  __\  / \  |    \|  \  | / \|      //
//    | | \||| |     | |  \___ ||  /_ | |-||      //
//    \_/  \|\_/     \_/  \____/\____\\_/ \|      //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract NFTSEA2022 is ERC721Creator {
    constructor() ERC721Creator("Blockparty x NFTSEA 2022", "NFTSEA2022") {}
}
