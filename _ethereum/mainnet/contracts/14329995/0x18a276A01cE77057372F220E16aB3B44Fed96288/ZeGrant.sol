
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ZendettaGrant
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//     ,__, _,,  ,  ,_   _, ___,___,_        _,  ,_  _   ,  , ___,                                                                                                       //
//       / /_,|\ |  | \,/_,' | ' | '|\      / _  |_)'|\  |\ |' |                                                                                                         //
//      /_'\_ |'\| _|_/'\_   |   |  |-\    '\_|`'| \ |-\ |'\|  |                                                                                                         //
//     '  `  `'  `'       `  '   '  '  `     _|  '  `'  `'  `  '                                                                                                         //
//     __, _, ,_      _, ,  ,,_   ___,_   , ',    _, ___,  ,  ,_   _,,  , ___,_,                                                                                         //
//    '|_,/ \,|_)    (_, \_/ |_) ' | '|\  |\ |   (_,' | |  |  | \,/_,|\ |' | (_,                                                                                         //
//     | '\_/'| \     _), /`'| \  _|_,|-\ |'\|    _)  |'\__| _|_/'\_ |'\|  |  _)                                                                                         //
//     '  '   '  `   ' (_/   '  `'    '  `'  `   '    '    `'       `'  `  ' '                                                                                           //
//                                                                                                                                                                       //
//    Website: https://Zendetta.com                                                                                                                                      //
//                                                                                                                                                                       //
//    In commemoration of the anniversary of the Syrian Revolution, Zendetta would like to launch an initiative;                                                         //
//    helping to support 100 Syrians who do not have the financial means to pay for their university applications                                                        //
//    (up to $100 per application) or to pay for their Foreign Language proficiency tests fees (up to 250$ per applicant).                                               //
//                                                                                                                                                                       //
//    The Zendetta Grant seeks to assist Syrians with their university applications acknowledging that education is crucial                                              //
//    for the creation of the Syrian future, which has to be aided by well-educated and passionate individuals; I believe that passion is best fostered by education.    //
//                                                                                                                                                                       //
//    We will hold an NFT auction for the artworks and photos on the website on Opensea to fund this initiative.                                                         //
//    The auction will start on the 15th of March and close on the 25th of April.                                                                                        //
//                                                                                                                                                                       //
//    The full proceedings of the auction will be dedicated to covering this grant's receivers application fees,                                                         //
//    foreign language proficiency tests, and consultancy fees.                                                                                                          //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZeGrant is ERC721Creator {
    constructor() ERC721Creator("ZendettaGrant", "ZeGrant") {}
}
