
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Prisms
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//        ____  ____  _________ __  ________    //
//       / __ \/ __ \/  _/ ___//  |/  / ___/    //
//      / /_/ / /_/ // / \__ \/ /|_/ /\__ \     //
//     / ____/ _, _// / ___/ / /  / /___/ /     //
//    /_/   /_/ |_/___//____/_/  /_//____/      //
//                                              //
//       By Sarah Zucker / @thesarahshow        //
//                    2022–                     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract prsm is ERC721Creator {
    constructor() ERC721Creator("Prisms", "prsm") {}
}
