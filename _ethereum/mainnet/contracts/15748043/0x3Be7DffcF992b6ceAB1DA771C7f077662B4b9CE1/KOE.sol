
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kiki's Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                       .''^,:Ill!!lI:"`'                                                                     //
//                                                                  ':i<>>><<<>>>>i>iiii!!!!l;`                                                                //
//                                                               ^i<<<<<>><<<<<<iiiii!!!!!l!!!!lI,`                                                            //
//                                                             :+++~~~<~<>><>><i!iii>!!lllll!!lIII;;,'                                                         //
//                                                           .~--_+~~~++~~<>>>>iii!ii!lIIII!!!lII;;;;;:.                                                       //
//                                                          "-?]?_+~~++~~<>>>>>i<i!!ilIIIIl!llIII;;;;II;'                                                      //
//                                                       .`;????-?_+++~~<><<><<>~<>i>>lIllllllIIII;;;;II:'                                                     //
//                                                     '^:l?]??-?__++~<><+?-+<<+}}}~>ii!iilIIIIIII;;;;;II,                                                     //
//                                                   .^,Il-]]?-?-+~_[<<>~~~++++-[[+_>i!!!lIIIIIIII;;;;;;;;'                                                    //
//                                                  '";li~]]]?-]+~~<-<<+~<><~~++~~>!i!!ll!IIII;I;;;;;;:;;;,                                                    //
//                                                 '";li~-][]?--++<<~+~>>>i>><><ii!!llIIllI;;;;;I;I;;;::;;;.                                                   //
//                                                '":Ii<-?]]]?-_~+<<+<~>i>>><i>!!!IIII;II;;;III;IIl;;;::;;;`                                                   //
//                                               .^,;!>+?-?]??--+<>>>>iiii>i>+>!lIlI;;;;;;;;;I;II;;III;:;;;^                                                   //
//                                               '":li<_?-?]??__+<<>>>!!i>i!i~!!I;I;II;;;:;;;IIllI;l!lI;;;;^                                                   //
//                                              .^,;li<_?_?]]]--~<>>i!!l!!il!<ilI;I;I;;;;;;;;I;;;;::;III;;;`                                                   //
//                                              '":Ili~_?~_-?--_+<<>>iiiii!ii!I;:;IIII;;;:;;I;,::,,::II;;;;.                                                   //
//                                             .`":Ili~_?<~+++++~<<<<<~<<>ilIIII;;IIII;;;;;;;;;:;;:;I;;;::;'                                                   //
//                                             .`":;li<_?+i+>>i><<<<~~<<<>!llIIIIIIl;;;;;II;;;I:IlIII;::::!,                                                   //
//                                             .^":;li<_]}M*oo*MbQz?<~~<<>illlII;!lI;;III;;::;I;!t0pqOmwdU_`                                                   //
//                                             '^",;I!>+])dpYo%8&WWM*z_~<<>!!llIIIlI;;;;II;:;;<LM##*oaooaL;                                                    //
//                                             '^",;I!>+]1txuw8&&&&&&W#t~<<>>ii!ll!lII;;:;IIlZM*abqmwmp{                                                       //
//                                             .`",:Ili+?1/ruY8888&&&&&#-+~++<>ii!!lIII;;::IqW#odqmdqqx'                                                       //
//                                             .`",:;li~?{/rucBB%%88&&&&W}___+~>ii!!llI;;;;?WMM*obpaMw]`                                                       //
//                                             .`^,:;li~?{|jnO@@%8888&&&&n--__~<<><<i!I;;;>#WMMaok0pohm"                                                       //
//                                              '^":;Ii<-}(jxo@@B88%%8hwkU?-__+_[(n/[_iI;;IOMMM*pa***%@q"                                                      //
//                                              .`",;I!<-}(ffmB@@B8%#zzcvt??-_+][jpX|<II;;lhd0JXLMMWWBWu^                                                      //
//                                               '^,:I!<_[)tr|U&B@@BwXXz/]][?-+_{nvc(<!II;IcXXXznfa8&u1<                                                       //
//                                               .`":I!<_[1/rxjC#8@@oXX1]]}]?-+_-?-_?>!lI;;InXzcx/ZQ|(<                                                        //
//                                                '^,;l>+]{|jnf[~/bMaXf[}}}}]?-1}_>_]_ilII;::;ijj)1|)~                                                         //
//                                                .`":Ii~?}(txvt?-}?[?1())|{{??)?~ii+~!llII;;III]/[}+'                                                         //
//                                                .'^,;!<_[1/juc]{j){{]1/){}[??)~>i!!llll!!!!ii>{n[~"                                                          //
//                                                 .`":Ii~?})txvc)|{[{11((){[]?[->i!lll!><~+++++-t+".                                                          //
//                                                  '^,;l>_]{(fncv?[}1){{)(){}]?-<>!l!i<+-??]]]]?-:.                                                           //
//                                                  .'",Ii<-[1|rucf})|f//t/|()1{-+~>>>~+-?](XZabX}`                                                            //
//                                                   .`":l>+-[1/rvct/fjxMWMc/||)}]-+~~+_-cW&LdM0n,.                                                            //
//                                                    .`,;!>+?[)txvcjxnnOMW&J/f)1}?_~~~+)Y**khCu}.                                                             //
//                                                     '^,Ii<_?}(fncuuccuMwXQut(1[?+<<>]zz#oOnxx,                                                              //
//                                                     .'^:l>~_]{|rucuccu*Jzzz(1[?_<ii-zXOM#(1/+.                                                              //
//                                                      .'";!<+-[1txvcccnmLXXXj)]-+<iitzzb*[[1|`                                                               //
//                                                       .`,Ii<_?}(jucvvnJQXXXn}]-+<i!vzX#C]{(:.                                                               //
//                                                       .'^:l>~_]{/rvcvuruYYXv]-+<>>~zzda}{(['                                                                //
//                                                        .'";i>+-])txvcurjfUYc[?_+~~]cmMr1/t"                                                                 //
//                                                         .`,Ii<+-[)fnzcuxrfcz1}[???vZ*/|fn?.                                                                 //
//                                                         .'^;l>~_?}(juYYccvunr/({{{cWYjuzJ:                                                                  //
//                                                          .`";!>~_]}|juQL0LXXcnjt//fxvYC0)                                                                   //
//                                                           '^,Ii<+-]{/rOqwZOQLCUzcvzYLOmw"                                                                   //
//                                                            '^,Ii<+-[1tvhhkbpqwOLCCQOmqpJ.                                                                   //
//                                                            .'^:l>~_?}(jw**oohbwmZZwqdbk~                                                                    //
//                                                             .'";!>+-]{/z#MMM#okdppdbkhr.                                                                    //
//                                                              .`,I!<+?[)fpMWWW#akbbkhad"                                                                     //
//                                                               .^:l>~_]{/n#MWW#ohkkhaa_.                                                                     //
//                                                                '";!>+-[)tpMMM#oahhhad"                                                                      //
//                                                                 `,I!<+]{(r#MW#ohkkhaC'                                                                      //
//                                                                 .^,Ii~-[1/ZMM#ohkkhal.                                                                      //
//                                                                  '";l>+?}(vMM*ahkkhn'                                                                       //
//                                                                   `,Ii<_[1/p#*akkkh!.                                                                       //
//                                                                   .";l>+?}(jo*ahkkf'                                                                        //
//                                                                   .^:Ii<_]1|C*oakw;.                                                                        //
//                                                                    `,;l>~-[1|poah1"                                                                         //
//                                                                    .^:I!>+-[{jaac!`                                                                         //
//                                                                     '^,I!>~_--_+l".                                                                         //
//                                                                      '`":Il!!l;,`.                                                                          //
//                                                                       ..'`^^^`'                                                                             //
//                                                                           ..                                                                                //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KOE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
