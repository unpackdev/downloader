
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lil Mahnaji
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//            '`            ``     '`             `''         ''`                   `'`                                        `'         '-`                   //
//           x#Q           rQ0    *#Q            =Q##*       y###                   ##o                                        Q#}     ~K8###di`                //
//           x@Q           rQ$    r#B            ~B#@I       d#@#                   #@I                                        Q@T    iQQB@##QQD_               //
//           x@Q           rQg    *@#            ~B@@$      .8@@#                   #@U                                        Q@u   ^##B#@@#BB#Z.              //
//           \#Q           _\r    r#8            =Q##Q`     ~8##B                   Q#w                                        vY,  `9#QgQ##B88B#y}_            //
//           i@Q                  *@#            ~#@@#"     xB@@#                   #@U                                             ^#@#B#@@#BB@@Q9y            //
//           x@Q                  *#B            ~B###)     oBQ@#        `''        #@I  ''            ``           '.'             )#@QUYxx\YK#@Boy            //
//           x@B           :TY    *@#            ~B8m#y     gBm@#      ,mB#Qz=      #@U.cBB3-     =yT`}$gZ*       ,oB#Bz!      Yz~  ^##v\ ~   ~ /@0=)i          //
//           x@Q           rBg    *@#            ~BQ}@9    'QBx@#     :g#@@#BQx     #@ODB@@#D`    y#BM#BB##~     <8B@@@BQx     B@c   Mm~i}$$$$${9)<3.Z^         //
//           x@Q           rQ$    r#B            ~Bg"#Q`   ^Q6r@#    `ZQBdwygQQ,    #@BQ$GQ#B*    T##@#33#@d     DQQPozgB0     Q@T   _Z)v}33oiv\i _g}.0         //
//           i@B           )Bg    *@#            ~BQ_gB!   YBI^@#    :#Bx`  ~B@v    #@#9, _QBy    u#@#~  O@#`   _#Q)   =B#=    B@c    ~9B#@@#BQV  `gu  y        //
//           \#Q           *g6    r#8            =Q0-Pgx   3g)*#B    \Qg`    $#T    Q#Q_   u8q`   cQ#x   r##_   rB9     DQv    $#}     `````````    !)  ``      //
//           x@Q           )Bg    *@#            ~BQ-vBK   8B-^@#    "Tx     d@K    #@q    ?Bg`   c##`   ^@@!   ,u\     $#x    B@c     ,Uccucmo.                //
//           x@Q           rQ$    r#B            ~BQ_:Q9  ,Qg`^@#         `!<D#3    #@I    rBQ`   y#Q`   ^#@!        .!^$#x    Q@u    _OQ#@@#QQ9.               //
//           x@B           rQg    *@#`           ~B8.`gQ- xBI ^@#      .TEBQgB@q    #@U    rBB`   }#Q`   ^@@!     -Y0#BgQ#x    Q@u    Z#TURNING#K`              //
//           x@Q           rQg    *@B            ~BB_ 3Qr Z#x <@#     =$#@@#BB@q    #@U    rBB`   y#B`   ^@@!    r0B@@#BB#x    B@c   x@#DREAMS##@i`             //
//           x@Q           rQ$    r#B            ~Bg. }Qw-QB= ^@#    .EQB6x*^0#P    #@I    *QQ`   }#Q`   ^#@!   `8QQPxr^g#x    Q@T   0#.#INTO##.Y@D             //
//           x@B           )Bg    *@#            ~BQ- <Qg!#B  <@#    *#B*`   6@q    #@U    rBB`   u#B`   ^@@!   r#Q*    g#x    B@c  `B#.REALITY'@B              //
//           \#Q           *g6    r#8            =Q0. .$Qc#M  *#B    GQG     O#I    Q#w    *8g`   cQQ`   ~B#!   3Bm     0Qv    $#}   E8.8Q##Bgg.Bg              //
//           x@B           )Bg    *@#            ~BQ-  O#B@w  <@#    $#U     D@q    #@U    rBB`   c#B`   ^@@!   6#V     g#x    B@c  `^'#B#@@#BB#`^'             //
//           x@Q           rQ$    *#B            ~BQ-  w#@@r  ^@#    0#P    _Q#P    #@I    *BQ`   y#Q`   ^#@!   d#o    !Q#x    Q@u     GQB###QQI                //
//           x@#xvx}}xv*   rQg    *@#`           ~B8.  *#@@,  <@#    V#Q!  !dB@q    #@U    rBB`   }#B`   ^@@!   z#g,  :OB#x    Q@u    `DB#'''QBq                //
//           x@@BB#@@#Qq   rBg    *@#            ~BQ_  :#@#   <@#    !BBBQQBBB@q    #@U    rBB`   y#B`   *@@!   :#QQ8B#BB#x    B@c    `gQ*   ?Bg                //
//           x@#BQ#@@BQP   rQ$    *#B            ~Bg.   Q@Z   ^@#     iQ###BUD#P    #@I    rQQ`   }#Q`   ^#@!    V8Q#@#IE#x    Q#u    .Dx     cE                //
//           :uTxxYuuix^   ,x\    _TY            -x\`   \c<   -T}      ?d09x`)T*    vu<    _x)    _Yx    'iu.     \qD9Y *Y:    B@c     ~      `~                //
//                                                                                                                             $#}                              //
//                                                                                                                             Q@}                              //
//                                                                                                                            `Q@?                              //
//                                                                                                                           xz#@!                              //
//                                                                                                                           B#@#.                              //
//                                                                                                                           8QB\                               //
//                                                                                                                           "~-                                //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LilMahnaji is ERC721Creator {
    constructor() ERC721Creator("Lil Mahnaji", "LilMahnaji") {}
}
