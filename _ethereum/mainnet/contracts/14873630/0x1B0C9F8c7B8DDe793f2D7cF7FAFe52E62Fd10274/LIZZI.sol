
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lizard Impression
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//                                                                                 ..                                      //
//                                                                             ..,:l'                                      //
//                                                                          .';cllll'                                      //
//                                                                       .,:lllllll:.                                      //
//                                                                     .;llllllc;'.                                        //
//                                                                     .:lll:,.                                            //
//                                                           .';:.     .;;'.                                               //
//                                                        .,:cllc'    .'.                                                  //
//                                                    .';clllllll,..;cl;.    .                                             //
//                                                 .,:loollllllllccllll;. .'::.                                            //
//                                             .';loooooollllllllllllllc;:lllc.  ..;.                                      //
//                                          .,coooooooooooooollllllllllllllll:'':cll'                                      //
//                                       .,coddooooooooooooooolllllllllllc;'..,lllll'                                      //
//                                      ,ldddddddooodddooooolllllllllllc'.    ,ll:,.                                       //
//                                    .:dddddddddooodddooolllllllllllll;      .'.        ..                                //
//                                   .:ddddddddddooodooooolllllllllllll;.  .',.       .';c:.                               //
//                                   ,dddddxxdddddoooooooollllllllllllc;',:llc.     .;llll:.                               //
//                                  .cddddxxxdddddooooooooollllllll:;'..:llllc.     .clllc'                                //
//                                  .lddddxxxdddddooooooooollllll;.    .:lc:,.      .::,.                                  //
//                                  .cdddddxxdddddooooooooollllll'     .''.          .                                     //
//                                   ;ddoodxxdddddoooooooooolllll'  ..,,                                                   //
//                                   .cdooodddddddoooooolloolllll;';cll;.                                                  //
//                                    .cooooodddddooooollloolllllllllll;                                                   //
//                                     .;oooooooooooooolllllllllllllc;'.                                                   //
//                                       .:loollloooollllllllllcc:,..                                                      //
//                                         .,:llolllllllllllc;'..                                                          //
//                                            ..',;;;;;;,''.                                                               //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//     ____    ____  ________  _________  ________    ___   _______        _____          _       ______     ______        //
//    |_   \  /   _||_   __  ||  _   _  ||_   __  | .'   `.|_   __ \      |_   _|        / \     |_   _ \  .' ____ \       //
//      |   \/   |    | |_ \_||_/ | | \_|  | |_ \_|/  .-.  \ | |__) |       | |         / _ \      | |_) | | (___ \_|      //
//      | |\  /| |    |  _| _     | |      |  _| _ | |   | | |  __ /        | |   _    / ___ \     |  __'.  _.____`.       //
//     _| |_\/_| |_  _| |__/ |   _| |_    _| |__/ |\  `-'  /_| |  \ \_     _| |__/ | _/ /   \ \_  _| |__) || \____) |      //
//    |_____||_____||________|  |_____|  |________| `.___.'|____| |___|   |________||____| |____||_______/  \______.'      //
//                                                                                                                         //
//                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LIZZI is ERC721Creator {
    constructor() ERC721Creator("Lizard Impression", "LIZZI") {}
}
