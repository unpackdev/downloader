// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rimeo YamiKawa Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//     ____   ____  ___ ___    ___   ___          //
//    |    \ |    ||   |   |  /  _] /   \         //
//    |  D  ) |  | | _   _ | /  [_ |     |        //
//    |    /  |  | |  \_/  ||    _]|  O  |        //
//    |    \  |  | |   |   ||   [_ |     |        //
//    |  .  \ |  | |   |   ||     ||     |        //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract RYC is ERC721Creator {
    constructor() ERC721Creator("Rimeo YamiKawa Collection", "RYC") {}
}
