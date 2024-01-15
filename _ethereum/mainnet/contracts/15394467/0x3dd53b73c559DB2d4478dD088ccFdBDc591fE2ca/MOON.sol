
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: M O O N
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    rrrxxxxxxxxxxxnnnxxxxxxxxxxxxxxxxxrxxxnuuvz$$$$$$@vvunnxxxrjrrrrrrxrxxrrrxrrxrrrxxnuv#$$$$$$Bvunnrrrjrxnnuv%$$$$$$Mvvunxxxrjjrrrrrxxxxxxxxxrrrxrxxnuuv@$$$$$$*vunxxrrrrrrrrrrrxxrrrrrrrrrjjjrjjffjffffff    //
//    xxxxxxxnxxxxxxnnxxxxxxxxxxxxxxxrxxxxxxnuuv*$$$$$$&vunnxxxxxxxxrxxrrrrrrrrxxxxxrrrxnuvM$$$$$$trunf`>jr(""?n\v$$$$$$WvuunxxxrrrrrrrrxxxxxxxrxxxrxxxxnuuvW$$$$$$#vunnxrrrrrrxrrrrrrrrrrxxxxrrrjjjjjjjjjjjfj    //
//    xxxxxxxxxxxxxxxnxxxxxxxxxxxxxxxxxxrxrxnuuv8$$$$$$cvunnnxxxxxxxrrxxrrrrrxrxxrrxxrxnnuv%$$$$$B-</r"`',j)^`<n]>&$$$$$Bvvunxxrrrrrrrrrxxrxxrxxxxxxrrxxxnuuc$$$$$$8vunnxxrxrrrrrrrrrrxxrxxrxxrrrjjjjjjjjjjfjj    //
//    xxxxnxxxxxxxxxxxxxxxxxxxxxnnxxxxxrrrxxxnuz$$$$$$&vunnnnxxxxxxxrrxxxrrrxxxxxrrxrrxxuu#$$$$$$Mvunxrrjjrrrxxnuu#$$$$$$#vunxxrrrrrjrrrxxxrxrxxxxxxxxxxxnnuvW$$$$$$zvunxxrrrrrrrrrrrxxxrxxxxxxxxxrrrrrjrjjjjf    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxrjjxxnnu%$$$$$$cuunnnnxxxxxxxrrrrrrrrrrrxxrrrxxnnuvB$$$$$@vunnxxxrrrrrrxnnuvB$$$$$@cunnnxxrrjrjrxxxrxrxxxxxxxrrxxxxnnuc@$$$$$%vunnxxrrrrrrrxrrrxxrxxxxxxxxxxxxxxrrrrrjj    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxrrrjjjrxnuM$$$$$$&vunnnxxxxxxxxxxrrrrrrrrrxxrrrrxxnuv&$$$$$$MvunxxxxxrxxxrxxxnuM$$$$$$8vuunxxrrjjrrxxrrxrxxxxxxrrrxxxxxnuvW$$$$$$Wvunxxrrrrrrrxrrxxxxxrxxxxxxxxxxrxxxrrrrj    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxrrjjjjrxnz$$$$$$$zvunxxxxxxxxxxxxxxrrjjrrrrrrrrrxnuu#$$$$$$$cvunxxxrxxxxrrrxxnuv$$$$$$$Mvunnxrrrrrrxxrrrrrxxxxxxxxxxxxxxnuz$$$$$$$*vunxxxrrrrrrxxxxxxxxxxxxxxxxxxxrxxrrrrj    //
//    xxxxxxxxxxxxxxxxxxxxxxnxxxxxxxrrjjrrxnv@$$$$$$%vuunxrxxxxxxxxxxxrxrrjrrjrrrrrxxnuz$$$$$$$8vunxxxxrxxxxxrxrrxnu&$$$$$$$zvnnxxrrrrrxxrrrrrrxrxxxxxxxxxxnnuv%$$$$$$@cunxxxxrrrrxxxxxxxxxxxxxrxxxxxxxrxrrrrr    //
//    xxxxxxxxxxrxxrxxxxxxxxxxxxxxrxxxrrrxnu%$$$$$$$MvunnxrrxxxxxxxxxxxxxrrrjjrrrxxnnucB$$$$$$$*vunxrxrxxxrxxxrrrxnuz$$$$$$$Bcunnxrrrrrxxrxrrrrrrrrxxrxxrxxxnuv#$$$$$$$%vunnxxxxxxxxxxxxxxxxxxxxxxrxxxxxrrrrxx    //
//    xxxxxxxxxxrxrrxxxxxxxxxxxxxxxxxxrrxnuW$$$$$$$@vuunnxxxxxxxxrxxxxxxxxrrrrrrrxnnuv8$$$$$$$Bvunxrrrxxxxxxxrrrrxnnv%$$$$$$$%vunxrrrrjrxrrrxxrrrrrxrrrrrxxxxnuv@$$$$$$$&vunxxxxrxxxxxxxxxxxxxxxxxxxrxxxrrxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxrxxxxrrjxxxxnuuz$$$$$$$$Wunnxxxxrxxxxrrxrxxxxrxrrrrrxxxnuu#$$$$$$$$Mvunxxrrxxxxxrrxxrrxxnu#$$$$$$$$MvunxrrrrrrrrxrrxxxxxxxxrrrrrxxnuvW$$$$$$$$*uunxxxxxxxxxxxxxxxxxxxxxxrxxrrxxxxxx    //
//    rxxxxxxxxxxxxrxxxxxxxrrrrrrjrrxxxnuv@$$$$$$$$cunxrrrjrrxxrrrrrrrrxxxrrrrxnxnuuc$$$$$$$$@cvunxrrrrxxxxrrxrrrrxnnv@$$$$$$$$zunnxrrjrrrrxxxrrxxxrxxrrxrxxxnuuc$$$$$$$$@cunnxxxxxrxxxxxxxxxxxxxxxrxxxxxxxrxx    //
//    xxxrrxxxxxxxxxxrxrxrrrrrrrrrxrrrxnu&$$$$$$$$&uunxxrrrjjrrrrrrjrrrrrrrxrrxnnuuv%$$$$$$$$WvunxrrrrrrrrrxrxxxxrxxnvM$$$$$$$$Bvunnxrjrrrrrrxrrxxrrxxrrxxxxxnnuv&$$$$$$$$8vunnxxxrxxrrrrrrxxxrrxxxrrrxxxxxxxx    //
//    rjxrrxrxxxxxrxxxrrxrxxrxxxrrrxxxnuc$$$$$$$$$cunnxxrrjrjjjjjjjjrrrrrrrrxrxnnuv*$$$$$$$$$cuunxrjffjfjjrrrrxxxrrxnuv@$$$$$$$$*vunxrrrrrrrrxxrrrrxrxrrrxxxxxnuuc$$$$$$$$$zuunxxrrrrrrrrrrxxxxxxrrrrxxxxxxxxx    //
//    jxxxxxxxxxxxxxrrjjrxxxxxxxrrrxxxnu&$$$$$$$$%unnxxrrjjrrrrrrrrrrrxxxrrrxrxnnuv%$$$$$$$$&vunnxrjf/ttffjrrxxxrrrxnuvW$$$$$$$$%vuunxrrrrrrrxxrrrxrxxxrrxrxxxnnuv8$$$$$$$$&vunnxrrrxrrrrrrrrrxrxrrrxrxxxxxxxx    //
//    jxxxxxxxxxxxxxrrrrrxxxxxxxrrrxxnnv$$$$$$$$$Munxxrrrrrrrrrrrxrrxxxxxrjrrxxxuu*$$$$$$$$$*vunnxrrf/ftfjjxxxxxxrrxnuv*$$$$$$$$$*vunxrrjrjrxxxrxrrrrxrrrrrrrxxnuu#$$$$$$$$$cuunxxxxxrrjrxrxrrrrrrrxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxrrrrrxxrrjjrxnuM$$$$$$$$$cunnxxrrrrxrrrrrrrrxrrrxrrjrxxxnu&$$$$$$$$$vvunxxxxrjjjjrrxxxxxrrrxxnuv@$$$$$$$$8vuuxrjrrrrrxxrxrrrrrrrrrrrrxxnnuv$$$$$$$$$Wvunnxxxrrrrrxxxxrrrrxxxxxxxxxxxxx    //
//    xxxxxxxxxrrxxxxxxxxxrrrrxrrrrxnnuB$$$$$$$$@vunxxrrrrrrrrrrrrrrxxxrxrrrrrrxnu@$$$$$$$$Bvuunxxxxxxrrxrrxxrxxrrrrxnuv%$$$$$$$$$vunxrrrrrrxxrrrrrrrrrrrxrxrrxnnuv@$$$$$$$$Bvunnxxrrrrrrxxxrjjrrxxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxxrrxxxxxnnv$$$$$$$$$@vunxxxrrrrrrxxrrrrrxxrrrrrrrxxnuc$$$$$$$$$%vunnxrxxxxxxxxrrxxxrrrrrxnuv8$$$$$$$$$zunxrrrrrrxrrrrrrrrrrrrxxrrxxxnuvB$$$$$$$$$vunnxxjrrrrrrrrrrrrxxxxxxxxxxxxxx    //
//    rxxxnnxxxxxxxxxxxxxxxxxxxxxxxnnuc$$$$$$$$$@vunnnxxrrrrrrxxrrrrrrrrrrrrrxnnu*$$$$$$$$$%vunnxxxxxxxxxxrxxxrrrrjrxnuv8$$$$$$$$$#unxxrrrrrrrrrrrrrrrrrrxrxxxxxnuvB$$$$$$$$$zunxxrrrjjjjrrrrrrxxxxxxxxxxxxxxx    //
//    rxxxxnxxxxxxxxnxnxxxxxxxxxxrxnnuv$$$$$$$$$@vunnxxxrrrrrrjrrrrrrrrrrrrrrxnnuz$$$$$$$$$Bvunnxxxxxxxxxrrxxxxrrjrxxnuv%$$$$$$$$$zunxxrrrjrrrrrrrxxxrrrrrrxrrxnnuv@$$$$$$$$$cunxrrjjjjjrrrxxxxxxnxxxxxxxxxxxx    //
//    xxxxxxxxxxxxxxxxxxxxxxrrrrrxxnnuv%$$$$$$$$$*unnxxxxrrrrrrrrrrrrrjjrrrrrxnnuv@$$$$$$$$$zunnxxxrxxrrrrrxrrxrjjjxnnuc$$$$$$$$$@vunxrrjrjjrjrrrrrrxrrrrrrrrxxnuuz$$$$$$$$$%vunxrjjjjjjrrxrrxxxxxxxxxxxxrxxrr    //
//    xnnxxnxxxxxxrxxxxxxxxxxrrrrxrxnnuM$$$$$$$$$BvunxxxrrrrrrrrjrjjjjjjrrjrrxxnnuW$$$$$$$$$8vunxxxrrrrjrrxrrrrrjjrxnuv&$$$$$$$$$&unxrrjjjjjrrrrrrrrrrrrrrrjrxnnuv%$$$$$$$$$Munnxrjjjjjjrrxxxxxxxxxrrrxxrrrrrr    //
//    xnnnnnnnnxxxrrxxrrrrxxxxrrrrxxnnuc@$$$$$$$$$Mvunxxxrrrrrrrjjjjjfjjjjrjjrrxnnc$$$$$$$$$$*unxxxrrrrrrrrrrrrrrrxxuvz$$$$$$$$$$cunxrrrjjrrrrrrrrrrrjrrjrrrrxnuu#$$$$$$$$$@cunxrrjjrrjrrrxxxxxxxxxrrrrrrrrjrj    //
//    xxnnxxxxxxxxxxxxxrrrrrxrrrrrrxxnnu*$$$$$$$$$$*vunxrrrrrrrrjjjjjffjjjjjjjjrxnu#$$$$$$$$$@zunxxxxrrrrrrjrrrrrxnnuc@$$$$$$$$$Munnxrjjjjrrrrrrjrrrjjjjjrrrxnuuz$$$$$$$$$$*unxrrjjrrrrrrrrxxxxxxxrrrrrrjfffff    //
//    xxxxxxrrrrxxxxxxxxxrrrrrxrrrrrxxxnuM$$$$$$$$$$Mvunxxrrrrjjffjjjjjfffjjjfjrrxnu&$$$$$$$$$@*vunxxxrrrrxrrrrrxnuu*@$$$$$$$$$&unnxxrjjjrrrrrrjjjjjjjfjjrxnnuu#$$$$$$$$$$Munnxrjjjrjrrrrrrrrrxxxxxxxrrrjftt/t    //
//    rrrrrxxrrxxxxxxxxxxxxxrrrrrrjrrrxxnuW$$$$$$$$$$8vunxxxrrjfffjjjjjjjjjjffjjrrxnv8$$$$$$$$$$WvunnxxxrrxxrrxxxuuM$$$$$$$$$$%vunxxrjfjjjrrrrjjffjfjjjrrxxnuv&$$$$$$$$$$&uunxrrrjjjrrrrrrrrrrrrxxxxxrrrffftft    //
//    rrrjrrrxrxxxxxxxxrxxxxxrrrrrrrjrxrxnuW$$$$$$$$$$@*uunxxrrjjfjjjjjjjjjjjjjjjrxxnu8$$$$$$$$$$Bzuunnxxxxxxxnnuc%$$$$$$$$$$8vunxxrrjffjjjrjjjjjjjjjjrxxxnuzB$$$$$$$$$$&unxxrrjrjjrjjrrrrrjrrrrrrrrrrrjjffjff    //
//    xxxrrxrrxrrrrxrxxrxxxxrxxrrrrrrrrrxxnuM$$$$$$$$$$$&vunxrrjjfjjjfjfjfjjjjjffjrrxnuW$$$$$$$$$$$WvunxxxnxnnuuM$$$$$$$$$$$&unnxxrjjfffjjjjjfjjrjjjjjxxnuv&$$$$$$$$$$$Munnxrrjrjrrrrjrjrrjrrrrrrrjjrjjffftfjf    //
//    xnnxxxxxxxxrrrrrrrrrxxxxxxrrrrrrrrrrxnuz@$$$$$$$$$$@#unxxrjjffjjfffffjjjfffjjrrxnu*@$$$$$$$$$$B*unxnnnuuzB$$$$$$$$$$$#unxxrjjjfffffjjjfjjjjjjjrxxnu*@$$$$$$$$$$@zunxxxrjjjrrrrrjjrjrjrjjjfffjjjjrfffjfjf    //
//    xxnnnxxxxxxxxxxxxxxrrrrrrrrrjrrrrrrrrxxnv&$$$$$$$$$$$%cnxrjjjjffffjfjjjjffffjjrrrxuv8$$$$$$$$$$$&vuuuuv&$$$$$$$$$$$8cuxxxrjjjffffffffjjjjjjjrrxnuv8$$$$$$$$$$$&vnnxxrrjjjjjjjjjjjjffjjjjjffjjjjjjjjjjjfj    //
//    xxxnnnxxxxxrxxxxrxrxxxrrrrjjjrjjjjjjjjjxxncB$$$$$$$$$$@#nxxrrjjffffjfjjjfffffffjjrxnu*@$$$$$$$$$$@#vv*%@$$$$$$$$$@*uuxrrrjjfjffftjfffjjjjjrrxxnu#@$$$$$$$$$$Bzunxxxrrjjffjfjjjjfjjffjjfjjjjjjjjjjjjjrjjj    //
//    xnxnxxxxxxrrrxxxxxxxxxrrrjjjjrjjfjjffffjrxxuM$$$$$$$$$$$Bcnxxrrjffffjjffffffffffffjrxuv&$$$$$$$$$$$%W%BB@@$$$$$$&vunxrjjfjfjftfffffffjjjjrxxnuc%$$$$$$$$$$$Wuunxrrrrrjfjjjjffjjjjjjjjrjjjjjjjjjrrrrrrrjj    //
//    xxxxxxxxxrxrxxxxxxxxxxrrjrjjjjfftfffttffjfjrnc%$$$$$$$$$$$WunxrjjjfffffffjjfftfftfffrxnuzB$$$$$$$$$$$B8%BB@$$$@*unxrrjfffjfjjfffffffjfjjrxnnuW$$$$$$$$$$$Bzunnxrfffjjjjrrrrrrrrrrrrrrrrrrrrrrrrrrrjrrrrj    //
//    xxrxxxxxrrrrxrxrrrrrrxrrrrrjrrrjfffftfffftffxxn#$$$$$$$$$$$@*nnrrjjfffftfjjjfftftttfjrxnnuW$$$$$$$$$$$$%8%B@@Wunxxrjjffffffjjffjjjfjfjjrxnuz@$$$$$$$$$$$Munxrrrjfffffjjjjrrrrxrrrrrrrrrrrxrrrrrrrrrrxxrj    //
//    xxxxxrrrjrrjrjjjjrrjrrrxrrrrrrjjjjjftfffffffjjxnv%$$$$$$$$$$$&vuxrxrrfffffjffttfttttffjrxnuzB$$$$$$$$$$$B8%8zunxxrrjjjffffffjfffjfjjjjrxnu&$$$$$$$$$$$%vnxxrrrjrjftfjjjjjjrrrrrrrrrrrrrrrxrrxxxxrrrxxxrj    //
//    xxnnnxxrrrjfffjffjjjjrrrrxxrrrjjjjjjfffffffffjrxnuM$$$$$$$$$$$@zunxrrrjfjfffttffttttftfjrxnuc&$$$$$$$$$$$@WcvnnxrrjjfffffffffffjjjjjrxxuzB$$$$$$$$$$$Muxxrrrrrjjjttfjjfffjrrrrxrrrrrrrrrxxxrrxxxrrrrxrrr    //
//    xxxxxxxrjjrjjjrrrrrjrxrrxxxxxrrrjjjjjjffffffffjjrxucB$$$$$$$$$$$Wunxrrjffffffftttttttffjrxnv*8%$$$$$$$$$$$$MvnxrjjffffffffffffjjjjjrxnuM$$$$$$$$$$$Bcnxxrjjjjjrjffffffffffrrrrrrrrrrrrrrrrrrrrxrrrrrrrxr    //
//    xxxxxxxxrrrrrjrrjrrrrxxxrxxxxrrrrjjjjjjjjjffftffjrxnuW$$$$$$$$$$$8vnxrrjjftfffffttttfffjrxuMBB%8B$$$$$$$$$$$&uxxrjjffffffftfffjjjjrxnv8$$$$$$$$$$$Wunxrrjjjjjrrrrrjffffffjjjrrrrrrrrrrrrrrrrrrrrrrrrrrrx    //
//    xxxxxxxxrrrrrrrrrxxxxxrrrxxxrrrjjjfjjjfffjfffffffjjrxnc%$$$$$$$$$$Bcnxxrjffjjjjfffftffrrxu8$@@B%8%@$$$$$$$$$$%uxxrjjjffftfffffjjjrxnvB$$$$$$$$$$%cnxxrrjffjjjrrrrjfrjffffjjrrrjjjjjrrjrrrrrrrrrrrrrrrrrr    //
//    xxxxxxxrrrrrrrrxxxxxxxxrrrjjjjjfjfffffffffffftfffffjjxnuM$$$$$$$$$$@cnnxrjfjfjjjjfftfjrxu%$$$$@BB%8B$$$$$$$$$$Bunxrjjfftfftfffjjrxnv@$$$$$$$$$$Munxrjjjjftfjjjjjrfjjjjjjjfjjjjjjjjjrrrjjrrrrrrrrrrrrrrrr    //
//    xxxxrrrjrrjrrxxxxxxxxxrrjjjjjjfftftfffffffffffjffffffjrxnz@$$$$$$$$$@vnxrjjffjjjjfffjrxn%$$$$$$@BB%*#$$$$$$$$$$%uxxrjfftfftffjjrrnuB$$$$$$$$$@znxxrjjjfjffffjjfffffjjfjjjjjjrjrjjjjrrrjjrrrrrrrrrrrrrrrr    //
//    rrrrrxrrrrrxxxxxxxxxxxrrrrjrrjjffftfftttffffffffffffffjrxnc$$$$$$$$$$Wnxrjjffffjfjjjrrx*$$$$$$$$@B*vv*$$$$$$$$$$*nxrjffffftffjjrxnM$$$$$$$$$$cnxrrjjfffjjjjfjfjjjjfjffjjrrjjjjrjjjjrrjjjjrrrrrrrrrxxxxrr    //
//    rrxxxxxrrxxxxxxxxxxxxxxrrjjrrrjjjffffffffffffffffttttfjjrxu&$$$$$$$$$@unxrjfffftfjfjrxn%$$$$$$$$$8uuuu%$$$$$$$$$Bnxrjjfftfffffjrnu@$$$$$$$$$&unxrrjjfffffjjjjjjffffffjjjjjjjjrrjjjjjjjjjjrjrrrrrrrxxxrrr    //
//    rrrxxxxxxxxxxnxxnxxf:,,,,+frrrjjjfffffff/I,,,,,\ftttttffrxnz$$$$$$$$$$znxf[I"`'..''^;]r$$$$$$$$$$MunnuM$$$$$$$$$$vxrjf/];"`'..'`^lf%$$$$$$$$*uxxrjjjffffffffj_,,",;)fjjjjjjjrrr~,,,,,,{jrrrrrrrrrrrxxrxx    //
//    rrrrxxxxrrxxxxxxxxxx/}'   `frrrffjjjfjjt`   '_|fffttttffrrxv$$$$$$$$$$z{^. `I?{)1?l`   "t@$$$$$$$*uxnu*$$$$$$$$$$vnr[^. `I-1(1?l^.  "t@$$$$$znxxrjfjfffftfffj/)I    ^)jjjjjjrrrt(: ._|fjjrrrrrrrrxrrxxxr    //
//    jrrrxxxxrrxxxxxxxxxxxr,    "jrjftffjfjt^    :ffffffttfffjrnc$$$$$$$$$#`  ,\fftttffjrt;   `z$$$$$$#unnn#$$$$$$$$$$u\`  ,|tttffjrrxr_.  `z$$$$znxxjfftffffffffjff\. .   ,trrrjrrrrr| 'jjrjrrrrrrrrrxrrrxxr    //
//    rrrrxxxnxxxxxxxxxxxxxf' ;   ,jjffjjjff, "'  `tffjffffffjjrn#$$$$$$$$n.  >jjffftffffjrx).  .n$$$$$WunnuW$$$$$$$$$&{.  iffffffjjrxxn8c.  .n$$$Munxrjjfffffffffjjj/..(:   .ijjjrrrrr| 'jjjjrrrxrrrrrrrrrxxr    //
//    jrrrxrxxxxxxxxxxxxxxx( .fi   lrjjjjjjl `/,  .\fffffffffjrxn&$$$$$$$8'  `jjjffffffffjrxn]   `B$$$$%uunu%$$$$$$$$$x.  `fjffffffjjrxnz$f   `B$$8unxrjjfffjffffffff\../j(^   '?rrrrjr| 'jrrrjrrrrrrrrrrrrrrr    //
//    rrrrrxrrxxxxxxxxxnxxxl "xr:   <jrjrj+ '\f]   _tffffffjjrxnu@$$$$$$$\   :rjffftftffffjrxr'   W$$$$@cuuc$$$$$$$$$%-   :jfjffffjjjrxxuBB'   W$$@vnxrjjjfffjfffffff\..\jjf]'   `)rrrr| 'frrrjjrrrrrrxrrrrxxr    //
//    jrrxxxxrxxxxxxxxxxxxr` -xrj"   -jjr[ .(ff\.  ,ttfttffjjrxnM$$$$$$$$1   "jjjffffffttfjjrr'  .8$$$@@Wvv&$$$$$$$$$*<   "fffffffffjrrxuM@`  .8$$$Munxrjjfjjjfffffff\..\fffft<.   ,/jj( 'frrrrrrrxxrrxrrxxxrr    //
//    rrxxxxxxxxxxxxxxxxxx/ ./rrjf`  .}r)..{jjjf`  '/ffffffjrxnc$$$$$$$$$#   .1jfffftffftffff(   ;$$$$@B%*#$$$$$$$$$@n|   .1ffjfftfffjrxnvz   ;$$$$$cuxxrjjjfjfjjjjjf\../jffjjjt:   .lf| 'frrrrrrrxxrxrrxxxxrr    //
//    rrrrrrrxrxxxxxxxxxrx~ `jrjjj\'  .[' -jfjffl   )ffffjjrxnvB$$$$$$$$$&~   '1ftffftfttttf\`  "%$$$@BB%&@$$$$$$$$$Mxri   '{fffffffjjrxnr`  "%$$$$$Bvnxrrjjjjjjjjjjf\../jfjjjjjj|^   'i 'frrrrrrrxxrxxrxxxxrx    //
//    jjrxxrrrrrrxxxxxxxxr^ irrrjjf(.    >jjjjjj{   ifffjjrxnu%$$$$$$$$$$cn?.  .:|ffftf/t/\+. .I%$$$@BB%8$$$$$$$$$$@nrjf_.  .:\ffffffjjr]' .-@$$$$$$$Bvxxrrjjjffjfjjj\..\fjjjfjjfjf['    'jrrrrxrrxxxxxxrxxxxx    //
//    jrrrrrrrxxxxxrrrrj|~  :1/rjjrj1.  ;rrjjjt1,   '](jrrxnu%$$$$$$$$$$Wnxrfi'   `;~]}-i". ';/x*$$@BB%8$$$$$$$$$$$#nrjft\!'   `;+]}]>,. '!z$$$$$$$$$$%unxrrjjfffjjt)l  l1/jjjjjjjjjj~.  'jxrrrrxxxxxxxxxxxrrr    //
//    jrrrxrxrrxrrrrjfj1,,,,,,!jrrrrj}"~jrrjjj+,,,,,,,,txxnv%$$$$$$$$$$$vnxrjff|<,`''.'`^,<(tfjrn%@BB%8$$$$$$$$$$$Bnxrjftttt(~,`''.'`^:+/xnv@$$$$$$$$$$Bvnxrrjjffff-,,,,,,_jrjjrjrjrrrf;`:rrrrrrxxxxxxxxxxrxrr    //
//    jrrrrrrrrrrrrrrrrrrrxxrrrrrrrrrrrrrrrjfjjrrrrrrjrxnnv%$$$$$$$$$$$#nxrjffftfftttftttt/ttfjrxcBB%8$$$$$$$$$$$$znrrjftffffffffftffffjjrxu#$$$$$$$$$$$Bvnxrrfjjfjjjfjfjjjjjrjrrrjjrrrjrrrrrrrrrxxxrxxxxrrrrr    //
//    jrrrrrrrrrrrrrxxxxrxrrrrrrrrrrjjjjjrrrjjjjjjjjjrrxnvB$$$$$$$$$$$&uxrjfffftfttttfftftttffjrxu#%8$$$$$$$$$$$$Wnnxrrjfffffjfffffffffjjrxnu&$$$$$$$$$$$Bcnnxrrjjjjfffffjjjjjjrrrrjxrrrrrrrrrrxxxxrxxxxrxxrrj    //
//    jrrrrrrrrrrrrrxxrrrxrrrxrrrrrjjjjjjjjjjjjjjjrrrxnnvB$$$$$$$$$$$BuxxrjftffffffffffffttftfjrxuvW$$$$$$$$$$$$%vuxxxrjffjjfjjjftfffffjjrxnnvB$$$$$$$$$$$@cunxrrjjjjjfffffjjjjjjrjjjrrrrxxxxxxxnnxxxxxxxrrrrr    //
//    fjjjrjrrrrrrrrrrxrxxrrrrrrrrrrrjjjjjrrrrrrrrxxxnuvB$$$$$$$$$$$Bvnxrjjffffffffffffjfftffjrxnuz@$$$$$$$$$$$@&zunxxrjffrjjjjffffjjffjjjxxnnvB$$$$$$$$$$$Bcunrxrjjjjjffjjjjjjrjjjrrrrxrxxxxxxnnxxxnxnnxrrxxx    //
//    jjjrjjrjjjjjrrrrrxxxxrxxxxxrrrrrjjrrrrrrxxrxxnnuvB$$$$$$$$$$$Bvnxrrjjffffffffffffjjffjjrrnuz@$$$$$$$$$$$@8%%zunxrrffjjjjjfffjffffjjjrrxnuvB$$$$$$$$$$$Bcunxrjjjjjjjjjfjjjjrrjjjrrxxxnnxrrxxxxxxxnxxxxrrx    //
//    jjjjjjjjrrrrrrrrrrxxxxxxxrrrxrrrjjrrxxxrxxxxxnuv%$$$$$$$$$$$Bvnxrjjjffffffffffffffjffjxxxnc@$$$$$$$$$$$@8%BBBcuxxrjjjfjjjjffffffjjjjrrrxnuvB$$$$$$$$$$$Bvunxrrrrjjjjjjjjjjrjjjjjjrrrrrrrrrxxxnnxxxxxxxxx    //
//    jjjffjrjrrxrrrxxxrrrrrrrrrrrrrrrrrrrxrrxrrxxnnu%$$$$$$$$$$$@cnxrjjjffftftfffffffffjjjrxnnvB$$$$$$$$$$$@8%BB@$BvunxxrjjjjjjffffjfjjjjjjrxxnucB$$$$$$$$$$$%vnxxxrrjjrjjjjjjjjjjrrrrrrrxxxxxxrxrxxnxxxxxxxx    //
//    jjjjjjjjjjrrrrxxxxrxxxxxxrrrrrrrrrrrrrrrrrrxnu8$$$$$$$$$$$Bvnxxjjjffttttttfffffffffjrrxnv%$$$$$$$$$$$@8%BB@$$$BvunxrjjjjjfffffjjjjjrrrrrxxnucB$$$$$$$$$$$%vnnxrrjjjjjjjrjrrrrxxxxxxxxxxxnnnxxxxnnxxxxxxx    //
//    jjjfjjjjjrrjjrrrrrrxxrrrrjjjjjjjjrrrrrrrrrxxnW$$$$$$$$$$$@vnxrrffftttttffttfffffjjjrrxnu8$$$$$$$$$$$@8%BB@$$$$$%vunxrrjjjjjjfjjjjjjrrrrrxrxnucB$$$$$$$$$$$8vnnxxrrrjjjjrjrrxxxxxxxxxnnnnunnnnxnnxxnnxxxx    //
//    rrjjjjjrjjjjjjjjjjrrrjjjjfjfffjffjjjrrrxxxnnM$$$$$$$$$$$@cnxrrjffftttttffffffffjjjrrxnu&$$$$$$$$$$$B&%BB@$$$$$$$8unxxrrrjjjjjjjrrjrxrrxxxxnnnnc@$$$$$$$$$$$&vunxxrjrrrrrjrrxxnxxxxxnnnnnnnnnnnxnnxxxxxnx    //
//    rrjjjjrrrjjrjrrrrjrrrrjjjjjjjjjfjffjjjrrrxn#$$$$$$$$$$$@cnxrjjjfffffffffffffjjjjrrxxnn&$$$$$$$$$$$Bzc8B@$$$$$$$$$8unxxrrrrjjrrrjrrxxxxxxxnnnnnuc@$$$$$$$$$$$Wvunxrrrrrjjrrrrxxxnnnnnnnnnnnnnnnnnnnxxxxnx    //
//    rrjrrrrrrrrrrrrrrrrrrrjrrjrrrrjjjjjfjjrrxu*$$$$$$$$$$$$cuxrrjjjfffffffffffjjjjjrrxxnnM$$$$$$$$$$$@cvvc%$$$$$$$$$$$&uuxxrrrjjrrjrrrxxxxnnxnnnnnnuz@$$$$$$$$$$$Muunxrrrrjjrjrrxxxnnnnnnnnnnunnnnnnnnnxxxxx    //
//    rrrrrrrrrrrrrrjrrxrrrrrrrrrrjjjjjjjjrxxnuz$$$$$$$$$$$$znxxrjjfffffffftftffjjjjjrrxxu#$$$$$$$$$$$@cuuuuc@$$$$$$$$$$$Munxrrjjjrrjrxrxnxxxxxxnnnnnuvz$$$$$$$$$$$$#unnxrrrrjrrrrxxnxnnnnunxnuuunnnnnnxxxrxxx    //
//    rrrrrrrrrrrrrrrrrrrrrrrrrjjjjjrjjjjrrxnuc@$$$$$$$$$$$#nxrrjjfffffffftttfffjjjrrrrxnz$$$$$$$$$$$$*unnnnuz$$$$$$$$$$$$#unxrjjfjjfjjjxxxxxrrxxnnnnnuv#$$$$$$$$$$$$zunxxrrjjrrrxxxxxxnnnunnnuuunnnnnnnxrxxxx    //
//    rrrxrrrrrrrrrrrrrrrrrrrjjjjrrrrrjjrxxnuvB$$$$$$$$$$$Wunxrjfffffjfftttttttffffjrrxnc@$$$$$$$$$$$#unnxxxnu#$$$$$$$$$$$$zunxxrffjjjjjrxxxxxxxxxnnxxnuvM$$$$$$$$$$$@cunxrrjjjrrrxxxxnxnnnnununnnnnnnnxxxxxrr    //
//    rrxxxrrrrrrrrrrrrrrrrrrjjjrrrrrjrrxxnnv%$$$$$$$$$$$8unxrjffffjjffttttt///tfjjrrxnvB$$$$$$$$$$$WunxxrxxxnuW$$$$$$$$$$$@cunxxrjrjjjjrxxxxxxxxxxxxxxnuv8$$$$$$$$$$$Bvnnxrrrrrrrxxxxxnnnnuuuuunxxxnnxrrxxxxr    //
//    rxxxrrrrxrrrrrrrxrrrrrjjftrrrrrrrrxnuu8$$$$$$$$$$$@vnxrrjfffjfffftfffftttfjjjrnnu%$$$$$$$$$$$%unxxrrrrxnuu%$$$$$$$$$$$BvunnxrrrjjrjxxxxxxxxxxxxxxnnuvB$$$$$$$$$$$%uuxxxxrrxxxxxrxxxnnnnnnnnnxxnnxxxxxxxr    //
//    rrxxxxrrrrrjjrxrrrrrrrjjjjrrrrrrrxnuvM$$$$$$$$$$$$*unxrrjffjjjjjfftfffttfjjjrxnu&$$$$$$$$$$$$cnxxrrrjrxnnuc@$$$$$$$$$$$8vunnxxrrrrrrrxxxxxxrxrrrxxnnuz$$$$$$$$$$$$Wunnnrrrxxxxxxxxxxxnnnnnnnxxnnxxxxrxxx    //
//    xxxxrrrxrrrrrrrxrrrrjjjjrrrrrrrrxnuv*$$$$$$$$$$$$WunxrrrjjjjjjjfftffffftfjrrxnuM$$$$$$$$$$$$#uxrrjjjjjrxxuu*$$$$$$$$$$$$Wunnxx                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MOON is ERC721Creator {
    constructor() ERC721Creator("M O O N", "MOON") {}
}
