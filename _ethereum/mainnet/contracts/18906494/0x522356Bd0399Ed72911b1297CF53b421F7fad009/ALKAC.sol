// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alke's Anniversary Collection
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbqÇÇbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb«q▄gg0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb▀▒@▐▌╝╝bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdd▒B▒»bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb╝▀█▐▌»bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb    //
//        bbbbbbbbbÇÇ»▄▄@██@@gpÇbbbbbbbbbbbbbbû▐▌█bbbbbbbbbbbbbbbbbbqÇ[▄@██@@gqÇpÇbbbbbbbb    //
//        bbbbbbb«bq▄██████████▄p«bbbbbbbbbbbbÅÄ▒Ñ▌kpbbbbbbbbbbbbb»k▄@█████████@▄»h╝bbbbbb    //
//        bbbbbCÄ0▄██████████████g»Çbbbbbbbbbbbbd█▒8hbbbbbbbbbbbb5▄██████████████@▄╝bbbbbb    //
//        bbbbbá▄██████████████████▄hàbbbbbbbbbbû▒▐▌bbbbbbbbbbbd»▒█████████████████▌Vbbbbb    //
//        bbbdX▐████████████████████▌èbbbbbbbbbbÇ█Ç▌hbbbbbbbbbb▄█████████████████████pÇbbb    //
//        bbbh▐███████████████████████▄@▄@@½▀▐█W▀▐╣▀WM▓▀▀@@ææ▄▄███████████████████████╝bbb    //
//        bbbdú▒████████████████████▀▀V▀▐@WW▀▀4pù▐╢µV╜▀▀WHæ@▀V╜▀▓████████████████████▌0bbb    //
//        bbbbwÇ▀████████████████▀▀ùpqq#▀╜ôpppppV▐╪qVppppô╜▀M▄wXp╜▀▒███████████████▓ûbbbbb    //
//        bbbbb4╝«▀████████████▓▀XpqVq▌╜╜╜ppppppü▐▌╜ppppppp╜V▐▌üppqX▐████████████▀╨╝Cbbbbb    //
//        bbbbbbb╝b╝0▀▀@██████▌Vpppqq▓Akpppppppp4d▌kkpppppppp4▐▌kpp╜X▀███████Ñ▀╨╝╝╨bbbbbbb    //
//        bbbbbbbbbbbbbb5«▀▀▒▌Vppqµq▐▄▄████@▄qppVqppppµ▄▄████@▄½pppppp▀▒▀▀▀5bbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbb«h█▀Vppqü▐██████████Xpq▐▌Vpp▐██████████µVpppV▒phbbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbbV▐▌ôkppq▐███████████╜pwd╪kAp▒███████████Vpppô▀▌hbbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbbÅ▒▌▌pppq▐███████████kpüq╢üpp▐███████████ppppq▌█╝bbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbbd█U█pppüd▀█████████▀XpV▐▌4kpk▀████████▓▌ApqV▒▌▒▌bbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbbd█ü██ppµ▐▌k╜▀▀▀▀▀µXppp4▐▌üXppôù▀▀▀▀▀5V▀▌kqw▐█b▐▌bbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbbd█p▐██▄▄▀▌ppppppppppppAdpµkppppppppppV▐▌A▄██▌╜▐▌bbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbbè▒▌k▐█████▄╜4╜╜╜╜╜╜╜╜╜ü▐╢╩╜╜╜╜╜╜╜╜╜V4[▄█████╜q▒▀bbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbbÄ▀█▄k▐███████▄▄▄▄qwööö╫▐▌[nöön╧ô▄▄▄███████▓Z[▐▌╝bbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbb╝╝6M▄▀▀▓█████████████████████████████████▀▀▄@▀wbbbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbbbbd╝▒▌▀▀▀▀████████████████████████████▀▀▀ò▄█▀µébbbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbbbb«»▄@███▄▀ò▐▌▀▀████████████████████▓▀▄▌2▀[▐███▄h6pbbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbbb»w▄@██████▄▄3▐n▀▀▀▀▀▀▀▀██████▀▀▀▀▀▀▀3ÿg▀3▄@██████▄dÄbbbbbbbbbbbbbb    //
//        bbbbbbbbbbbbb«▄@██████████▄▄Å▄╦3ffff╞ffd╜ufffffffx▄ƒ▄▄@██████████▄d»bbbbbbbbbbbb    //
//        bbbbbbbbbbb╝Ç@██████████████@½▄fffffffT▄FYfffffff▄@æ███████████████▄bbbbbbbbbbbb    //
//        bbbbbbbbb⌂q▐█████████████████▀▀M▄⌡L⌡⌡TJJL⌡LT⌡⌠T▄@▀▀▀████████████████@╝qpbbbbbbbb    //
//        bbbbbbbbbÅ▐████████████████▀Ä╝bÄ«▀M▄LçTJ╡zJz▄æ▀╝»⌂bÄb▓██████████████▒█µ╨bbbbbbbb    //
//        bbbbbbbäq▒███████████████▌0Xbbbbb0╨▀W▄⌡u╡Y▄#▀dbbbbbbb╝▀▒███████████████gÄÄbbbbbb    //
//        bbbbbbbÇ▀▀▀▀▀╨CÅ▐██████▌╝6bbbbbbbbd»╝»Wæ%╣▀5bbbbbbbbbbbb▀██████▓▀Ä╨▀▀▀▀▀╝hbbbbbb    //
//        bbbbbbb╝b«0bbb0╝ûd▒███▀Vbbbbbbbbbbbb⌂╝0⌂b0⌂bbbbbbbbbbbbb60▒███▀àbbbbbdb╝Å0bbbbbb    //
//        bbbbbbbbbbbbbbbbbb«▀▀Åbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbw▀▀»dbbbbbbbbbbbbbbbbb    //
//                                                                                            //
//    ---                                                                                     //
//    asciiart.club                                                                           //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract ALKAC is ERC1155Creator {
    constructor() ERC1155Creator("Alke's Anniversary Collection", "ALKAC") {}
}
