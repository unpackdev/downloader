
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Urban Archetypes
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
//    Urban Archetypes are photographic portraits of skyscrapers taken during a trip to New York City in June 2022.                  //
//                                                                                                                                   //
//    My reason for using a camera as a tool is that it allows me find simplicity, peace, and solace within the viewfinder.          //
//    Typically I am photographing calm and quiet scenes in nature, however during a trip to New York City I found myself            //
//    entranced by the overlapping geometric patterns, reflections, and organization of the skyscrapers towering overhead.           //
//    Unlike the trip a year prior, this time I had my camera.                                                                       //
//                                                                                                                                   //
//    There, in the middle of Manhattan, I was able to find that simple beauty that draws me into my viewfinder and causes           //
//    everything outside of that little box to melt away. There, in the middle of Manhattan, I found peace and solace.               //
//                                                                                                                                   //
//    Many of these photographs are presented in unconventional orientations in order break the context of standing in the           //
//    middle of the city in an effort to show you the beauty that exists outside of the literal subject– in the words of Minor       //
//    White: “One should not only photograph things for what they are but for what else they are”.                                   //
//                                                                                                                                   //
//    I hope that these photographs cause you to look closer at your surroundings to find a deeper appreciation for the often        //
//    overlooked simplistic beauty that surrounds you. Even in the most chaotic of places, there is still peace to be found.         //
//                                                                                                                                   //
//    This is a living collection that will slowly be added to as I visit New York or other large cities. I don’t know when          //
//    the next time that I visit a large city with my camera will be, or even if it will ever happen, but my intent is to            //
//    add to this collection in “blocks”, which each new block being a sampling of images from a single trip.                        //
//                                                                                                                                   //
//    Used with permission, the title of the collection was inspired by Kjetil Golid’s generative artwork collection                 //
//    “Archetype”, which these photographs reminded me of.                                                                           //
//                                                                                                                                   //
//                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract urban is ERC721Creator {
    constructor() ERC721Creator("Urban Archetypes", "urban") {}
}
