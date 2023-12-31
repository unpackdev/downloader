// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Night Entities
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//     @@@@@@@   @@@@@@  @@@      @@@@@@@@  @@@@@@     //
//     @@!  @@@ @@!  @@@ @@!           @@! @@!  @@@    //
//     @!@@!@!  @!@  !@! @!!         @!!   @!@!@!@!    //
//     !!:      !!:  !!! !!:       !!:     !!:  !!!    //
//      :        : :. :  : ::.: : :.::.: :  :   : :    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract NE is ERC721Creator {
    constructor() ERC721Creator("Night Entities", "NE") {}
}
