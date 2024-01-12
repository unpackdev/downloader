
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fucking Coral
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                          ,                                          //
//                                                                                                                     //
//                                 ,$$#y                              @$5Rm$Q$g                                        //
//                                                                                                                     //
//                                 $Qg1w%                             %@$QK@RA&L        @&b                            //
//                                                                                                                     //
//                          ,@>    @[F|,7F                             "@$$WrJK$       $Y5$Q                           //
//                                                                                                                     //
//                         /$,JL  ]&|yA|QF                              '@@&{C]@[      @@L"@@           ,              //
//                                                                                                                     //
//                        ,$,\*Q  $g7AQw&[                               ]@[2L]4$     @NF ]g$          7LCJ            //
//                                                                                                                     //
//                     $r^L$L"-ur $L~|F$6L          $@%Qg                ]@$&]W@@   ,@@TF$lWF    g1,   @'-]K           //
//                                                                                                                     //
//                     "1%  ;-.&L Wl;Cfil[         $$$MY@L               $@@p$W$$  ,@@&C44]&    $F jC /gr M@           //
//                                                                                                                     //
//                      ]@`&," $& $L w]\$$  pw     $@|$QT@               ]@&NN@N@ ,gN@}-$MK     1\" Y&%hL"aK           //
//                                                                                                                     //
//                       |~g  +.} $K-],\)W $$$$    ]@@{ nBC    y@@K$      @$${}yCR@@}C^$@@`     Jg|,- , g;g            //
//                                                                                                                     //
//                        g@ig~,&L]@ \"`R$&&gW@     $$$M+R@   /$D/Q$$     $@@$+]1M%" wZ@@       ]VL| ~ TL^$            //
//                                                                                                                     //
//                        ]|$;;\A@ $y`y\Z"j$Y$[      $Mg"$]L ]$@LA]Q$      @g@`Djwz]$K@$        @LCLu`,"Q$L            //
//                                                                                                                     //
//                         $%ZVZ-,&'$gA \P[Y[QF  ]@MX$@[KDwAyl$QOxj@       ]@$$\  QCj$$        gBgL `"u $&             //
//                                                                                                                     //
//                          %$Q L Q%@$g,' }v@&%p '@Lj"h ]nA(@P[[YQN         @gPW;`$]R$|       ]@$fL/A,A=&@             //
//                                                                                                                     //
//                           \@${+w>M%&Q  >w lM$g "$$"[-$.@ uW9$Q/          $@@$P\ AV$$       @M"7 7r"M&&              //
//                                                                                                                     //
//                            'V$g$&}`@)C`.v+g|B&$g &@/jGY ]'L$|$            $$&gw*m@@$L     $@gQ \7"$@@               //
//                                                                                                                     //
//                   w~         -"$@Q$aglZ 7M,|$Y$@Q@@$ wL'!J],$L    ]$#*    $$$k}D]}@$&    /&$PQ;I,D&@                //
//                                                                                                                     //
//                  ]]{`y            "&@$@y%  M&DI$BC$$| u],'w[Y&    $$$w9   ]$&@g(PY2$&  ,gR${@>jK-@@                 //
//                                                                                                                     //
//                  ]W-,']        4nw,  "&[$lJ`R5Cj#$]&2 -" j^"W%C   [W]l&&  ]$@WU ,h[|$%&&C$@`{y~CJ@                  //
//                                                                                                                     //
//                   @&}~ $r     @g"W*L   "N$8@F,M%@$@BKQ"],+}*24$   $L&PL$  ]@@&$gup}y$$&Ct@[~"vMW@   ,]]w            //
//                                                                                                                     //
//                   j@VLve]w    $@C w%y    ]@@L,`{$QW|}g~   &j|$$$, &$jq{$  Q@@&$}m[- $/~$$7qZgZ$`    L,rJL           //
//                                                                                                                     //
//             ]g]$Bg@Q4Q-"-,Q,  '$@$wZ$l     B&@wrm'$wO?,.~,r&"g$$$g]{j,C$D@&$$@$"U] `L>]pg@$$k`     |`1-]@           //
//                                                                                                                     //
//              ]g@~&$F@bVt ]-WTb. M@$gj F&,   $$@g" +-$,V]\ .M"4$$g@@`$QFAX$@W$[W}$A7M`m=$p@N`       [,+"C,L   gMm    //
//                                                                                                                     //
//               *N@@Q$$@@w@$l,gE8@4BB&Qe`,*`]*$)|xPZ"L^4 "c]>=L,*R$$$@#$Op"$$jAA$Q'[2Ag5P]P`         @ww l4&gg@$]@    //
//                                                                                                                     //
//                     `"*N@$$Q@1' CZj{$L*'=~-"~ '~L"]"QwT"``FFJ,Fj&$$$P&@, )ljUVQ7)qKgy$*` ,=+,      L`L;4&QD$hQ@@    //
//                                                                                                                     //
//               ]@$$W      '"N@gN@@@Z+Q-r]]F\y",g,w, }@"f- |>*X.wK]&&@Wj{J `}}~$Mu$$$&N   ,@-*g@    $`K 5|$Zgg@N"     //
//                                                                                                                     //
//                @/$&@Qg,      `"*B@@$$$@$g$@g$@@6g$&$@@ws`yp\x^C}wj&Qg@{]  PL*|A@&J$$-   #*.*$Q  gMl\.Y\M$@P`        //
//                                                                                                                     //
//               m@N]wjA$&@B$$@BNw,,, ``""""*****$@@$@@@@$@Kg,JlyAC$%$]@|L|$ y|[$j$QU$&    @'A]$Bg$&$4^$/@@"           //
//                                                                                                                     //
//               BgZ$4$"gr\&%A$@@$g$@@$Ng,     ,g@@$@$@$@@$@@@FUCKING.CORAL@,[@i{J&hQg$  ,@\w,4P&@%P^$$g$P             //
//                                                                                                                     //
//                 "9&g$$@pp$$$@X$Zr$@&$N%$$@$@$&N@@$@@$@@@@@@@$@jIW&V&#LL#|w+Q&QD#C@Q%N@'"4$*RNy.ZZ$@$N               //
//                                                                                                                     //
//                       ""**MW4N@ew5F+$:$C{&Q@&@@%$$$@@@$@@@$@FUCKSTEVE$$L$)|$Qg[[m}MQ$J,&/gA1Q@$&@gM                 //
//                                                                                                                     //
//                              ,,@$gy]/Z^j~"b"%$@g*p-@R@@$@$@@@@@$$ZQ@@[P}L$[gj|$RWDQy",$'gwkQ$$N@"                   //
//                                                                                                                     //
//                       ,,gg$#B$$$G" "g r$,Zs.]p-D`$b)$1$$@$@@@@@$D${Ql$$w|$JP%$$$H[[]wG|Q[Cg@P"`                     //
//                                                                                                                     //
//                g$$AR$&&&$l FZ,ECZQB$@$@$@g@wZ@Eg]WC1@$Q%$@@@@@@$@g$A@@|$I$@@F[$$AW&P|$[[$@"                         //
//                                                                                                                     //
//                *$$@Z.a-~C$,l%$g$&M*``   ``"*R&#$g@@@$#@g@@$@@@@$@$$@&$@@&&J@W$$FKF)}]!]UK                           //
//                                                                                                                     //
//                  `*MNW$$l&NP^"                   '''""R@@@@@@@@@$N&RgP@|$|Q|PQQ|QAPJYKLQ[                           //
//                                                                                                                     //
//                                                         ]@@$@@$$B&$$lRN@$$$Pg$w&$Q[`g @,$                           //
//                                                                                                                     //
//                                                          $@$@&N&RPRP*""    `"``""**""""                             //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CORAL is ERC721Creator {
    constructor() ERC721Creator("Fucking Coral", "CORAL") {}
}
