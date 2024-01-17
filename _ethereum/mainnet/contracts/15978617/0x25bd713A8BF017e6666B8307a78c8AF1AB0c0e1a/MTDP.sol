
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Macy's Thanksgiving Day Parade
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                    |`                                                                               `X`              //
//                   ^m>                                                                             `^Q@Q=`            //
//                  ,amS_                                                                             `|,|.             //
//                  Immmj`                                                                                              //
//        'r???????cmmmmmt???????>,  w7,Ljwoz;  `+nSm{*'      `;7ywSn?' cP'    '=Iawy7;`  ;P!        ;P^ -?jwj|`        //
//          :|5mwwmmwwmmmmmmmmZL~    @@Qn!~!\QQm@U>;~>h@u   `S@D\!~;=}QQQ@~  ;NQS>;~!ib@G. q@~      ;@Q`~@R=~^bQ~       //
//             ~iSmmmmmmmmmSc;`      @@-     `8@|      |@| 'Q#,        i@@~ c@t`       ,WQ,`QQ`    -QQ' v@*   'y^       //
//               >mmmmmmmmmL         @R       y@,      ,@S j@~          d@~-@#          `,` ~@q   `gQ,  `yQQXu>`        //
//              -ZmmmmommmmS,        @D       y@,      '@m j@~          D@~'@N           ``  +@y `d@~      `~*6@L       //
//              7mmy>, '+fmmt`       @D       y@,      '@m 'Q&,        \@@~ 7@t`       'RQ:   S@7X@?   `ga     QQ       //
//             ^Z|,       ,*5>       @D       y@,      '@m  `m@di;~~rYQQQ@~  ;BQa=;~;LH@6'    `d@@\     7@w^~^w@i       //
//             _`           `_`      mc       >m-      .m*    `;zymSf|, \m'    '>{amoJ!`       \@x       'LymyL.        //
//                                                                                            >@q                       //
//                                                                                           ~@D`                       //
//                                                                                           `.                         //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MTDP is ERC721Creator {
    constructor() ERC721Creator("Macy's Thanksgiving Day Parade", "MTDP") {}
}
