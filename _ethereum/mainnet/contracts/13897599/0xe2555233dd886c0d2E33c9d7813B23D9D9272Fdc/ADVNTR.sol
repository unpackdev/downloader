
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Adventure
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//    ___       ___          __        ___      ___       __   ___     //
//     |  |__| |__      /\  |  \ \  / |__  |\ |  |  |  | |__) |__      //
//     |  |  | |___    /~~\ |__/  \/  |___ | \|  |  \__/ |  \ |___     //
//                                                                     //
//               photography from Adam & Heather Nagel                 //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract ADVNTR is ERC721Creator {
    constructor() ERC721Creator("The Adventure", "ADVNTR") {}
}
