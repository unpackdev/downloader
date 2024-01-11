
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art works by AlexCocoPro
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//                                             *                                                 //
//                                           ,*                                                  //
//                 .@    @(               @  /                                                   //
//                 @*%%%%% @            @ %                                                      //
//                 @ %%%%%%*(&        @ %/(                                                      //
//                  @ %%%%%%% @     @ %% &                                                       //
//                   .@ %%%%%%(/@ @ %%%                                                          //
//                     @ %%%%%%%  %%%,@                                                          //
//                       @ %%%%%%%%% @                                                           //
//                        @.%%%%%%%% @                                                           //
//                        @# %%%%%%%% @/                                                         //
//                      /@ %%%%%%%%%%%% @                                                        //
//                     @ %%%%%% &,%%%%%% @(                                                      //
//                   @ %%%%%%,&  @ %%%%%%% @                                                     //
//                 @ %%%%%%% @    #& %%%%%%.@/                                                   //
//                @ %%%%%%%,#       @ %%%%%%%((                                                  //
//                @ %%%%% @          (@ %%%%%,@                                                  //
//                 #@.  @*             &@. (@,                                                   //
//                                                                                               //
//    Smart contract of the artistic works by Alex Jesús Cabello Leiva, known as AlexCocoPro.    //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract AlexCocoPro is ERC721Creator {
    constructor() ERC721Creator("Art works by AlexCocoPro", "AlexCocoPro") {}
}
