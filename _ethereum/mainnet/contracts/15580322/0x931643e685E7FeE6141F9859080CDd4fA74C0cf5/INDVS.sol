
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Indivisible
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//     _ __  _ __  _  _   _  _   __  _ __ _   ___      //
//    | |  \| | _\| || \ / || |/' _/| |  \ | | __|     //
//    | | | ' | v | |`\ V /'| |`._`.| | -< |_| _|      //
//    |_|_|\__|__/|_|  \_/  |_||___/|_|__/___|___|     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract INDVS is ERC721Creator {
    constructor() ERC721Creator("Indivisible", "INDVS") {}
}
