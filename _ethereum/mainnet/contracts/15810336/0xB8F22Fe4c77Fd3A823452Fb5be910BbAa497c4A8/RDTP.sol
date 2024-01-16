
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: L'enfance - A la recherche du temps perdu
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//                                        The Childhood - In search of Lost Time                                    //
//                                   (orig. L'enfance - A la recherche du temps perdu)                              //
//                                                                                                                  //
//                       It was originally a 3 pieces collection of computer-generated sculptures,                  //
//                       reflections to “In Search of Lost Time” ( A la recherche du temps perdu),                  //
//                       a novel in seven volumes by French author Marcel Proust.                                   //
//                       Most specifically the Madeleine moment.                                                    //
//                                                                                                                  //
//                       They are simple, graphical, banal, half-real, and probably half-rewritten                  //
//                       memories of my childhood. They are places, sounds, emotions, visuals;                      //
//                       sometimes so specific, sometimes a memory of fiction blended with reality,                 //
//                       and sometimes both.                                                                        //
//                                                                                                                  //
//                       1) The Bird, Snail and Salt (L’oiseau, l’escargot et le sel)                               //
//                       2) When we were playing (Quand on jouait)                                                  //
//                       3) G.A.T.A. and asthma (G.A.T.A. et l’asthme)                                              //
//                       The third piece was never finished because I never found the                               //
//                       mental courage to continue working on it.                                                  //
//                                                                                                                  //
//                       | France | 2012 |                                                                          //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                      [████████████████████████████████████████████████████████████████████████]                  //
//                      [████████████████████████████████████████████████████████████████████████]                  //
//                      [████████████████████████████████████████████████████████████████████████]                  //
//                                                                                         [█████]                  //
//                      [██████████████]     [█████████████████]       [█████████████]     [█████]                  //
//                      [██████████████]     [█████████████████]       [█████████████]     [█████]                  //
//                      [██████████████]      [███████████████]        [█████████████]     [█████]                  //
//                      [██████████████]       [█████████████]         [█████████████]     [█████]                  //
//                      [██████████████]        [███████████]          [█████████████]     [█████]                  //
//                      [██████████████]         [█████████]           [█████████████]     [█████]                  //
//                       [███████████]            [███████]             [███████████]      [█████]                  //
//                        [█████████]               [███]                [█████████]       [█████]                  //
//                           [███]                    █                     [███]          [█████]                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                      Multidisciplinary artist.                                                                   //
//                      Studied a mix of classical and digital arts and worked as a 3D Artist for                   //
//                      18 years.                                                                                   //
//                      Enjoys photography very much.                                                               //
//                                                                                                                  //
//                      © 2022 Umut UYDAS aka umutusu. All rights reserved                                          //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RDTP is ERC721Creator {
    constructor() ERC721Creator("L'enfance - A la recherche du temps perdu", "RDTP") {}
}
