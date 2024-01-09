
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blazed Punks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                ;                                                                        //
//                                                                                ED.                                                                      //
//                                                                              ,;E#Wi                         :      L.             G:               .    //
//      .                      i                                              f#i E###G.             t         Ef     EW:        ,ft E#,    :        ;W    //
//      Ef.                   LE              ..                            .E#t  E#fD#W;            ED.       E#t    E##;       t#E E#t  .GE       f#E    //
//      E#Wi                 L#E             ;W,      ,##############Wf.   i#W,   E#t t##L           E#K:      E#t    E###t      t#E E#t j#K;     .E#f     //
//      E#K#D:              G#W.            j##,       ........jW##Wt     L#D.    E#t  .E#K,         E##W;     E#t    E#fE#f     t#E E#GK#f      iWW;      //
//      E#t,E#f.           D#K.            G###,             tW##Kt     :K#Wfff;  E#t    j##f        E#E##t    E#t fi E#t D#G    t#E E##D.      L##Lffi    //
//      E#WEE##Wt         E#K.           :E####,           tW##E;       i##WLLLLt E#t    :E#K:       E#ti##f   E#t L#jE#t  f#E.  t#E E##Wi     tLLG##L     //
//      E##Ei;;;;.      .E#E.           ;W#DG##,         tW##E;          .E#L     E#t   t##L         E#t ;##D. E#t L#LE#t   t#K: t#E E#jL#D:     ,W#i      //
//      E#DWWt         .K#E            j###DW##,      .fW##D,              f#E:   E#t .D#W;          E#ELLE##K:E#tf#E:E#t    ;#W,t#E E#t ,K#j   j#E.       //
//      E#t f#K;      .K#D            G##i,,G##,    .f###D,                 ,WW;  E#tiW#G.           E#L;;;;;;,E###f  E#t     :K#D#E E#t   jD .D#j         //
//      E#Dfff##E,   .W#G           :K#K:   L##,  .f####Gfffffffffff;        .D#; E#K##i             E#t       E#K,   E#t      .E##E j#t     ,WK,          //
//      jLLLLLLLLL; :W##########Wt ;##D.    L##, .fLLLLLLLLLLLLLLLLLi          tt E##D.              E#t       EL     ..         G#E  ,;     EG.           //
//                  :,,,,,,,,,,,,,.,,,      .,,                                   E#t                          :                  fE         ,             //
//                                                                                L:                                               ,                       //
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BPs is ERC721Creator {
    constructor() ERC721Creator("Blazed Punks", "BPs") {}
}
