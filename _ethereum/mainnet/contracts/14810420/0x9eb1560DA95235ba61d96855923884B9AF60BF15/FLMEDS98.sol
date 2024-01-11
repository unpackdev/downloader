
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FILM SINCE 1998
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                            //
//                                                                                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXkYct1=|;::--____--::;|)]}vLTGHMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMEwz7;-.`                              `.,;=IagQMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMBO3>:.                                              .:=vwNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMgL7-`                                                        `-)3bQMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMEo)^                                                                  .|cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMQPl-`                                                                         ,]TWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMAt^                                                                                .iDMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMqv:                                                                                      ,rdMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMHv-                                                                                            ^}gMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMG='                                                                                                `|hMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMh\`                                                                                                     :xQMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMP;      .YAAAddddD*                                                                        .LAdddddAAa"     -&QMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMG/         `cQMMMMMMMV^                                                                     =qMMMMMMMQL.        :hMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMH1`            ;KMMMMMMMq=                                                                  _TMMMMMMMMm*            *8MMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMQL.               .nMMMMMMMMT~                                                              `?NMMMMMMMM0.              'jWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMW\                   cQMMMMMMMN1`                                                           -OMMMMMMMMM7                  :@MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMX:                     ;KMMMMMMMMh,                      -rtc=` )uttl`                     `tWMMMMMMMMm|                    `PMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMs.                       .YMMMMMMMM#l`                    \-.iN,'gi-"`                     :GMMMMMMMMM&.                      `vQMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMN*                           :GMMMMMMMME*                   `_+lO;.j|:lH:                  _TMMMMMMMMMA:                          :KMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMME:                             `cQMMMMMMMMx^                'ht:*g=-a*:}K-                `iNMMMMMMMMQz'                            ^@MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMd,                                ;gMMMMMMMMH=                `:*;.  ^\+:`                -OMMMMMMMMMK;                               .PMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMg_                                  .LQMMMMMMMMT_                                         tWMMMMMMMMMY.                                 .OMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMm-                                     *qMMMMMMMMN:                                      .YMMMMMMMMMq+                                    .SMMMMMMMMMMMM    //
//    MMMMMMMMMMMB;                                       ^aMMMMMMMMQc'                                   =qMMMMMMMMMa^                                      ,mMMMMMMMMMMM    //
//    MMMMMMMMMMM1                                         `]NMMMMMMMMd;                                _TMMMMMMMMMN]`                                        ;WMMMMMMMMMM    //
//    MMMMMMMMMMs                                            ,OMMMMMMMMQo.                            `?NMMMMMMMMMP,                                           tMMMMMMMMMM    //
//    MMMMMMMMME^                                             `rWMMMMMMMMK|                          -OMMMMMMMMMW}`                                            `DMMMMMMMMM    //
//    MMMMMMMMM7                                                :SMMMMMMMMMs.                      `rBMMMMMMMMM@-                                               ;QMMMMMMMM    //
//    MMMMMMMMT                                                   ]NMMMMMMMMQj`                   =qMMMMMMMMMN=                                                  cMMMMMMMM    //
//    MMMMMMMM\                                                    ,qMMMMMMMMMb:                _TMMMMMMMMMME~                                                   -BMMMMMMM    //
//    MMMMMMMD`                                                     ^aMMMMMMMMMQc'            `iNMMMMMMMMMMs.                                                     nMMMMMMM    //
//    MMMMMMMi                                                        ]NMMMMMMMMMd;          -OMMMMMMMMMMH)                                                       |MMMMMMM    //
//    MMMMMMQ-                                                         ,OMMMMMMMMMQo.      `tWMMMMMMMMMMT^                                                        .qMMMMMM    //
//    MMMMMMG`                                                          `}WMMMMMMMMME=----|SMMMMMMMMMM#1`                                                          VMMMMMM    //
//    MMMMMMo                                                             :SMMMMMMMMMMMMMMMMMMMMMMMMMO,                                                            rMMMMMM    //
//    MMMMMMr                                                     \|`      `cQMMMMMMMMMMMMMMMMMMMMMWr`                                                             *MMMMMM    //
//    MMMMMM7                                                     uMqo*.     ;gMMMMMMMMMMMMMMMMMMM@:     -L}`  .u:  -3: .octtt:                                    :MMMMMM    //
//    MMMMMM|                                                     uMMMMQP}-`  .YMMMMMMMMMMMMMMMMQc`     ^ArOv  -Ml-sa:  :M+                                        :MMMMMM    //
//    MMMMMM|                                                     uMMMMMAc;`  `cQMMMMMMMMMMMMMMMX-     .bh:7W: -MmvaD-  :MTtt7`                                    :MMMMMM    //
//    MMMMMM>                                                     uMBT1,     :SMMMMMMMMMMMMMMMMMMBl`  `0D)++tg^-Ml `iq1 :M+                                        :MMMMMM    //
//    MMMMMM}                                                     +='      `IQMMMMMMMMMMMMMMMMMMMMMh_ `;.    ;'`;.   ,; `;'                                        *MMMMMM    //
//    MMMMMMo                                                             -DMMMMMMMMMMMMMMMMMMMMMMMMN>                                                             }MMMMMM    //
//    MMMMMMD`                                                          `}WMMMMMMMMMMKvtttvmMMMMMMMMMM0^                                                           YMMMMMM    //
//    MMMMMMQ-                                                         -OMMMMMMMMMMQz.     .LQMMMMMMMMMm*                                                         .EMMMMMM    //
//    MMMMMMM1                                                       `?BMMMMMMMMMMG:         ;dMMMMMMMMMMo.                                                       \MMMMMMM    //
//    MMMMMMMP`                                                     _wMMMMMMMMMMBr`           'vWMMMMMMMMMg;                                                      oMMMMMMM    //
//    MMMMMMMM;                                                    :NMMMMMMMMMMw-               :DMMMMMMMMMQc                                                    _NMMMMMMM    //
//    MMMMMMMMx                                                  `rWMMMMMMMMMH>`                 `lNMMMMMMMMML.                                                  IMMMMMMMM    //
//    MMMMMMMMQ;                                                -OMMMMMMMMMQs^                     "TMMMMMMMMMK;                                                ,NMMMMMMMM    //
//    MMMMMMMMMg.                                             .oQMMMMMMMMMw,                         :@MMMMMMMMMT^                                             `hMMMMMMMMM    //
//    MMMMMMMMMMo                                            ;gMMMMMMMMMH>`                           `rBMMMMMMMMH)                                            lMMMMMMMMMM    //
//    MMMMMMMMMMM=                                         '3QMMMMMMMMQY^                               -hMMMMMMMMMs.                                         :BMMMMMMMMMM    //
//    MMMMMMMMMMMN:                                       :AMMMMMMMMM8\                                  `]HMMMMMMMME/                                       ^8MMMMMMMMMMM    //
//    MMMMMMMMMMMMg~                                    `vQMMMMMMMMMv'                                     ^&MMMMMMMMQu'                                    'OMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMb^                                  :GMMMMMMMMMH7                                         vQMMMMMMMMA:                                  `TMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMG^                               `tWMMMMMMMMMs^              :.   _||~   ^||_             -OMMMMMMMMQv`                               'TMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMX,                             -OMMMMMMMMMg|             .*sQ1  lP;*E> =b;:Or             `iNMMMMMMMMD-                             .hMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMq;                          `lBMMMMMMMMQc'              ,:-N1  .` >D: hv  lA`              _TMMMMMMMMBl`                          ,bMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW?                        ,PMMMMMMMMMD:                  .N1  `*&*`  Yx  ch`                =qMMMMMMMMh_                        |HMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMO-                    '3QMMMMMMMMg|                    `v-  +xctt; `=II1`                  `}BMMMMMMMQc`                    `aMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMN:                  .dMMMMMMMMQc'                                                           -wMMMMMMMMS.                  "wMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWv'               *mMMMMMMMMD:                                                              `7HMMMMMMMK;               `iNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMg+            .nMMMMMMMM#l`                                                                 ^VMMMMMMMQc`            :DMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMh:         \KMMMMMMMMT_                                                                     |KMMMMMMMb:         ,VQMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMQx-     'uQMMMMMMMq=                                                                        .zQMMMMMMWt`     ~zWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMQx:   .---------'                                                                           ^--------'   ,uWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMw|`                                                                                                 :VQMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM8l^                                                                                            .>DMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW&|`                                                                                      `:oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMQP1'                                                                                `)aQMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#&=^                                                                          .*LHMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMQ@v;.                                                                  `:rPQMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOv*~`                                                         ^;rw#MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMME0r|-`                                              `_;lY8MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW@Yt*:^`                                `.-/?LO#MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMB8hfcr]+;::-~^^.....^^,::;+7}vnyXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                                            //
//                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FLMEDS98 is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
