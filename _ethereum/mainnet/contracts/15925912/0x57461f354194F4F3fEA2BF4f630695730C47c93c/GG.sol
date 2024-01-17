
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: giuligartner
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                               @ GGG                                                                                                                                                                                         //
//                                            GGGGGGG  % @@                                                                                                                                                                                    //
//                                       /@@@@@GGGG      @ @ G                                                                               GGG                                                                                               //
//                                      @   @@@@@@@     @@%  G                                                                              @@GGGG                                                                                             //
//                                     @@   @@@@@@@    @@@     G.     G                                         GG                          @@@GG.@@@                                                                                          //
//                                    @@@@  @@@@@@@@  @@@@        @@@@@@                                 @@@@ @@@@@@ @@                    @@@@    @@@@                                                                                        //
//                                  @GGGGG@@@@@@@   GGGGG           @@@%  GG                #GG         @@@@@@@ @@@@@@%@@@     @. @@@  @%  @@@@@@       @@@@                                                                                   //
//                                @@ *@@GGG@@@     @@@@           @@@    GGG            @@@ GGGG      @@@@@@@@ @@@@@@.@@ @@  @@     %@@GGGGGGGG@@          GGG@@                                                                               //
//                               @@  @@GGG@@@      @@@@    GG      GG     GGG          @@@@      GGGG @@@@@@@@@ @@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          GGG@@                                                                          //
//                              @@  GGGGGGGGGG   @@.@@@@@  @@@@@@@@@@@@    GGGGGG     @@@ @@      GGGG   GGGGGGGGG  @@@@@@  @@@@@@@GGGGGGGGGGGGG@@@@@@@@@           GGG@@                                                                      //
//                             @   @@@@@@@@@  @@@GGGGGGGGGGGGGGG@@@@    @@@@@@@@    @ @@  @@   @@@@@     GGGGGGGG   @@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            GGGG@@                                                                 //
//                           @@   @@@@@@@@@@  @@@GGGGGGGGGGGGG@@@@@@    @@@@@@@@@@@@@@  @   @@ @@@@@       GGGGGGGGGGG   @@@@@@@@GGGGGGGGGGG@@@@@@@@@@@@@@@@@@@               GGG@@                                                            //
//                          @GGGGG@@@@@@ GGG  @@@@GGGGGGGGGGGGG@@@@     GGG @@@@@@@@@@@  @  @@@*@@@@@         %@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.         ,&GG@                                                        //
//                         @GGGGGGGGGGGGGGGG  @@@@@GGGGGGGG @@@@@@      GGGG    @@@@@@@@@@@@@@@ @@@@@          @@@@    &@@@@@@@@@@@@@@ GGGGGGGGGGGGGGG@@@@@@@@@@@GGGGGGGGGGGGGGGGGGGGGG                                                        //
//                          @GGGGGGGGGGGGG%   @@@@@GGGGG@@@@@         GG       @@@@@@@@@@@*  @@@@@        @@@@@@   @@@@@@@@@@@@@@@ GGGGGGGGGGGGGGGGGGGGGG@@@@@@@@@@@GGGGGGGGGGGGGGGGGGGGG@                                                     //
//                          @GGGGGGGGGGG.   (GGGGGGGGGGGG@@/          G       G  @@@@@@@@@  @@@@@@    @@@@@@GGGGGGGGGG@@@@@@@@@@@  GGGGGGGGGGGGGGGGGGGGG@@@@@@@@@@@GGGGGGGGGGGGGGGGGGGGGGGGG@                                                  //
//                         @@@GGGGGGGG@    GGGGGGGGGGG@@@@(          G      GG     GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG   GGGGGGGGGGGGGGGGGGGGGG@@@@@@@@@GGGGGGGGGGGGGGGGGGGGGGGGGGG@                                                 //
//                         @@GGGGGGGGGG@  GGGGGGGGGGGGGGGGGGGG       GG     GG       GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG   GGGGGGGGGGGGGGGGGGGGGGGGGGG@@@@@@@@@@@@@@@@@@@GGGGGGGGGGGGGG@                                               //
//                        @@GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG, GGG          GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG   GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG@@@@@@@@@@@GGGGGGGGGGGGGGGGGGG@@G                                           //
//                       @GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG             GGGGGGGGGGGGGGGG@@@@@@@@@@@GGGGGGGGGGGG    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG@@@@@@@@@@@@@@@@@@@@@@GGGGGGGGGG@@                                          //
//                                    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG           GGGGGGGGG@@@@@@@@@@@GGGGGGGGGGGGGGGGGG   GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG@@@@@@@@@@@GGGGGGGGGGGGGGGGGGGGG@                                        //
//                                             @GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG@@@@@@@@@@@GGGGGGGGGGGGGGG  GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GGGGG@@                                    //
//                                                      @GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG@@@@@@@@@@@GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG                                                                            //
//                                                               #GGGGGGGGGGGGGGGGGGGGGGGGMINTWITHINTENTIONGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGCGGGGGGGGGGGGGGGTGGGGG                                                                                //
//                                                                      *GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG                                                                                                      //
//                                                                               GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG                                                                                                             //
//                                                                                             GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG                                                                                                                //
//                                                                                                          ,GGGGGGGGGG                                                                                                                        //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GG is ERC721Creator {
    constructor() ERC721Creator("giuligartner", "GG") {}
}
