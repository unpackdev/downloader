// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Illusions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//      _____ _ _           _                     //
//     |_   _| | |         (_)                    //
//       | | | | |_   _ ___ _  ___  _ __  ___     //
//       | | | | | | | / __| |/ _ \| '_ \/ __|    //
//      _| |_| | | |_| \__ \ | (_) | | | \__ \    //
//     |_____|_|_|\__,_|___/_|\___/|_| |_|___/    //
//                                                //
//                                                //
//    by ToadTec                                  //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract ILL is ERC721Creator {
    constructor() ERC721Creator("Illusions", "ILL") {}
}
