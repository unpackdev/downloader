
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: real CourtDog
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGSSSS    //
//    SSSS········································································SSSS    //
//    SSSS········································································SSSS    //
//    SSSS········································································SSSS    //
//    SSSS········································································SSSS    //
//    SSSS·····eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee·····SSSS    //
//    SSSS·····SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS·····SSSS    //
//    SSSS·····SSSSb·······GSSSSS·······PSSSSSSSSSb······PSSSSSSSb·······SSSS·····SSSS    //
//    SSSS·····SSb····ssp····SSSS··········QSSSSb··········)SSSb····ss····)SS·····SSSS    //
//    SSSS·····SS···sSSSSSp···SSS···········GSSb············)Sb···SSSSSQ···)S·····SSSS    //
//    SSSS·····SS···SSSSSSSSSSSSS···········)SSb············)Sb···SSSSSSSSSSS·····SSSS    //
//    SSSS·····SS···SSSSSSSSSSSSS···········)SSb············)Sb···SSSb·····)S·····SSSS    //
//    SSSS·····SS···)SSSSG···)SSS···········SSSQ············SSQ···GSSee····)S·····SSSS    //
//    SSSS·····SSQ··········)SSSS·········sSSSSSQ··········sSSSQ···········)S·····SSSS    //
//    SSSS·····SSSSQe····)eSSSSSS······sSSSSSSSSSSeQ····seSSSSSSSeQ····sp··)S·····SSSS    //
//    SSSS·····SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS·····SSSS    //
//    SSSS·····PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG·····SSSS    //
//    SSSS········································································SSSS    //
//    SSSS············eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeep···········SSSS    //
//    SSSS···········)SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSb···········SSSS    //
//    SSSS···········)SSSC····SSb··········SSb··········SSSSb······GSSb···········SSSS    //
//    SSSS···········)SQ······SSQssssssp···SSQssssss····SSS····sp···)Sb···········SSSS    //
//    SSSS···········)SSQqc···SSSSSSSSS···SSSSSSSSSS···SSSb···SSSSSSSSb···········SSSS    //
//    SSSS···········)SSSSb···SSSSSSSS···SSSSSSSSSb···SSSSb·······PSSSb···········SSSS    //
//    SSSS···········)SSSSb···SSSSSSb···SSSSSSSSSb···SSSSSb·········)Sb···········SSSS    //
//    SSSS···········)SSSSb···SSSSSb··)SSSSSSSSSb··)SSSSSSb··········Sb···········SSSS    //
//    SSSS···········)SSSSb···SSSSb··(SSSSSSSSSb··sSSSSSSSS·········sSb···········SSSS    //
//    SSSS···········)SSSSb···SSS···sSSSSSSSSS···SSSSSSSSSSSep····sSSSb···········SSSS    //
//    SSSS···········)SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSb···········SSSS    //
//    SSSS········································································SSSS    //
//    SSSS········································································SSSS    //
//    SSSS········································································SSSS    //
//    SSSS········································································SSSS    //
//    SSSSeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract RCD is ERC721Creator {
    constructor() ERC721Creator("real CourtDog", "RCD") {}
}
