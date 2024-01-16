
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Music, Melancholy and Mirage
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//    OUYYUYYYXXXXzzzXXzzXzzzzcvuuumOYXXUOwmLokk0YzzXZbCLQJqQJUCwoowUudOJYUYYUUUUYYYYYYYUUYYYYYYUUUUJJJLLLLLLLLL    //
//    OYUUUUUOLpZdCCJhpppwXXcc0bpqpqqqqqpqqqqqqqqqqqqwwwwwmwwwwqqppqmmnnbqCUYYYYYUYYYYYUUUJCLQQQQQLLLLLCJJUUYYXz    //
//    OUYUUJJCCCCJUUodpppppppppqqqqqqwwwwwmmmmmmmZmmmwmwwwwqqpppqqqqqmZvjCOQJZwmZmOQQQQQLLLLLLLJUUYYYXzzzzcccccv    //
//    ZUuJJCLLLLLCCC0*b*ddpdppppppqqqqqqqqqqwwwmwwwwwwwqqqqwwwqwwwwwwwqqCxjruucvnMM*apppd0JUUUUYXzzzzzcvvvvccvuv    //
//    ZJvCCLjUnJJnJCmQahdddddddddppppqqqqqqwwwwwQwwwwY}wwwwwwwwwqqqqqqpqqqqOLC0ZZ0QLYCv[]t0mUUYUYXczcvvvvvvcvvvv    //
//    ZJC~CCCLLLLCCCm0kbbddddppppqqqqqqwwwwwwwmm::ZZ("wwwwwqqqqqqqqpppppppppppqqqqpqqqq1?uCbUUXzzccccvccccvvuuuv    //
//    wZLCCLLCJJxUUUUYbdpppppppppppppppqqqqqqqqqqqrrJqqqqqqqqwqppppppppqqppppwXrfrf((}|XqZJYXXzcccczcccccvvvvvvv    //
//    nUmCCLYYYXXjXXXUdqqqqqqqqppppppppppppppppppppppppqqwwwwwwqqppwqqqppppm1XQLCLJJYUYXzzzzcczcccccccvvvczcczzz    //
//    o/LwCLCJUuvXj|XUdpqqqqqqqqqqqqpppppppqpppqqwwwmwqqwwwqwqqpqqqqqqqppppzOXXXXzzzzzcccccccccccccccvvcvzzzXzcc    //
//    8U[YCJYJJUUY/XXUpqwwwwmwwwwwwqqqqpppppqqqwwwwqqqqqqqqqqqqqqqqqqqppppvJXcvuuuvczzzzcccccvcccccccvvzzzzzzzcv    //
//    88}]LLfXXYUUXXXaqpqqqqqqqpppppppqqqqqqqqqqqqqqqwwwwwwqqqqqqqqppppqpp0nccxxxnuuuvvvvuuuvvvcccccccczzzzzzzcu    //
//    8dr+[cQ()jvJUvXpmddpqppppppppppppppqqqqqwwwwwwwwwwOn>QwqqqqpqpppppppqZuuXY|rJUzcvuuvvvvvccccccczzzzzzzzzcu    //
//    8Uu-_-1|f{{tUXzYzzzzUhbdddpppppppppppqqk00-*wwqzI?mkdpqwwqqqqpppppppqqOnxLpO(v(zQ0YYXzzcczzccczzczXXzzzzcu    //
//    *j}~+?[[0_[])Xn|zzzzYUUU0wddpppppppppqqxmw|)qa0|hdppqqqwqqqpppqqqpqwqwwmOOZpdao*W88kqUXXzzccczzzczzzzzzzcn    //
//    8p?~~-(11p_-/YzzuzXCppQUUUU)akbdddddddpp#}odqJ]zxkdqqqqqqqqqqqqqqwqqqmmwqqmYqo*#W888hUXYYXzzzzzzzczzzzzzcx    //
//    ro*{~<{111f!)YzzzYnUYXYYYYYYYYYYcfc~nv(ObddYUu|//]UbqqqqqqqqqqqqqqqqqppdpwOwmQka#WWwCYYYYzzzzzzzzzzzzzzzcx    //
//    Jxk*[+~)[}]<:]zzXUJXi,/XYYYXYYY0YYY(X}<XYYYXfrctX|cfbqqqqqqqqqqqqqpddddpwwumQLCJUYYJYXXXzzzzzzzzzzXzzcvzcu    //
//    wZzq&Y?+]?{]<:UzYJYYUUYu|v~nUXr_YUUYJUJ}cxnv1rrXnXz?dpqqqqqqqqqqpdddpqqOJQJJJUUUUYYYYYYYzXzXzzXXXzvvvvvvcn    //
//    YmZUm8WU{?~1}<_XUUJJUJJJCLLJJ~!fYUUUYYYU<uvnuX1Xt|1bppqqqqqqqpddbbpqwmOLJUUYYYUUUYUUYYYYYYXXzXzzzvvvvvvvcr    //
//    JJLOLQb#&zt8X},twmqwZOO0ZOLJJJr_,<<|UUUUuxX(jzrX0kpqqqqppqqpdbbddppm1QJUYYUUUUUUYUUUUYYYYYYXXzXXccccvccvvj    //
//    pdOQL0ZmdWJ88Y_!;1/"`LpwZOLCCJJUI,_~1YYYXYrX/fvckbpphppqqpdbbdddpppCYJUUUUUUUUUUUUUUYYYYYYXXzXXczcccvcvvvx    //
//    pdhkkdbbbdW&8&M&*w+~IIqbwOLLLJJJJ:l]1JUU~+/X1XYYQpdppqqdbbddpddppppjLJUUUUUUUUUUUYYUYYYYYYYXzzczzzccccvvvu    //
//    pdaahaoo*#&&aWrb8b~<l_WkwOO0QLCCCx^^)UUUXY|U1nvz+dpppdddppdqdppppqp|0JJUUJJJJUUUUUUUYYUYYYXXXzczzzzcccvvvu    //
//    &8888888&&8&oo1dM__<:,~r8pOO0QLCCJ;`<UJCUvfrY}(YY-Opdpqqpppddpppww0|ZCJJJJJJJJUUUUUYYYYYYYXXXcczzzzzccvvvu    //
//    nCJU888ab8hWWLr&n+_<<!`';camZO0LCU;`UJJJ|/(vxUJUYuupppppkkbdpppqwwZt[)f)vUJUUUUUUUUYYYYYYYXXYczzzzzzccuvvu    //
//    vjtZbk8888C8&qWm?_+~~<<i``ICwX|LCn,+CJJUmUUJjUUt(YUlJJoU0hk#hdpbqwwmj?<{1|frLUCJJUUUUUYYYYYXzzzzzzzccvvvvv    //
//    wJUU#8vO88&888a[-~>>~~<>,`'_t][tCt^{JJJm|CJJcJnjUrXjYXbzvY(|:/hdpqqqO{[]]]})/jr(/YUCJUUUUYYXzzzzzXvccvvvvv    //
//    nMpoCpW8wq88M8p[+~<~+~~<i^'"Zm0LL<]LLLL-C(Ccx}??}uYYrjUU]XfXv~+dkdpqdmX?~~__]}1fx/CLUUJUYYYXzzzzzXXXcvvcvv    //
//    vwdqYwp*8J8&*8p?+-_+~~>!,"',h0LL_"|LLYCJ[Cvz1+Il_1vtJ:f{x|Y)vvxx[bbppddpmJ(--??|r)CJUJJUYYYXXXXzzzXXccvvcv    //
//    zdabwzpd8&w8Z88u-_++1/I:^^':iQQz'?LQ0uv?Y}tvj(1{1(?u~YYcnY(jJvcz}:bkppbddqL|-?-)|10CUJUJUUUYYXYzzXXXcvcvcv    //
//    OqddwUmoW8v&ZU8&]]Uv<:,,"^^,cm+?0ZOOcLvYXJJ(U-xUUu;i!-1I``'`>n_Yj]xikkkbddOr}_-}{c0CJJJJUUUYYYYXXXXXXccvcv    //
//    ZqwbpZpbM8OX&r88u(L_!,,:,^"OL:0LJUUjzv}X?|c)zJQ~!l"'```````````^lX]-l^{0akdY1?~1}zLJJJCJJUUYYYYYYXXXXczvzc    //
//    Qqdbphwb8&8p&oo8W[pU+:,I"""1u/XXXzcXn|uzzX-YX>:;;::,,,:""``:^""```^x,I{r?:dJ[~<+)0LCCCCJJUUUYXYYYXXXXccczz    //
//    mwObdphkM88po&v88[Ldq~:I;"""YXzzzzjuuX|cYYUu;;,,,,^^^,"":"^^`^"`````I{/}~:kz]_-+|mCCCCCJJJUUYYYYYXXXXcccXX    //
//    Zwwbpb#*#88LJbb&8mwakw+II",,xXcczzzzXX;XcYvi;;,,,:,,,:,,"""::"""`````````/hp|]-1UZCCCCCCJCUYYYYYUXXYYzcXYU    //
//    qZbkdo#M888O88&Y88)qoh0</:,,^)JvczccXXjvYX_<;;,",,::;,,::,"","""^````````_0bk{[-(OCCCCCCJCUUUYUUYXXUUXzcXY    //
//    boh*o#W88M#O888#&8#r&hbCrI,!:'^QXzzctXXzIvC>;:,""",:;,:::::"""``````````!aqbob}(zCCCCCCLLJJUUUUUUXYYYYzczX    //
//    baa*MW888a&&888v&#&b&#kk1I,I;;`^xjzuvv(nnx<il:,,,::<:;;,"^``""``^``````+dqbho**pjLCCCLCCLJJUUUUUUUYYYYXzcz    //
//    k*#M#M88#888888&LM8CpMab[:I;i!;``Qczunzur>iI::_,:::~::;;,^","","^"````^Zmphha*oaMZCCCCLLLLCJJUUUUUUUUYXXvc    //
//    o*M&888n&8888888fM&&fkobz;;i><II`!Czcuvc<I,::::l:::::,,;;I;,,""^^`"```tLZmha**#*aa#0CLLLLLLCJJJJJJJUUUXXzz    //
//    #M&888k*88888888MCp8X{khq(l">ilI;'u0cuYX-~",;I<:::;;::;I::::,"^^",,``Iu0qqao###**oooMbv0LLLLLCCCCCJUYYYXXz    //
//    MW&88&#88888888888M#&~woap]!:<>ll^_Cnv(n0i``^",::::ll;:::I::,"""",^``_v0qha#M*oahaaoo*#b/YLCJCLLLJUUUUYXXX    //
//    M&88#/8888&&&&&&888j8cQo*#O>I>ii!^~acXUcjc:;;;I::_:;:::;::,,,""""^```_OOqa*#*okp0wmpJho*#**L0cUvc0QCJJYYXX    //
//    W&8Mj8888&&&WW&&W888p8z**oWp<iI!>:>{JoknzziI;!^,:,::I:::}:,"^"""^,"<^_XZko#MabXfZv0Cbdw*MWWWWWMM#*hdnYXYXX    //
//    &&&j8888&&WW&WWWW&88hhOpooa&0I!!~i:>uL8*)JL-;d<^"",:;;;:,,,^^,">"``l{Ucwa*MabxxOfffLdqZnkMMMMMMMo*#0UYYXXu    //
//    W8p8888&&WWWWWWWWWW88Y&Ma*b&W!!:!i,^"mMo8&8aZwrLc;:::[;;ll;"::^:``:QQJZao#odnjxfjUYvx/LaM#o***#a*#dUYXzzzx    //
//    W8j888&&WWWWWMMWWWW888bW&Mw*&flI`;;,';La)+fXLkJJdMcx:IIIIIlI:"^^I``O0phaook/|jjYJZpqdba#*hohkoa*#hQYXzzczn    //
//    &wd88&&WWWWMMMMMW&&&888b&&oo&_!;^I:``dZ|,,:;^`^:vWkhM__);,"^^"",^``:CpbooMr||vJJk#aaoahhhooakoM#*uUXXzzczv    //
//    Ww88&&&WWWM##MMWWWMW&888#&M**rl":""`kZ!,IIlI:;II"`;/QM~""(OppJ|/|1:`,YWo#q/|rXpM&M**#o#W&akh#MM*xjYYXzzczt    //
//    &w8&&&WWWW*#*MMWWMW&8888&&MMoul,;":M(,:IIl;:::::"``''^..'".''''....r/UWa&wj|tXW888MMWqZ88W#MMhutr|zYXzzzcr    //
//    km&&&WMWM#o*#MMWMMWW&888&&WMWOi,,ru>,:I;ll:!l;;;;:,```^""""^^^'''....,kMWMv//z&888&&Q||n|/njrX|t|j|jYXczcu    //
//    qmW&&WMM#W#*###MMMWW&&8&&&&WWd|,v],::;Ill!;!lllllI;;:,,"^`^'`'''...'.'c&&8&UX088888Cu|p|||u|U||ruj|mzJccux    //
//    pwMWWWM**M#**##MMMM&&&MM&&&&MUt,},,;;lil!l!l!!llI:::"^'````.`'''...''imW#W8888q&888L|t|j||wq||||/|k|jmYunr    //
//    wwMWWMM**M##a**MMMM&&&*#&#W&M8tJ,:lIIii!i!i!!I;I;:,"````"`.''...':~|LhhMoY<1{;^;/Qp&mQ||||||v||jz|/||,'f-j    //
//    bw*WWM#*oo##***###W&&bWW&#MWW8m',I;!>ii!!ii;III::,""`^,"^``''..[(.'`Qqhh(.'''^`'`||&8ck||||c/|||||/MW;'j;j    //
//    &wkWWM#*oo****##*M&&#o&Moh*WW8&",:I!il>Illlll;;;,;",,"^^^`.'.'+;`'`".}uz.''^`^^^:Y|nnw|jJ|UQ(1||vJU}Y'.(^)    //
//    WwhM##*#oo*oa*#*#M&Wd&&##ah#WW&^"";;;;;Ii;I!!!!l;:,"^,"^.....;}''I`:`...''^^^",^]|||z;/(`.,^^",:':'.''^]^[    //
//    &waM**o*oo*oo**o#WWhd8*aMabhMMkw;^,;;;:ll!i!iiil;;;,^``'..."[>`^Il`;".''^`^":"'Y||+....',::,:,,^``':;'c],"    //
//    8C***#o*oo*a****#W*x#*kk#akk#oWdZ"":,::li!i>i!lII,"^``''[_''`''^I,"",.'^`^,:^,;O!....',,,,,,^^`^,:;l!)->`[    //
//    ob****oooo*koo*o#MhCWaqZbbhbha#bd{^,"^,ii>ii!l;,,"^```'')`'`'^::,lIl^''^":;";I;::,:^,,,""^.``^":;ll<qil,`1    //
//    Oh*o#*oooaoaoo**MMtoWhqLZdbbbhMqdd1:"^;ii!ii!l,""^^`^^''|..^,::!!!l::"^,:;,;l!lI;:::;:"`..'",:;ll:l~-J<"^[    //
//    Ok****oooaooooo*##toobuZCLbbbhWMbdp~"^:l<>!l",","``,"`''?'.";I,li>i!I!::I;I!iI;;;:,"`....^,:::::,^!>[J{?+_    //
//    Oa****oooaooooo***aOaQZOOUbkkaW&#bdz`^:;<ii,",""^`,"^.''?!":Ill<<!><i!!lil!!iiI;;,'....'"",,,,,`'"!~[:{b[;    //
//    ha****oooaoohooo***aohbUOdbkka#WobbC}'`",!Il:"^^";^!^"''i|>I>:<_?~<~<!l>!!;;III"......``::"^^```'',!II.[[l    //
//    ha****oooaaooooa***ahabdjLLbbhaoW#kkLu`'',ll:`^^;:;`":"`"~;I<>_-~>>>i;i!l:::I^......',:::I;+[l'''""l"l-X-;    //
//    haoo**oooaahoooho*o*kkbqunjjmbko*M#abbbw-:`;~;,^;:Il":;i_`>!i<__<Ii:^`I;:,"^......'`^^^:lYp|jC|.'..`I;`b~^    //
//    Oaoo*ooaaaaaooohaokhkdJJ/jxzJLXdkh#&&abbdLr+mC-II,"I;l:<.'`i_-_<>;l,:^^:^'.'''''''``^;!;-Xxrfvzi..:I,I('`i    //
//    Oooo*ooaaaaakaoaoopkhwfLJrcXvcX0pkoo*&WW&MakkM&88c<':!,:.':I+_~>ll;!:^""``'.''.'`";l!!ill&|0Xu/?.',,t'.":~    //
//    dooo*ooohahaoaoaoadbk]OJc|nUncczQZho*MW&8&888&#M&&b^:>1:."I<_-i!i!I;""`'``""^":;;I!!~~lIIi|XuY|_''f!'!i""_    //
//    moooooooaahaoooohadwbUJUfuxUnrXXX0dahhhha*aaahkhM&du<`1.`,;+~ii>i!!^""^`^",:;;I;:;I!+<i><;l<fz|/}`w,"^`",_    //
//    doooooooaahaaaaohkpObZzxjn1])nuvvvvO0wpqppOkkbbb*&#8W`(.``,!>><>!i;"",::,,;I!lll!i<_i~~~+<>_}|JU;')"^^:,I?    //
//    daoooooaaahaaaaahwp00cnnjx1{)ttvjf(nzzXYc|/nL0dbo&*W8WCvxj!,~>il>,,:Ii<i!!!!><+___-?!>lI~<i++YcuI(:^^"^l;]    //
//    haoooooaaahhaaaabwLdwzvjj|||tffcxjj/XrXc/)t0njQha&#88W8*88*L|]~~;;!~+++______-|xrwhQi;_,;"l+-uY0'`f`^:II~<    //
//    hhoooooaaahaaakhmdJznznrcc)xzncunnc))Uuft)rxzzk*aWW8M88&8M8Wp)?_i~-?[}}}1fzOCLLYa*qJ]&8Q++>~+[Jt(1[}^:!!i_    //
//    hhaaaaoahakhahhhZppjzxrfjUr1cYuxuuzr-cnnUYruQUw*MW&Wbw8WM0qpo*(?1|ZqZ0k&W&*MM*Cd#888a888&WoqbJzUftxMUjj/||    //
//    kaaoaaoahadhaaadmqwOc{nxz/zrtnzxxuL|1|vuj[|vfcvo*W88odqaaZZOmqdwW&8&WWM#####MW#MMMM#****##MMWWWW#akZJJzn|v    //
//    phaahooahbdkaaakwqLLmYjxLjmnfjujnuZntjCn||Xr/vnma#88MMrhbOqJLahkkko*a#M#kdqwwwpdbbbbbdddpqmZOQLJXnnuuxj(|(    //
//    ChaahoaahdpkahhbZQXuuxuxcjYrnjjrftC1f//|(/t(jvjbaMM&M*ap0CCCCCCLZJLQOqwmmZO000wqwwwwmOQLLCQO0QLCCUUUUYYuxf    //
//    Xhamjzh|-rqkhkhbw0OXvunnxzxxnxxjt|u|Ynj/1|/xXzzdh&&M*ad0UUXccvzYYccczcunnnuvunYt1vvx|/(}}[[}}}}}}{{}}[[{|r    //
//    CkhakkkkdbkhkbdwmLLUXxvvccurrxuuvc|tuvvxjxxxcJwdkh#MowQcYX<>i>[Xi:;;IIl!!!llII!llIIl!!!llIIIllllll!!II:I;:    //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MMM is ERC721Creator {
    constructor() ERC721Creator("Music, Melancholy and Mirage", "MMM") {}
}
