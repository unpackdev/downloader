
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FRAGMENTS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//      ...',,,,,,,,,,,,'';c;'.                                                                      .';c:'',,,,,,,,,,,,'...      //
//     ,;,''''''''''''''.'dWMNKkoc'.                                                            .':okKNWWd'.'''''''''''''',;,.    //
//    ;lc:,''''''''''''''.:KMMMMMMNKxl,.                                                    .,lxKNMMMMMMK:.'''''''''''''',:cl:    //
//    lccll:;''''''''''''''lXMMMMMMMMMWKx:.                                              .:d0WMMMMMMMMMXo'''''''''''''';:llccl    //
//    occccclc:,''''''''''''lKWMMMMMMMMMMMXkc.                                        .ckXMMMMMMMMMMMMKl'''''''''''',:clccccco    //
//    lcccccccllc;,'''''''''';xXWMMMMMMMMMMMMXk:.                                  .:kXMMMMMMMMMMMMWXx:'''''''''',;cllcccccccl    //
//    :lccccccccclc:;,''''''''';okKNWMMMMMMWNX0x:'.                              .':dOKNWMMMMMMWNKko;''''''''',;:clccccccccclc    //
//    'lcccccccccccclc:;,''''''''',:looddool:;''.',,.                          .','.'',:looddool:,''''''''',;:clccccccccccccl'    //
//     ;lccccccccccccccllc:;''''''''''.....''''''''',,.                      .,,''''''''''....'''''''''';:cclccccccccccccccl;     //
//     .:lccccccccccccccccllc:;,'''''''''''''''''''''',,.                  .,,'''''''''''''''''''''',;:cllccccccccccccccccl:.     //
//      .clcccccccccccccccccccllc::;,''''''''''''''''''','.              .',''''''''''''''''''',;::cllccccccccccccccccccclc.      //
//       .clccccccccccccccccccccccllcc::;,,''''''''''''''',.            .,,'''''''''''''',,;::ccllcccccccccccccccccccccclc.       //
//        .:lcccccccccccccccccccccccccclllcc::::;;;;;;;;:;;;'          ';;;:;;;;;;;;::::cclllcccccccccccccccccccccccccclc.        //
//         .:lccccccccccccccccccccccccccccccccclllllol:;'.. .'        .. ..';:lolllllcccccccccccccccccccccccccccccccccl:.         //
//           ;lcccccccccccccccccccccccccccccccccclc;'.     .'c;      ;c'.     .';clccccccccccccccccccccccccccccccccccl;           //
//            .clccccccccccccccccccccccccccccccl:'.    .:dOKNWX:    ;KWNKOd:.    .':lcccccccccccccccccccccccccccccclc'            //
//             .;lccccccccccccccccccccccccccclc'     ,dXWMMMMMM0'  .OMMMMMMWXx,     'clcccccccccccccccccccccccccccl;.             //
//               .:lccccccccccccccccccccccclc,.    .dNMMMMMMMMMWo. lWMMMMMMMMMNd.    .,clcccccccccccccccccccccccl:.               //
//                 .:lccccccccccccccccccccl:.     .kWMMMMMMMMMMWk::kWMMMMMMMMMMWO'     .:lccccccccccccccccccccl:.                 //
//                   .;clccccccccccccccclc,      .xWMMMMMMMMWXkddddddkXWMMMMMMMMMk.      ,clccccccccccccccclc;.                   //
//                     .':clcccccccccccl;.       :NMMMMMMMMW0occoxxocco0WMMMMMMMMNc       .;llcccccccccclc:,.                     //
//                        .';cllcccclc;.         oMMMMMMMMMNdccclddlcccdXMMMMMMMMMd         .;clccccllc;'.                        //
//                            .,clll:'           lWMMMMMMMMNxccclxxocccxNMMMMMMMMWo           ':lllc,.                            //
//                           ..',,',,,''.        ,KMMMMMMMMMXxlclxxoclxXMMMMMMMMMK,        ..',,,',,'..                           //
//                         .',,''''''''',,'.      cXMMMMMMMMMWKOdccdOKWMMMMMMMMMXc      .',,''''''''',,'.                         //
//                       .,,''''''''''''''','.     ;0WMMMMMMMMMMd..dMMMMMMMMMMW0;     .',''''''''''''''',,.                       //
//                      ',''''''''''''''''''',,.    .c0WMMMMMMMX;  ,KMMMMMMMW0l.    .,,''''''''''''''''''','                      //
//                     ','''''''''''''''''''''',,'.   .,oOXWMMWo    oWMMWXOo;.   ..,,'''''''''''''''''''''',,                     //
//                    ';''''''''''''''''''''''''',,'..    .;cxd.    .oxc;.     .',,''''''''''''''''''''''''';'                    //
//                   .;''''''''''''''''''''''''''''',,'..    ..      .'    ..',,''''''''''''''''''''''''''''';.                   //
//                   .;''''''''''''''''''''''''''',,;;:ccc::;.        .;::ccc:;;,,''''''''''''''''''''''''''';'                   //
//                   ';.'''''''''''''''''''',,;::cccllllcccc.          .ccccllllccc::;;,''''''''''''''''''''.;'                   //
//                   ';''''''''''''''''',;::cllccccccccccl:.            .:lccccccccccllc::;,''''''''''''''''.;'                   //
//                   .;''''''''''''',;:cclccccccccccccccl;.              .;lcccccccccccccclcc:;,''''''''''''';.                   //
//                   .,,.'''''''',:cclcccccccccccccccccc,                  ,cccccccccccccccccclcc:,''''''''.,,.                   //
//                    .;'''''',:cclcccccccccclooolcccl:.                    .:lccclooolccccccccccclc:,'''''';.                    //
//                     ';''';:clcccccccccldOKXNNNXKOo,                        ,oOKXNNNXKOdlccccccccccc:;''';'                     //
//                      ';;clcccccccccccd0WMMMMMMMNx'                          .xNMMMMMMMWKdccccccccccclc;;'                      //
//                       'llcccccccccccdXMMMMMMMWO;                              ;OWMMMMMMMXxcccccccccccll,                       //
//                        .:lcccccccccoKMMMMMMW0c.                                .c0WMMMMMMKocccccccccl:.                        //
//                         .:lccccccccdXMMMMMKl.                                    .lKWMMMMNdccccccccl:.                         //
//                          .clcccccccdXMMMKo.                                        .lKWMMNdccccccccc.                          //
//                           :lcccccccoKWKo.                                            .lKWKocccccccl:.                          //
//                           ;lcccccccldl.                                                .cdlcccccccl:                           //
//                          .:lcccccl:'.                                                    .':lccccclc.                          //
//                          'lccccc:.                                                          .;cccccl,                          //
//                         .clclc;.                                                              .;clclc.                         //
//                         ,lc:,.                                                                  .,:cl,                         //
//                         ;o;.                                                                      .;o;                         //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                          _       _                 _   _        _          _                                   //
//                                         /\ \    / /\              /\_\/\_\ _   /\ \       / /\                                 //
//                                         \ \ \  / /  \            / / / / //\_\/  \ \     / /  \                                //
//                                         /\ \_\/ / /\ \          /\ \/ \ \/ / / /\ \ \   / / /\ \__                             //
//                                        / /\/_/ / /\ \ \        /  \____\__/ / / /\ \_\ / / /\ \___\                            //
//                               _       / / / / / /  \ \ \      / /\/________/ /_/_ \/_/ \ \ \ \/___/                            //
//                              /\ \    / / / / / /___/ /\ \    / / /\/_// / / /____/\     \ \ \                                  //
//                              \ \_\  / / / / / /_____/ /\ \  / / /    / / / /\____\/ _    \ \ \                                 //
//                              / / /_/ / / / /_________/\ \ \/ / /    / / / / /______/_/\__/ / /                                 //
//                             / / /__\/ / / / /_       __\ \_\/_/    / / / / /_______\ \/___/ /                                  //
//                             \/_______/  \_\___\     /____/_/       \/_/\/__________/\_____\/                                   //
//                                           _       _           _                  _                                             //
//                                          /\ \    /\ \        / /\               /\ \     _                                     //
//                                          \ \ \  /  \ \      / /  \             /  \ \   /\_\                                   //
//                                          /\ \_\/ /\ \ \    / / /\ \           / /\ \ \_/ / /                                   //
//                                         / /\/_/ / /\ \_\  / / /\ \ \         / / /\ \___/ /                                    //
//                                _       / / / / /_/_ \/_/ / / /  \ \ \       / / /  \/____/                                     //
//                               /\ \    / / / / /____/\   / / /___/ /\ \     / / /    / / /                                      //
//                               \ \_\  / / / / /\____\/  / / /_____/ /\ \   / / /    / / /                                       //
//                               / / /_/ / / / / /______ / /_________/\ \ \ / / /    / / /                                        //
//                              / / /__\/ / / / /_______/ / /_       __\ \_/ / /    / / /                                         //
//                              \/_______/  \/__________\_\___\     /____/_\/_/     \/_/                                          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FRGMT is ERC721Creator {
    constructor() ERC721Creator("FRAGMENTS", "FRGMT") {}
}
