
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Luminous
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//      _                 _                           //
//     | |               (_)                          //
//     | |_   _ _ __ ___  _ _ __   ___  _   _ ___     //
//     | | | | | '_ ` _ \| | '_ \ / _ \| | | / __|    //
//     | | |_| | | | | | | | | | | (_) | |_| \__ \    //
//     |_|\__,_|_| |_| |_|_|_| |_|\___/ \__,_|___/    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract LMNS is ERC721Creator {
    constructor() ERC721Creator("Luminous", "LMNS") {}
}
