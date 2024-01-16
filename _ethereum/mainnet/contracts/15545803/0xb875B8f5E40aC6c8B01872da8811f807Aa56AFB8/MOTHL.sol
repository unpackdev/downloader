
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mother
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//        __  ___      __  __                 //
//       /  |/  /___  / /_/ /_  ___  _____    //
//      / /|_/ / __ \/ __/ __ \/ _ \/ ___/    //
//     / /  / / /_/ / /_/ / / /  __/ /        //
//    /_/  /_/\____/\__/_/ /_/\___/_/         //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract MOTHL is ERC721Creator {
    constructor() ERC721Creator("Mother", "MOTHL") {}
}
