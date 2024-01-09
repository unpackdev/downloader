
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Habibi Community Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//                                                                                    ,g@@@@@@@@@gg,              //
//                                                                                ,g@@@@@@@@@@@@@@@@@bc           //
//                                                                              ,@@@@@@@@NMMMMMMB@@@@@@@          //
//                                      ,,gg@@@@Nw,    ;gggggggggg;   ;,gggg,, g@@@@@@M|lllllllll||@@@@@@         //
//                               ;gg@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@M|lllllllllllll|@@@@@K        //
//                           ,g@@@@@@@@@@@@@@NMN@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|llllllllllllllll]@@@@@        //
//                  ,,ggggg,@@@@@@@@@NMT|||lllll|]@@@@@@W||||||||j@@@@@@||||]@@@@@Mlllllllll|@@lllll]@@@@@        //
//               ,@@@@@@@@@@@@@@@M||lllllllllllll]@@@@@@Wllllllllj@@@@@@llll]@@@@@lllllllll]@@@Wllll@@@@@[        //
//              ,@@@@@@@@@@@@@@K|llllllll||ggllll]@@@@@@Wllllllllj@@@@@@llll]@@@@|llllllllj@@@@llllj@@@@@-        //
//            ,g@@@@@@||ll]@@@@|llllllll@@@@@llllj@@@@@@Wllllllllj@@@@@@llll|@@@@g||llllll@@@@@llll$@@@@@g        //
//          g@@@@@@@@@|lll|@@@@@llllllll]@@@@llll|@@@@@@|llllllll|@@@@@@lllll%@@@@@@@@@@@@@@@@Wllll$@@@@@@@@g     //
//         @@@@@@@N@@@@llll]@@@@pllllllll|@@@Wllll]@@@@Kllllllllll]@@@@|llllll|%B@@@@@@@@@@@@@@llll|%@@@@@@@@K    //
//        ]@@@@@|lll|%@|lll|@@@@@pllllllll|%@@lllll||||llllllllllll||||l||llllllllllllllllllllllllllllll]@@@@@    //
//        ]@@@@@lllll]@@llll]@@@@@pllllllll|@@@llllllllll$gllllllllllll|@@glllllllllllllllllllllllllllll$@@@@@    //
//        '@@@@@@@@@@@@@@llll]@@@@@@llllllll]@@@g|lllll|@@@@g|lllllll|@@@@@@@||lllllllllllllllllllllllll@@@@@P    //
//         *%@@@@@M|l||%@@llll|%@@@@|lllllll]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-    //
//          ]@@@@@lllllj@@@|llll|||||lllllll@@@@@@NMN@@@@@NMN@@@@MMN@@@@@NMN@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@C     //
//          `@@@@@@@gg@@@@@@@|llllllllllll|@@@@@@|lll|%@@|llll]@llll|@@@|lll|%@@@@@NNNNNNNNNNNNNNNNNNNNNM**       //
//           '%@@@@@@@@@@@@@@@@@@g||||g@@@@@@@@@@|lll|@@@|llll$@llll|@@@|lll|@@@@@@                               //
//             "*B@@@@@@NM@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-                               //
//                  ",     -*RB@@@@@@@@@@@P"*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P-                                //
//                               --""`-        "*NNNNP*""MNNNN**NNNNP""*RNNNP*"                                   //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HBBCC is ERC721Creator {
    constructor() ERC721Creator("Habibi Community Collection", "HBBCC") {}
}
