
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TJ Thorne
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                   //
//                                                                                                                                   //
//                                                                                                                                   //
//                                       >>--l>!.                                                                                    //
//                                   .v|jvXYr|}}}_>                                                                                  //
//                                  IQQQQQQLQQQCt1)[                                                                                 //
//                                 )QkZZLZQQQ0*Uj1}fx_                                                                               //
//                                IQZ*qwQ0QxxcjknLj)/f(>                                                                             //
//                                QQwW%*WQQQUf1{Y-]J{Y]}!                                                                            //
//                                QQ0&&rI:UQQ1{-,?}]i[}[>                                                                            //
//                               xQQ0OzI;/{QQJ(I  <I1~}{)`                                                                           //
//                               nQQj}[ ]/}}}>     ]{{/nQx'                                                                          //
//                              ^J}}}}}I []["  .''.' fLYQQQC?^                                                                       //
//                            `_,}``>~`!`l}  '     :uQZrj>1{Yzcz[|nzczcc}                                                            //
//                         !!." ;:    i"  :l. '  ,[+b$$@v)m$LrQ0| .UQQQQQQQQQQ0,                                                     //
//                     .,}}}-[}}_]    ;`       <~|QpW$$@Y&o$BMkl :0ZqMpa$$$$$$b                                                      //
//                  .}}}f1}{{{rQn}}}}].>'!`'   ;(QQ@$$$@Q%$$k}  'w$$$$$$$$$$$$b                                                      //
//                 -}zUc1}jUnQQQn}}}}}}}^[}^   '}!(Qh$$W$$Z|^    ,-*$$@M{_?-_u*                                                      //
//               .-)UQQQLUQQQQLn}}}}}}r-}[}<`   ldQaaaWOU1<         }1.                                                              //
//               :}/QQQQQQQQQQJ)}}}}{1)n{}}}:   ')QmvQm&}?<  `"{,fvnj                                                                //
//               }}LQQQQQQQQQQC)}}}}{u/0,n}}z    ;*QC{B)}`~  '.                                                                      //
//              ~}YQQQQQQQQQQQC)}}}}}}fXnaL/L   ,.Q$$@z};.  .                                                                        //
//              1|CQQQQQQQQQQQQz}}}/I?}+@obQQ'.  '^n8*}I   ,                                                                         //
//              1jQQQQQQQQQQQQQt}}}})j"[Q$$m01,     <}}[                                                                             //
//              ?QQQQQQQQQQQQQQU}}}}^>:1Qh$$mz}  .  >}!                                                                              //
//              [QQQQQQQQQQQQ)QQj}}}}]`.u0B$m('                                                                                      //
//              zQQQQQQQQQQQQQ/YZ/?}}}] )JZ%0}"           .                                                                          //
//              zQQQQQQQQQQQQQQ;QQ-~}}}:` 1bm}}           <I                                                                         //
//              rQQQQQQQQQQQQQQQ/vQ1;}i'   f%z}_         (c,                                                                         //
//              XQQQQQQQQQQQQQQQQnlYv,}<   -8Mu}}l`     _8t{                                                                         //
//              XQQQQQQQQQQQQQQQQQUltL",~   k$pY}}}-   '0Bh1+                                                                        //
//              XQQQQQQQQQQQQQQQQQQL-'x/    z$$QrX}}I  `.*@J]^                                                                       //
//              ,QQQQQQQQQQQQQQQQz)vQf "[:   0dY<]Jj(l`  f$m-+                                                                       //
//              iQQQQQQQQQQQz{rLQQLf}jcl `;  QQ>          %$(]                                                                       //
//              XQQQQQQQQQQQQQ{}{XLQJ{{}"    ?!           }qU;-                                                                      //
//              XQQQQQQQQQQQQQQU}}_{1{}_>'                I#mJ];                                                                     //
//              XQQQQQQQQQXQQQQQQx}}]]}__l                 O$#>}                                                                     //
//              )QQQQQQQQQY~YQQQYXz}}}{?>?.                 $$L)_                                                                    //
//              {QQQQQQQQQQQ(`cQQQLti_}}}}}  ,              1q&L]                                                                    //
//              nQQQQQQQQQQQQXl"<)ttt[  `, ^.  .            >8QJ?I                                                                   //
//              jCQQQQQQQQQQQQQn_I_>>i>,.I^,.  :             Z&qu_                                                                   //
//              XCQQQQQQQQCLQQJQX{}}[-[[!.:                  :$#U-[                                                                  //
//             ^YQQQQQQQQQQJ1u{}1}}}[,}l ,."                  qd%Q[                                                                  //
//             <LQQQQQQQQQQQQQz|rf({>~?I"":^                  i$0qu_                                                                 //
//             1XJQQQQQQQQQQUvvt11}}}}}]<]t}}}}. x            .0%oL{`                                                                //
//            kUhkQ@a8@$@$$@@MQQn}}}}}[i}}}}}"]^`              j%QL>[                                                                //
//           ~LQQQQQQQQQQd$$B@0Q)}}}}}-`}}}+>}Il_-              $kwQXi                                                               //
//           zQQQQQQQQQ0Q$$$MOQQXUX}}{}! l}}}l_++:_             ;&$WQf'                                                              //
//           QQQQQQQQQaMQ%$$$$$BmQ}}fQ}}.`[}}^--}})_            ^kQ&O_+                                                              //
//           QQQQQQwq0QQQ@$$$$$$$0|LQQ}}}}}}}_- +}l;             zBQ@u}.                                                             //
//           zQQQQhoM$$8Mp$$$$$$$MQw*mot}}}]:-}~<}I]`             @pQa1~                                                             //
//           ?QQQQkWQZ8$$$$$$$$$$$woh$ox}}<}}}}?`?<[^             noQOQ]`                                                            //
//           iLQQb$$8QQb$$$$$$$$$$$$$$%x}>?}}}}},`I`.             'B0QO]v                                                            //
//            J@mB$$$#QO$$$$$$$$$$$$$$@m{>I}}}{c!^<?i              n8QZC(i                                                           //
//            Uh$$$$$%m0W$$$$$$$$$$$$$$d{,]/)}}}/tl![+I            :B0QCI_                                                           //
//             O%$w*Q$dQk$$$$$$$$$$$$$$h{'[Q(}}}}-;`},              koQZ0),                                                          //
//             QQ$wQQmbQQ@$$$$$$$$$$$$$d{i(QC}}"_ l[. l              $OOZ({                                                          //
//            <Q%mOh$$$#Qw*$$$$$$$$$$$@q{}CQC}!}}. '+_               u&QOL)_                                                         //
//            ]Q%WwB*o%%QQh$$$$$$$Q X$$m}xQQ(}i}[[^   !'             }B0&Zj]`                                                        //
//            UQ%$p@h8$MQQQ@$$$$$0  ;BBv{QQJ)};}}}!   .               ##QMQ1!                                                        //
//            JQ%$$qqQO@8QQ%B$$$B+   U$bQQQv{}}}}}}    -              u@mQ0C/                                                        //
//            JQQ$$8WQQQQQQQh$$$w.   .$$$@Ov}}}}_}[  .i.              (Z0OoQj?                                                       //
//           .JQQqB$$&QQQQQQb@$$-     I$$$BL(?`+}}}: ;^               /j1}[]c1{t[+++l                                                //
//           :CQQQQwB$dQQQQQQZ$v       z$$O0/}}-+;}}nL1?              xQLt|"cJ!UuCQQQQQ/"'                                           //
//           >MbQ&mQo&8QQQp&Q%d"       ^@$$M0QQc,    /                YQO)/[uY~->}1|uQQQQQJi                                         //
//           {d#@&$$#aaaaaaa@$)          "JQQQQ},    'l              ?Qv((/[}Qc}/}}}}}}}xUQQUl                                       //
//        <f{t)|nJpWWWWWdOJutzIl-fu~>ii>ii>QQQQ},     }<ii}iiiiii!iizQQLr11//(wL/}}}}}}}[}}jXYYu(l,:+}l;                             //
//      `}}}}(LY)}}/QQQQL{)}}}1JULQQQQQQQQQQQLf}_     l}{{|11YQQUQQQQQQQQQQQQZ$8{Ln{}{}}}}}}}}{}{_[,]}: !}+}> _-                     //
//      u1}}}}}t/}}}}}}}}}}}}}[})XQQQQQQQLf[!l:_--    l]   .,,:-{(QQQQQQQQQQQQmdzi}}}}zQQQQYQLLzz}x}[~?}}}]l}<}}}?}_}]]+<!"'         //
//      QQzurCQQt}}}trrj|j|1xJuLf/XJQQQU[   !~I}}};   l}         ;>}}tcQQXQQQQQzQtvQJn_i^;ii[tcQQQQCzvvt]}}}}}{jrrrrrrj1}?~~~>'      //
//      :XQQJQQQQQQzz((QQYvcYJQQQQcQz|]l              l}!              '?}{}}}}_.'                 i?]}}}{(1|]??]~^                  //
//         .":>[;""""`.         .^,1QQQCYc<                            '. ..'   .                                                    //
//                                       ^+_1cxnt{_I^                                                                                //
//                                                                                                                                   //
//        "$$$$$$$$$$$$#    Y$C      Y$$$$$$$$$$$$) z$u       i$#     `($$$$$$x^     a$$$$$$$$O'   }$8_       d$C   $$$$$$$$$$X      //
//             lW$<         U$C           !$$       z$u       i$#    *$h-`  `[B$#    a$)    .C$B^  }$$$Z`     d$C   $$o              //
//             lW$<         Y$C           !$$       z$u       i$#  _B$c        u$$'  a$)      $$$  }$kv$$c`   d$C   $$o              //
//             lW$<         Y$C           !$$       z$$$$$$$$$$$#  x$$:        ^$$c  a$u+++++L$#`  }$k"'U$$~  d$C   $$$$$$$$$J       //
//             lW$<         B$C           !$$       z$u       i$#  x$$:        ^$$"  a$$$$$$$c'    }$k,  `O$B'd$C   $$o              //
//             lW$<        ,$$v           !$$       z$u       i$#   ]$$z^    `C$$!   a$)    U$@~   }$k"    -&$$$C   $$o              //
//             lW$<  :o$$$$$#-            !$$       z$u       i$#     uo$$$$$$pc     a$)     [$$f  }$k"      r%$C   $$$$$$$$$$$      //
//                                                                                                                                   //
//                                                                                                                                   //
//    For the most part my approach to nature photography is based in literal representation. Even if the resulting photograph       //
//    would take on more of an abstract form due to isolation and omission of the surrounding environment, the experience of         //
//    photographing it and developing a relationship with it is always based in reality and a sense of photographing a specific      //
//    THING whether it be a play of light, a unique moment in time, or an interesting subject. It still is and always will be        //
//    because at the base of everything, that's the primary way that I interact with and experience nature.                          //
//                                                                                                                                   //
//    This explorational series comes from a different emotional and mental place. These photos were taken not with the intent       //
//    of that literal representation mentioned above but from a more visceral place, based more in an emotional reaction to          //
//    what and where I'm photographing and putting pieces of the experience together into a single frame.They’re the result of       //
//    a need to bring more fun and less pressure into my work. Honestly, it's hard to describe. But when I photograph in this        //
//    way, I have noticed a distinct shift in the way that I am interpreting the environment, both mentally and emotionally,         //
//    and that carries over into the way that I process the photo. Everything about making these photos feels... freeing.            //
//                                                                                                                                   //
//    I feel this approach calling to me more and more often lately. Photography has always been my antidote to the demons in        //
//    my life and I’ve been busy battling a lot of them recently. By letting myself tap into a more relaxed and experimental         //
//    approach I am able to push the boundaries on how I interact with the landscape, appreciating it for more than its literal      //
//    inherent beauty and diving deeper into the things that make it special. It allows me to become more in touch with what         //
//    ELSE nature is and what else it can be, further strengthening my relationship with it.                                         //
//                                                                                                                                   //
//    Another distinction between these images and the images in my other galleries is that often I'm not even sure how I made       //
//    them. Sure I know which techniques I used, but in the process of taking the photograph I am blending different types of        //
//    photos with different settings in-camera and not paying attention to the specific process. I'm mixing and matching and         //
//    switching and experimenting. In my usual interactions with nature I am extremely cognizant of every decision that is           //
//    being made: which settings I'm using, why I'm using those settings, the composition, and more. There is INTENT behind          //
//    every single decision and I make them consciously despite the subconscious emotional connection and love with the subject      //
//    that I’m photographing. These images are a departure from that conscious decision making.                                      //
//                                                                                                                                   //
//    All of these images are single frames made in camera using one or more creative camera techniques. I've purposefully           //
//    left out any description of the techniques, the literal subject (though many of the subjects and techniques are easily         //
//    identified), and the context in an effort to not cloud the emotional response to the images with preconceived attachments.     //
//    If you find these images interesting or if they elicit emotions within you, I invite you to explore them, spend some time      //
//    with them, and create your own journey.                                                                                        //
//                                                                                                                                   //
//                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract fgmnt is ERC721Creator {
    constructor() ERC721Creator("TJ Thorne", "fgmnt") {}
}
