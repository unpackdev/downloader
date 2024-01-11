
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Falling Stars Edition - by TJ Thorne
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//                                       >>--l>!.                                                                                      //
//                                   .v|jvXYr|}}}_>                                                                                    //
//                                  IQQQQQQLQQQCt1)[                                                                                   //
//                                 )QkZZLZQQQ0*Uj1}fx_                                                                                 //
//                                IQZ*qwQ0QxxcjknLj)/f(>                                                                               //
//                                QQwW%*WQQQUf1{Y-]J{Y]}!                                                                              //
//                                QQ0&&rI:UQQ1{-,?}]i[}[>                                                                              //
//                               xQQ0OzI;/{QQJ(I  <I1~}{)`                                                                             //
//                               nQQj}[ ]/}}}>     ]{{/nQx'                                                                            //
//                              ^J}}}}}I []["  .''.' fLYQQQC?^                                                                         //
//                            `_,}``>~`!`l}  '     :uQZrj>1{Yzcz[|nzczcc}                                                              //
//                         !!." ;:    i"  :l. '  ,[+b$$@v)m$LrQ0| .UQQQQQQQQQQ0,                                                       //
//                     .,}}}-[}}_]    ;`       <~|QpW$$@Y&o$BMkl :0ZqMpa$$$$$$b                                                        //
//                  .}}}f1}{{{rQn}}}}].>'!`'   ;(QQ@$$$@Q%$$k}  'w$$$$$$$$$$$$b                                                        //
//                 -}zUc1}jUnQQQn}}}}}}}^[}^   '}!(Qh$$W$$Z|^    ,-*$$@M{_?-_u*                                                        //
//               .-)UQQQLUQQQQLn}}}}}}r-}[}<`   ldQaaaWOU1<         }1.                                                                //
//               :}/QQQQQQQQQQJ)}}}}{1)n{}}}:   ')QmvQm&}?<  `"{,fvnj                                                                  //
//               }}LQQQQQQQQQQC)}}}}{u/0,n}}z    ;*QC{B)}`~  '.                                                                        //
//              ~}YQQQQQQQQQQQC)}}}}}}fXnaL/L   ,.Q$$@z};.  .                                                                          //
//              1|CQQQQQQQQQQQQz}}}/I?}+@obQQ'.  '^n8*}I   ,                                                                           //
//              1jQQQQQQQQQQQQQt}}}})j"[Q$$m01,     <}}[                                                                               //
//              ?QQQQQQQQQQQQQQU}}}}^>:1Qh$$mz}  .  >}!                                                                                //
//              [QQQQQQQQQQQQ)QQj}}}}]`.u0B$m('                                                                                        //
//              zQQQQQQQQQQQQQ/YZ/?}}}] )JZ%0}"           .                                                                            //
//              zQQQQQQQQQQQQQQ;QQ-~}}}:` 1bm}}           <I                                                                           //
//              rQQQQQQQQQQQQQQQ/vQ1;}i'   f%z}_         (c,                                                                           //
//              XQQQQQQQQQQQQQQQQnlYv,}<   -8Mu}}l`     _8t{                                                                           //
//              XQQQQQQQQQQQQQQQQQUltL",~   k$pY}}}-   '0Bh1+                                                                          //
//              XQQQQQQQQQQQQQQQQQQL-'x/    z$$QrX}}I  `.*@J]^                                                                         //
//              ,QQQQQQQQQQQQQQQQz)vQf "[:   0dY<]Jj(l`  f$m-+                                                                         //
//              iQQQQQQQQQQQz{rLQQLf}jcl `;  QQ>          %$(]                                                                         //
//              XQQQQQQQQQQQQQ{}{XLQJ{{}"    ?!           }qU;-                                                                        //
//              XQQQQQQQQQQQQQQU}}_{1{}_>'                I#mJ];                                                                       //
//              XQQQQQQQQQXQQQQQQx}}]]}__l                 O$#>}                                                                       //
//              )QQQQQQQQQY~YQQQYXz}}}{?>?.                 $$L)_                                                                      //
//              {QQQQQQQQQQQ(`cQQQLti_}}}}}  ,              1q&L]                                                                      //
//              nQQQQQQQQQQQQXl"<)ttt[  `, ^.  .            >8QJ?I                                                                     //
//              jCQQQQQQQQQQQQQn_I_>>i>,.I^,.  :             Z&qu_                                                                     //
//              XCQQQQQQQQCLQQJQX{}}[-[[!.:                  :$#U-[                                                                    //
//             ^YQQQQQQQQQQJ1u{}1}}}[,}l ,."                  qd%Q[                                                                    //
//             <LQQQQQQQQQQQQQz|rf({>~?I"":^                  i$0qu_                                                                   //
//             1XJQQQQQQQQQQUvvt11}}}}}]<]t}}}}. x            .0%oL{`                                                                  //
//            kUhkQ@a8@$@$$@@MQQn}}}}}[i}}}}}"]^`              j%QL>[                                                                  //
//           ~LQQQQQQQQQQd$$B@0Q)}}}}}-`}}}+>}Il_-              $kwQXi                                                                 //
//           zQQQQQQQQQ0Q$$$MOQQXUX}}{}! l}}}l_++:_             ;&$WQf'                                                                //
//           QQQQQQQQQaMQ%$$$$$BmQ}}fQ}}.`[}}^--}})_            ^kQ&O_+                                                                //
//           QQQQQQwq0QQQ@$$$$$$$0|LQQ}}}}}}}_- +}l;             zBQ@u}.                                                               //
//           zQQQQhoM$$8Mp$$$$$$$MQw*mot}}}]:-}~<}I]`             @pQa1~                                                               //
//           ?QQQQkWQZ8$$$$$$$$$$$woh$ox}}<}}}}?`?<[^             noQOQ]`                                                              //
//           iLQQb$$8QQb$$$$$$$$$$$$$$%x}>?}}}}},`I`.             'B0QO]v                                                              //
//            J@mB$$$#QO$$$$$$$$$$$$$$@m{>I}}}{c!^<?i              n8QZC(i                                                             //
//            Uh$$$$$%m0W$$$$$$$$$$$$$$d{,]/)}}}/tl![+I            :B0QCI_                                                             //
//             O%$w*Q$dQk$$$$$$$$$$$$$$h{'[Q(}}}}-;`},              koQZ0),                                                            //
//             QQ$wQQmbQQ@$$$$$$$$$$$$$d{i(QC}}"_ l[. l              $OOZ({                                                            //
//            <Q%mOh$$$#Qw*$$$$$$$$$$$@q{}CQC}!}}. '+_               u&QOL)_                                                           //
//            ]Q%WwB*o%%QQh$$$$$$$Q X$$m}xQQ(}i}[[^   !'             }B0&Zj]`                                                          //
//            UQ%$p@h8$MQQQ@$$$$$0  ;BBv{QQJ)};}}}!   .               ##QMQ1!                                                          //
//            JQ%$$qqQO@8QQ%B$$$B+   U$bQQQv{}}}}}}    -              u@mQ0C/                                                          //
//            JQQ$$8WQQQQQQQh$$$w.   .$$$@Ov}}}}_}[  .i.              (Z0OoQj?                                                         //
//           .JQQqB$$&QQQQQQb@$$-     I$$$BL(?`+}}}: ;^               /j1}[]c1{t[+++l                                                  //
//           :CQQQQwB$dQQQQQQZ$v       z$$O0/}}-+;}}nL1?              xQLt|"cJ!UuCQQQQQ/"'                                             //
//           >MbQ&mQo&8QQQp&Q%d"       ^@$$M0QQc,    /                YQO)/[uY~->}1|uQQQQQJi                                           //
//           {d#@&$$#aaaaaaa@$)          "JQQQQ},    'l              ?Qv((/[}Qc}/}}}}}}}xUQQUl                                         //
//        <f{t)|nJpWWWWWdOJutzIl-fu~>ii>ii>QQQQ},     }<ii}iiiiii!iizQQLr11//(wL/}}}}}}}[}}jXYYu(l,:+}l;                               //
//      `}}}}(LY)}}/QQQQL{)}}}1JULQQQQQQQQQQQLf}_     l}{{|11YQQUQQQQQQQQQQQQZ$8{Ln{}{}}}}}}}}{}{_[,]}: !}+}> _-                       //
//      u1}}}}}t/}}}}}}}}}}}}}[})XQQQQQQQLf[!l:_--    l]   .,,:-{(QQQQQQQQQQQQmdzi}}}}zQQQQYQLLzz}x}[~?}}}]l}<}}}?}_}]]+<!"'           //
//      QQzurCQQt}}}trrj|j|1xJuLf/XJQQQU[   !~I}}};   l}         ;>}}tcQQXQQQQQzQtvQJn_i^;ii[tcQQQQCzvvt]}}}}}{jrrrrrrj1}?~~~>'        //
//      :XQQJQQQQQQzz((QQYvcYJQQQQcQz|]l              l}!              '?}{}}}}_.'                 i?]}}}{(1|]??]~^                    //
//         .":>[;""""`.         .^,1QQQCYc<                            '. ..'   .                                                      //
//                                       ^+_1cxnt{_I^                                                                                  //
//                                                                                                                                     //
//        "$$$$$$$$$$$$#    Y$C      Y$$$$$$$$$$$$) z$u       i$#     `($$$$$$x^     a$$$$$$$$O'   }$8_       d$C   $$$$$$$$$$X        //
//             lW$<         U$C           !$$       z$u       i$#    *$h-`  `[B$#    a$)    .C$B^  }$$$Z`     d$C   $$o                //
//             lW$<         Y$C           !$$       z$u       i$#  _B$c        u$$'  a$)      $$$  }$kv$$c`   d$C   $$o                //
//             lW$<         Y$C           !$$       z$$$$$$$$$$$#  x$$:        ^$$c  a$u+++++L$#`  }$k"'U$$~  d$C   $$$$$$$$$J         //
//             lW$<         B$C           !$$       z$u       i$#  x$$:        ^$$"  a$$$$$$$c'    }$k,  `O$B'd$C   $$o                //
//             lW$<        ,$$v           !$$       z$u       i$#   ]$$z^    `C$$!   a$)    U$@~   }$k"    -&$$$C   $$o                //
//             lW$<  :o$$$$$#-            !$$       z$u       i$#     uo$$$$$$pc     a$)     [$$f  }$k"      r%$C   $$$$$$$$$$$        //
//                                                                                                                                     //
//                                                                                                                                     //
//    Taken on October 7, 2014 Falling Stars is the very first Ebb and Flow ever created that ended up in my portfolio. It is          //
//    a photo of direct light glistening off the windblown surface of Crater Lake, Oregon and aside from a crop, this image is         //
//    presented as photographed from the northeastern rim near Palisade Point.                                                         //
//                                                                                                                                     //
//    2014 was a pivotal year in my creative journey and photography career. I had taken a chance and applied for an                   //
//    Artist-in-Residency appointment at Crater Lake National Park. To my surprise, I was accepted into the program and spent          //
//    two weeks in the park, opting for October in the hopes that I would have a better chance of the weather systems moving           //
//    through and hopefully, the first snow of the year. The summers and early autumns in Oregon are dominated by mostly clear         //
//    skies and this can make for some challenging conditions and light to photograph in. The entire first week was nothing but        //
//    hot temperatures and cloudless skies. I was disheartened at first, as I let my hopes and expectations dictate my approach        //
//    and mindset, but the more time that I spent just sitting and observing, the more that I realized that beauty was                 //
//    everywhere around me– even in the seemingly mundane dirt, rocks, and water that make up the park. It wasn’t a change of          //
//    conditions that I needed, it was a change in mindset and approach. I needed to dig deeper and explore that beauty through        //
//    my camera to find solace and gratitude that I had the opportunity to exist right then and there and I needed to place the        //
//    value on the fact that I got to experience those moments. That switch of mentality is what made me the photographer I am         //
//    today and has played a crucial role in the work that I produce and the importance that it holds for me. I needed that            //
//    first week as a lesson and I was lucky enough to be blessed with the more favorable conditions I initially hoped for             //
//    during the second week of the residency when I was able to sit in solitude while watching low clouds pour over the rim of        //
//    the caldera and also experience the first snow of the year, which dropped a couple of inches in the park, completely             //
//    transforming it into a winter wonderland.                                                                                        //
//                                                                                                                                     //
//    Being a co-parent with a stressful and demanding full-time restaurant management job, I rarely had opportunities for             //
//    anything more than a day trip to escape to nature and fill my soul. This residency appointment was the first time that I         //
//    got to forget about work meetings and responsibilities and completely immerse myself in my creative pursuits. It was hard        //
//    for me to accept at first. The guilty burdening thoughts of being undeserving of this experience and that I should be back       //
//    in the city with my son or slaving away with my kitchen team were overwhelming, and I’m not sure I was ever able to get away     //
//    from them. Because of that I made sure to wring every bit of gratitude out of the experience and I still highly value my         //
//    time there, even all these years and dozens of visits later.                                                                     //
//                                                                                                                                     //
//    And I learned a few things too:                                                                                                  //
//                                                                                                                                     //
//    1. I learned that following my creative passion was something that I wanted to do full-time and I made it my goal to work        //
//    towards being a full-time photographer. I gave myself a 5 year timeframe to achieve this goal and exceeded that goal by          //
//    going full-time in October of 2017.                                                                                              //
//                                                                                                                                     //
//    2. It taught me that there is no such thing as bad light and that beautiful things can happen all day long. This mindset         //
//    completely shifted the way I approach photography and ever since this trip I have explored midday light with purpose and         //
//    have learned how to use it to my creative advantage. Many of my most personal images were made using direct midday light.        //
//                                                                                                                                     //
//    3. I learned to place 100% of the value in the experience– that coming back with a photo to represent that experience is a       //
//    gift, but not the goal.                                                                                                          //
//                                                                                                                                     //
//    4. I learned that light on water is one of my favorite subjects– one that has turned into an obsessive passion which has         //
//    brought me the solace and comfort I need in this world. Though my first record of photographing direct light on water            //
//    happened in 2011, Falling Stars is the photograph that sparked a conscious exploration of the subject that eventually led        //
//    to the Ebb and Flow Collection and philosophy, something that has become the most personally significant body of work I          //
//    have ever created.                                                                                                               //
//                                                                                                                                     //
//    This image is important to me. It speaks to me of reaching for the stars and reminds me of one of the most impactful             //
//    experiences of my photography career. I wouldn’t be the photographer I am today without that experience and I’m happy            //
//    that I have this photo to represent it.                                                                                          //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract stars is ERC721Creator {
    constructor() ERC721Creator("Falling Stars Edition - by TJ Thorne", "stars") {}
}
