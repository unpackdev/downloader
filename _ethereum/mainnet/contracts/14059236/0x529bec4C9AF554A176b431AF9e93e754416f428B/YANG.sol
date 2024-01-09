
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: yangyangicecream
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    ~""""~""~"!~""~"~""~""~~"~""~""~"~M#M0M0MM0M00N0NNBBMN#Q0N#B#00#B0MMMM0NR00000M    //
//                                      "0N#N00NN&###B#M0&MM0M0#0#QM00MM0B0N0N00&00#M    //
//                                  -    O#0&MWQN#00N&00#M&&#N000&0MM#&0N#000000000&B    //
//                                       MQ0MM#000NKM00M&M#0#M0Q0000M00BM#0M0#00000M0    //
//                                       *#MMN&MN#MMB000#0N00#0M#MM0Q#M0NQ00NN0R0#0N0    //
//           -                           ##M00MN00RMMMNMR00#&#N000D#N00M00MM0M0B0000M    //
//              -                       yp0W0N0B#NRQ000M0#Q##N##M0N0MN0R#M0BNMN&NN&00    //
//            -                      ,(T~#&Q0NMMM0M0M&000WMM#N#00M#0QN0#MM#0Q#0NK0N0M    //
//                                 m~dgg#&0M00Q0N0BMNMMMM&MMM#MQNMQ&0AM#N#0B#0&BQ0#0#    //
//     -                       _p-  0M000BNN00M#EN#00M000N00M#NM#0#0NM00M&R0#Q##MN#0#    //
//                            ^    :b00##MN0BM&#Q0000NMM#0#M00M@$0MN#0MQN8WNQNM@0&NM#    //
//                               aMTN00N0K&0QMMMM00B#N#BMM#M#0BM#&WRNM@NKZ##0*A#r0M&#    //
//             -                  \M#Q0M0M#&M#BMR0Q00MQ&#MM&00NBM#Q0$9s%^MmhMMM&&&&&&    //
//          -                     4NMQBMQQN000M0N&M&0M0MKMM&0##G&9&&&&--  "\~:Wd--&--    //
//    ;                         m\j0#BKMM00M00NMMMMgMM0Q00M#8m&d&&^^3E S  E  O.   ~-*    //
//    0                       -&CB&M000MQN@B0N0QB8#000#N00NMEE%3m  % ~   --0T    -~      //
//    ML                ,  ,zz&#&B0000M###R0000M0#BD&#g80M8FxZ^xE                 - -    //
//    F4                4%%!,yAWR#MMMB00##0MB00B00#&0&Q&YXM,M-    ~        \    \s  -    //
//    M&V             \\MhQp&&##N0M0000NNN000N00000QB@#M&E%^       )  \   -      \       //
//    M0f           {E"6m&0MM#B0#B#0#K##B00B#0M#00b&0KQ&&t~~ ~           -    -    \     //
//    M~         /-W~%EggKN#0#0N#KMQB00#00M0M0#QN&QW&rmM ~1 -                   -        //
//              r4b~dEE0M&##K#&0Q0Q&#R0#0000MNM0#QDE$\/ZO                  -             //
//              "-&%&6DFN#F RBgp0N&000NM#M0NM#MND#WQ-#H~                ~                //
//           tT^0~~      3QNN0M0#M#0#0M00&0##NN#0Nr9^4% r             \-                 //
//                     %MR@90B00#QN0QQ##NMNNQ0M&AMM:~#                          -        //
//         -             NSw0Q#000M00M00M00#MM0EFaO  &                -                  //
//                  (    16~0N#NQ#M&M0#N00#000&3rw~  I                                   //
//           {  "  /~     &=#MNM0#BA#M0#M####C&&&\  \Z                    \    m         //
//           ^ \         w!xQN0#0#0N00#M#00M#8FFKE   $                                   //
//     \  \   - -         Tr##0MN#B00N#00R0NDQ&&~    F                                   //
//    ,  ~\               #$M80Q&QM0M#MM0M#MAQQ} \  w:~                                  //
//                        0&NMK0M0#N#MNM0Q00Q#E~                              ^  ^       //
//                        &DMM#MD00&00###RR0W:       ~-                          ^       //
//                       -#h$M#00#B0#0#0MMQ09                               \            //
//                   -    39070MM0NM&BKMM0A&-                                            //
//                    -   dMg3Q0#NN000#0000h                              - -            //
//                   t5% (&7MQM0#N00W#8N0&&                              \       ,       //
//                    {"p#g%%BN00##N00M0M&}           : \ - \,         \                 //
//                    ^ENF0G%gQM000NRMMN#M        $QNMt&&&&#QAp&#qg       %        ^+    //
//                     g/#mb;Z$MM#M000#KNE      yMMKK##Q0g&MN0QMMNMM&#,sEE{.             //
//                   = &#QAgQ00#M0QR&0B0&D     m#00M'~7D!P9K0MM00M&MMD0$FFFG  \     ^    //
//                    ,900K8#M#MM0MN0M0QNr     ~\/. -      ^ {&&&MDNZKWE0\w ^S    "r     //
//                   zB&MMW&GN##NQB000MMN@                -   h\ar&&&&NFF^,m     3 \     //
//                \ ^:0N00F#EB&p00MM&#M0Mm               \/-Qmam&~&&m"$:1   -     .-/    //
//                   RZM0M#0BQ6#MMR#M#B0D              Lx*&&3&Q&&mmy/~-&/\~ \      z~    //
//         -         #&AMMM0MNN0#NN#0#NN0$           $EEEpg#000NN&Q&e% m  {   -          //
//               1  -r4*#NM0Q0N#&NBBN0BM&m      \  w&&&g0M~Q0F#0M0000pTaS%\         &    //
//                  - ~#AMNMR0#W0Q0&&M0N0~        m$#B00M" 0Q0#M00#D8CMG%( \       --    //
//                    -,EDM##R#M000#00WMM1         ~~$DEM%,{BQMM00B&&D9$/-          "    //
//      =              *Z/Mr,NW#BK00MM0N0r      = \  dO:T&wb~~#K9#E#0#:#           ~     //
//        \            -::r_;&#M#Q0NQN##&6-         -  ^{r -  ""~~Z~#1 ~            \    //
//                .      T~T~?M00##&#QM0NH \                -   {"0^^               ~    //
//                      \   "}-&&NZD0B&N0E   \    \            S                         //
//                             m&-~LB&0NMAr         -         ^  \                       //
//                       \        m"00&N#b-    -                 \                  t    //
//                  \           Sf;MQp#&M0-   s\\                                        //
//              /   \          %dg0##D&&&#S       ~                                      //
//              -   \    .    {N#MMEEQD#MQr                                              //
//          \        \ --     mmR&K,D~&&B0&                                              //
//                    \  ~  ~M00QB-:0d3EpMA \                                            //
//         ~\z  ^  \  -~^  ^[9 \ - ~~:(pFNW \  .                                    ~    //
//    \ ~O ~w      ~  ^       t*\,+a5  IB#0p  -                    \    -                //
//       -w:       ^ \    \\ :~  \  \  d+*E& -                    ~          ^           //
//    ^   &          ~       :. ^ _   " ,T%:@ \               \      -        -          //
//    ~ r-                 \ \m x  "}\   \wM%                        -              :    //
//                           - }    - -    "$                              9F:Z~  ~ &    //
//                       ~   ~       ~      F               -                \\^  wm9    //
//                                  -   - =  \%           _ \                    \  ~    //
//                          }         -   ( ~~,                                     \    //
//                           `      -  ~/ ~ {r6-  \  ~                              t    //
//                              \          -  :W\             - m6m           \          //
//                        "  -  \        ~   r&$Eq             a0@~\M%!pa&f&r,E&ggr##    //
//                        -                 \ ) Cmq          -  {     "B3&W#$M&M&N&N#    //
//                             ^-       -   / -:@04D,           -    -  "W0000T&Z0MU#    //
//                                        -  *L  &&Q$m                     {-&&&&&&BE    //
//                 \ ,       .              %\ " \&NS&W                        - ^\%9    //
//                            \\         ^\ \Ea   ^$W#\                        ~ \~^     //
//                                            \  -Q"0?                            \      //
//                    \   -              - ^- "}  mN% ^    -                             //
//                 -                         \x  gE\          \                          //
//                    -               - { -%\ mmL% ^                                     //
//                                  ,    -{ -m0#~\                                       //
//                                  ^  w -:)aT                                           //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract YANG is ERC721Creator {
    constructor() ERC721Creator("yangyangicecream", "YANG") {}
}
