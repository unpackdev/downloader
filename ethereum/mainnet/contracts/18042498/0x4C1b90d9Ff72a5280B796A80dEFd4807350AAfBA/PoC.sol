// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Proof of Cocktail
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                       o           o            //
//                          o   o                 //
//                             o         o        //
//                                                //
//                         o       o  o           //
//                      ________._____________    //
//                      |   .                |    //
//                      |^^^.^^^^^.^^^^^^.^^^|    //
//                      |     .   .   .      |    //
//                       \      . . . .     /     //
//    C H E E R S !!!      \     .  .     /       //
//                           \    ..    /         //
//                             \      /           //
//                               \  /             //
//                                \/              //
//                                ||              //
//                                ||              //
//                                ||              //
//                                ||              //
//                                ||              //
//                                /\              //
//                               /;;\             //
//                          ==============        //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract PoC is ERC721Creator {
    constructor() ERC721Creator("Proof of Cocktail", "PoC") {}
}
