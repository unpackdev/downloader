// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The width works
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    NMMNMWUOkHNM51zw1ZdZZZZZZZZXw0vqN#6WXXZZZZZZZQH0dXZZZZZZZZZZZZZZZZZZZZZZZZUMMMNMNNa.                    //
//    MN#XVzgMddM61uXOXdZZZZZZZZZZXddM#jHZOZZZZZZZXHZ0ZwdXZXZZZZZZZZZZZZZZZZZZZZZZM#MMMMMN,                   //
//    M0ZGqMHNMMIJdZkZZZZZZZZZXXXdMdMD+NZ0ZZZZZXZUJWZwZdd0XWZZZNXZXZZZZZZZZZZZZZZXyWNTMNNM#h.                 //
//    dVdM#dQMMWdZZXQgNNNMMMNMMWMMdMD+MW#wZZZQMHQWHZZdZddkN#ZZXMZZdZXUZZZZZZZZZZVkXkdNWM#NdKM,                //
//    GdNMMMMMN#dMMNMNMNMNMNMNNMMMM5<MWMMNkgMM#X#dWZZZZZkWdMZZXMNZvXdZZZZZZZZ0Z0ZZSwZvWWMNMdKMp`              //
//    QNMNNNM#MWMNMNMNNMNMNMNMMMNM3~JHMMNMNMMNHWjMNXZZZXH#MHZZXMMd0XdXdWZZZZZZZZZNdkwZZ0WM#NdsNl.             //
//    MMMNMMNH#MMNMMNMMNMNMNMMMMN8~.NMMNMNMNNMdFJMMMNNmHU#MMyZyNMkZdIkRdNZZZZZkXXMNXXdZX0NMfNHd#k,            //
//    MMNMNM#dWNMMNNMMMMY""""7??!  ,"THMMNMMNM#`dMNNMMM#XHMMKZZMN#NkXXW0MNZZZZZZXNMkZkXXNINMdKNdKm,           //
//    MMMMNM#HX#""!                      ?THMM] dNMNMNMWdWNMNZkMMNMNWZXZdM#ZZZZkdMMNdZkXd#wd#MdKMdN.  `       //
//    MNMMM#"`                               _ .MMMMNMMXMXMMMXWdMMMMWKXHWNMKZZZZMMMNKZZZZMNwMd#MdNNh          //
//    WM9'                                       7HMNNNWNXMMMKHUMNNMNMMMMMNNXZXXMNNMNZkZZdMNd#MdNMdbL         //
//    `                                             TMMNNWMWMNWXNMNNMMNMMNMMNZyMMNMNMW#WZXMMbMM#MdNMd,        //
//     ..                                             7MNNMNPMNKMMMNMNMNNMNMMNdMNMNMNNMMKZNNMMMMM#MdNN.       //
//     .Mh.                       `  `   `              (WMN@JMNMNMNNMNMMNNMNNMNMNMNMMMMNWMNMMNMNMMNMMb`      //
//      ,Ndh.                 `                           ,WN(MMNMNMMNMNMNMNMMNMNMNMMNMNMNMNNMNNMNNMNMN,      //
//       .WNWn    `  `  `  `     `     `   `  `  ` `        ( ?MMNMNNMMNNMNMNNMMNMNNM#dMNMMMNMMNMMNNMMMb      //
//         7MmH,             `               ...JggMM"^        dMNMMNMNMMNMNMMNMMNMNM#ZMMMNNMNNMNMMNNNMN      //
//          .WMM]                  `  `..JWWqMMM#"^            (MNNMMMMNMNMNM#MMMNMMNHZMMNMNMNMNMNNMMNNM|     //
//    .       .Tt                `   .WQgMM#"=           `     `dMNM#dNMNMNMN#MdMMNMMZZMMNNMNMNMNMNMMMNM]     //
//      ~.                          ?"""!                       .MNM@JMNMNMNMHNd#MMNNXMMNMMNMNMNMMMNNMNMb     //
//    MN,..   l   `  `  `  `  ` `                   `  `   `     dMM$(MNMNMNMW#d#MNMNMMNMNNMNMNMNMMNMNMN@     //
//    MMMN,.  ,;                                              `  ,MM:(NMNMNM#dHMWMNNNMNNMNMNMNMMMNMNMNMM@     //
//    =zTMMm-  .                         .?!     ` ..+<<<??!(, `  M#~.MNMNMMNHd#dMMNMNMMNMNMNMNN#MMMNMNMF     //
//    ==?vMMR~  `    `    `   `  `  `   `     `._uJMMMMMNgJ_. ?,  ($_ MMNMNNWWMWMMNMNMNNMNMNMNMM#M#MMMNM]     //
//    ~~??MNMR_                             .-<(MMNNMMMNNMNmx_ ,| .1` dMNMNMWM#dMNMNMNMNMNMMNMM#XM#MHMMM!     //
//        MMMMb                           .!.dMMNMM@WNMXMMNMys_ 7  (  JNMNMMMMMMNMNMNMMMNMNNMNMZXMHMXNMF      //
//        MMN Wp                         .(dNM9dNN$ (MNbdMMN#J/_   .. dMNMNMNMMNMNMNMNNMMNMMMHZZZWX#dMM!      //
//        JMN. W,                      `.JM#3<jMM@  dMMDzMNMM+hJgM#^ .<MMNMNMMNMNMNMNMNNMMMHZZZZZZWXMH!       //
//    ,   ,NM] ,@                      .MBI!` dNM> .MNMI=dNMMMNM#=   ~~dNMNMNNMNMNMMNMMMMWZZZZZZZXWd#`        //
//    ,    WMS-(M.                   `,9!`   .MM# .MMNF_1dMNNM#^    -~~dMNMMMMMY"""77??7WZZZZZZZZZdD          //
//     ... .b>66J:                           gMEb.MMMM`  (MN#^     .~~(NMN#=   .....    ~XZZZZZZXdF           //
//    ` (da.,mJ{J                            M3_?>(NM^   ."        ~~(MM@'  .vC!   _`    dXkZKZqM=            //
//    -  ."""TMH^                            F<I>><#!  ` "5       ~~(MD   .8v!     .JZUb.N#XKQ#^              //
//    (...                           `       N_~~(= .-7T8        _~?^..d] d=`      (yrwd(MMNY^                //
//    (I<~.``                          ..~~~(THHY"?8.-=          _`  Orrd .>        "! (MM"                   //
//    ~....`                         ``._ -((--..                    ,7!..`    .Krh.  (Z!                     //
//                                    `.._.~(!...``           `             ... ,Y^ .(8+.           `         //
//                                       `-_....```                         NAP   .(Y1>>>1T&,                 //
//                                 ` ...Z"=db             `    `..mgggggggme&&&g+V9===1?>>>>+TJ.              //
//                     ?NJ...-JOY""7!`    (f!                 .MNNMNMNMM8I=========??=?===?>>>?7n.`           //
//    N,                -Wb<         ...?"`                `.(MNMNMMMH0llll=========?=??=?===+>>?7e           //
//    >?Ha.                 _?7""77!`                  `  .(dMMNMNM#+111zllllllll====?==?=?=?==?>>+W,         //
//    >>?+TN,                                          .(:jMNMNMMMNb;;;;;;;>+11lll==?==?=?=?=?=??>>>de        //
//    >?>>>??Ha,`                                   ._::<jmZTMMNN<;?>;;;;;>;;>>>>+1zu&aaaaa&zz=??>>>>?h       //
//    MMNggMMNNMNJ.                           ..._::::<;jMMMNmZTY5;;;;>;>>ji&gHMY9T=7<<<<<<<<?C1x>>>?>+h      //
//    ZXWdMMMMMMMMMm,                ....Jg#9C::::::::;jMNMMMMMm<;;<jJdTY=<:~~~~~~~~~~~~~~~~~~~~~?<>>>>?b     //
//    rwSMMNMMNMMMNMMN-........(&gMMMMMB=<::::::::::::+MMNMNMMNMMKY5<~~~~~~~:~~:~~~~~~~~~~~~~~~~~~~_<>?>?[    //
//    trSMMNNMMNNMMNMMMMMMMMMMMMMMkV>:::::::::::::::::jMMMNMM#9=~~~~~~~~~~~~~~:~~~~~~~~~~~~~~~~~~~~~~~<?>d    //
//    ttXMMNMMMNMMMMMMNMMMM8I===dMM#:+gN<:+gMp::+d#::+#lwdB>~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:~~~:::~~:<1    //
//    rtdMMNMMNMNNMNMMNMBvr====zMMMNjMMMb&MNMMk+MMN<jN#9<~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:~~:~::~::~~(    //
//    trdMNMNMMMNMMMNM#tzrwz==ldMMNMMNNNMMMMMMMMMMNMB=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:~~:::~::~~    //
//    rtrMMNMNMMNMNMMM0zzrZI=qMUMM5JMMMMMNNMMMMMMM5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~::~:~~:::::~::~    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TWW is ERC721Creator {
    constructor() ERC721Creator("The width works", "TWW") {}
}
