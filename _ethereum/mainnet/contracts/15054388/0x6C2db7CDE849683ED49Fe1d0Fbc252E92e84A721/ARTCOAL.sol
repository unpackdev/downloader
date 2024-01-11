
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art Coal
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//          __  ___     __   __                //
//     /\  |__)  |     /  ` /  \  /\  |        //
//    /~~\ |  \  |     \__, \__/ /~~\ |___     //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract ARTCOAL is ERC721Creator {
    constructor() ERC721Creator("Art Coal", "ARTCOAL") {}
}
