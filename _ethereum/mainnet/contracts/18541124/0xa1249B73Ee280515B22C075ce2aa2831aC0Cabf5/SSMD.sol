// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DARK SASHIMI ART
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                       ..J7""""""""71(..    `    `    `    `    `    `    `    `    `     //
//         `  `  `  `  `  `  `  `  `  .,^  .._~~~~~~_-.                                                     //
//                                 .7'..__~~~~~~~~~~~~~~~~_..  .      `         `         `         `       //
//                              .,=.:(3:::::;:__:~~:~~~~~~~(.`` ,i.       `         `         `             //
//                            .('.::::$::::+:::::::(QJ:~~~~~?h.  _,i                                        //
//                          `,^ (:::::?+:::J2::::::::?N+:__~~~?x~~_.7,       `         `         `    `     //
//                         ./  `(:::::d#<:<:S:::?m<::::X+:<.::_(h~~~.,,           `         `               //
//        `  `  `  `  `  ` J  `.-<.::jMPz+_:?[:::dmx<:::?+:::::::4(_~ -,  `                                 //
//                        .t(_.2::::+MMb:?x::d+:::WTNx::<d+:::::::1<:~ j        `      `       `    `       //
//                        J3::J>:::<dM^X:::4+:u<:::W,.THx:1::::::::?x:..]           `     `            `    //
//                       /,::(D::::+#!`,2:::<C+j++JTT, `.4&1::::::::?n< (.   `                              //
//                      . P::J<::<?M7771N+<~~___?~~(7?h..ZTBMW0::::::?h<.h                   `  `  `        //
//                      \.P::?h:::+t _!-,b........(JWgdMr`` (_~:::::::?h:.1,      `                         //
//        `  `  `  `   , VF:::<HVWMHbHHY9dx..._(-(?=.MMMgm,`,-.._<:::::?b:.j.         `   `           `     //
//                     [J>W::::?WJf`.JMNa/?2?=```` `M@MMMMN  r...._(+jkYT::.S                               //
//                     wJ:JQ::::?$^.M@@MMMe` `` ` ``MBuXOOT{`r...(=  `,NM>:.F    `                          //
//                    .\d(dMa+J+<j`.MBXXuVH.` `` ` `(+>;>>j!_ty(WV, ```d@:<J         `         `    `       //
//                    , QKz]..(N,(, 4C1>>>j``` `` ` `(>~_(^.(v~Xz>w,` .MXuf             `  `                //
//                      f::h.(9._Th._1+~~('` ` `.`.` ` `` .._._df::wgHSKd$        `                         //
//                     J<:<:T@......... ```` `.(?? `` ` ``   (MMb:::dKX=                         `    `     //
//                    .r:::+1Jh.-...._ `` ` ` ````` ``  ..JMMMNXMp:::d#HQ.                                  //
//                     ,5J<<1<vGxZ@6J..............J7"=`,HggggM, d::::dmwdp     `      `       `            //
//                        ."TuSgMHbHMb?CXMNgggggggMN,.gmaHggggNMFMr::::?NbM?C..             `               //
//                            -XzdbbbWR::<?MHggggggggMNNNNgNMMMMMNN<+MHHHWMmJ::?&.                  `       //
//                            ,mXbbpbWF4<:::dMMMNNNgggHMMNMMMMM@@@MNkWWQH5?zx?G<:<T,                        //
//                             ,8WkWkB. 7+:(++dMMMMMMMNNMNNMMMM@MMMMMa,  4+>+O+?G<::C,                      //
//                            .$::J#>>?, .4MMMMMM@@MMMHMMMHMMMN?WMMMMMMp  (x>>?x>?G<:<i     `    `          //
//                            .:+:?#>>>?n  dMM@@@@H@M@MMMMNHpWNb."MMmmggb  ,x>>?O>>?&::G              `     //
//                            ,<P::q++>>>Z,d@MMM@MggHMMMggmMkpMMN.MgHNT4M   (x>>>z+>>4J(h                   //
//                            ,+j::<b?m+>>W@MMMMgmmNMgggggggMMNMMN-Y!```,`   ?x>?>?x>>dpOh                  //
//                            ,J b:+?2+WxjdMMMMNMMMggggggggHMMMMMMN,` .,^     4?>>??+>>dRk]      `          //
//                            .X ,x:TJo>jHMMMHHmgM@NgggggN#^ ` ``MMMM#`        DXx>>j+?y^             `     //
//                             M- ,x:<6HM@MWMHkVH@MggHgHMh`  ..dM@@@!          ,j,x?u"_`       `            //
//                             (L  .n::+GiMMh7WHs?WgggMMMm#jN@@@MY4             W .4`                       //
//                              4.   4Y`_.n3,?1?TZ~<TY""U8""""W"  `1            X                   `       //
//                               3      .D+?n?V ~ (i. 7d{      7,`  $           ?                           //
//                                      Ma.(WEn.      ~..=-.    .WgMM|     .i.              `    `          //
//                                     .MMM#l.=o           .T..   7MMN     . 4&.                            //
//                                    .MMMD  .1./.            .=(. (MMb     ?uQHM].-                        //
//                                    MMM]     .4.                7a,MM%  .JMHHHWNaQma..              `     //
//                                    ""!         7,                ?...WNbpbWHMHbpppHHHHh     `            //
//                                                  ?+.             .d9U$WHMMbbpbpbpbpppWF                  //
//                                                    .=,        .JMkVSNMHbppbpppbWQV""7`           `       //
//                                                    ., ?i.   .dHppWMMpbbppbpW#"!               `          //
//                                                   .  TS-._(WHpbWMHppppbpbWY`                             //
//                                             ..,     _..1GdHbbNMHbbppbpbWY                `               //
//                                            5/~?o      <dHbbWMbpbbpbpbWY                                  //
//                                            .J~~~T&.    .UHMHkWkkQQQH#:                        `    `     //
//                                          .-3~~:~~~?5j.    ??`        `                                   //
//                                        .J=~(JJxZY""]~:?TC(..                        `    `               //
//                                      .d9""!        TaJ"~4J(]                                             //
//                                                  .-"      ,3                   `              `    `     //
//                                                                                                          //
//                                                                                     `    `               //
//                                                                              `                           //
//                                                                           `                   `    `     //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SSMD is ERC721Creator {
    constructor() ERC721Creator("DARK SASHIMI ART", "SSMD") {}
}
