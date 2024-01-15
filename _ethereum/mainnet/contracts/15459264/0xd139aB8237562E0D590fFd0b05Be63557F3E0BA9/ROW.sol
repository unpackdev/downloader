
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rider On The Wheel
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//    kkkkkkkkkkkkkkhkhkhkhhhkkkkkkhhhkhob8@@@@@@@@@Wkkhkkkkkk&d%kkkkkkko%kbkk%kMkkkkb&kkkaMkkkkaopB8%M@@ahkkkkkkkkkkkkkhkkhkkkkkkkkkkkB@@@hkkkkkhkkkkkhkhh    //
//    dddddddddddddddddddddddddddB@@@@B8@@@@@@@@@@@@ppdddddddddpW8ddbbdbdb8dddkkkadbbWpq*bb#dbbb%ddbbdMpp%BdbB@@@@*dddddddddddddddddddd%@dbdbdddddddddddddd    //
//    qqqqqqqqqqqqqqqqqpqqqqq&@@@@@@@@@@@@@@@@@@@@@@WqqqqpqpqqqqqWQ8qqqqqWq&qqq8odWpq%qWp#bbqqq#bqqqqqdww8#dhB%%W%@@Mqqqqqqqqqwqqwqqqqqq8qqqqqqqqqqqqqqqqqw    //
//    mmmmmZmZmmmmmmmmmmmmZm@@@@@@@@@@@@@@bq@@@@@@Bh&WmmZZZmZmmmZmq*%ZmmZmhmpmw%0W0wm&p%mw#ZmmwMmmmmm%ZZZZMBBmZ&aZOB@mmmZmZmZmmmZmmZmZZmmmmmmmZZZZmmmmmZZmZ    //
//    00000O00000000OO00000qB@ZOZoB%Bq#ZB@@000000000OOm*aO0OO0OO0000B080OOoMoW0OO0#8Zmw@kmZahZO*OOO0qQOOO0BQ*MoO00*Bd000000Q000000000000O000000000O0O0O0000    //
//    CLLLLLLCLCLLLLLLLCLLL8B@@@WpLwqLkw@@@%QLLLLLLLLLLLL0&QLLLLLLLLL%LawQQQL@0Q&L0MBk0BLWOQo&0aLLQLqLLLLL%ZJqLao8LLhLLLLLCLLCLCCLLLLLLLCLCCLLCLLLLLLLLLLCL    //
//    JJJJUUJUJJJJJUJJUJJJJo#@@JUJ0UU0pmO@@8UMhJJJJJJJJJJCJJhaJJJJJJCJbJJ%cWJUOLBaUJp&pb8QQdBLpZJJCWJJJJJ@J&B@@@@@@%UhJJJJJJJUUJJJJJUJJJJJUUUJUJUUJUJJJJJJJ    //
//    XXYYYYYXXYXXYYYYYYYYYkC%@#WaUUUUYwJMBJczzzb*dYYXYYYYYYYYU%OUUUYYUbUYUBUUbM8BU&U&BhCUCQQCwdJY&YYUYU%XYYw@@@@@@WYZYXYXYYYXYYYYYYYYYYXXYYYYYXYXYYYXYYYYY    //
//    zczzzczzzzzczzczzzzzzzObXX@ZqB@@QzcX%cv&8muvnup8zzzzzzzzzzzoWXzzzzdCzz%h*X%#zY&UXY8kLUCQWUdqzXzzUOzccza@@@@@@%czOzzzzzzzzzzzzccczzzcczccczzccczzzzczz    //
//    uuuuuuuvuuuuuuvuuvuuvuJ0#B@@@@@@@vvvbuuuuuuv%anrxr@XnuuuvuvvvcBvkvvv&zzZzBYdZnvMUXuvMCzWvvzMuuvBuvuuvvuuucazuUuuc0vvvuvvvuuvuuuvuuuuuvuuuuuuuuuvuuuuu    //
//    xxxxxxxxxxxxxxxxxxxxx@@@@@@@@@@@@@unWxxnnnnxnxxnOu8rr0@xxxxnnxnx%vJnu@vQcLnW8@&vzq*zuo%hcnWnun%xxxnnxxnnxxx#%#*X@@@@@@axxxxnxxxxxxnxxxxxxxxxxxxxxxxxx    //
//    jrjjjjjjjjjjjjjjjjjjjX@@@@@@@@@@@@YzLjjjjjjjjrrrjrrjxnmWz@WrjjjjrrMokxoU&CLZrbvmjJrwY%MkzpvuubrrrrrrrrjrrbBrnoB@@@@@B%B@rrjjjrjjjjjjjrjjjrrjjjjjjjjjr    //
//    tttttttttttttttttttttt@@@@@@@@@@@@@@fftffftfttfttttttttttttp08zttftfW/Cw/&xoj%8uftWxrWhWYWxCjrjfffffff8hQkttfjZBO%Cc*raXfftfftttttfttttttfttttttttttt    //
//    ||/|||||||///||/|//||/|b@@@@@@@@@@Ba&B0t//|/||||///|||/|/||||||qO*t//%8r@dZ8C%%Yb&ww/obb%**zj/ft/f%&p/t/ttmB&tjafjfrQdt/|//|///||//||||/|||/||||||/||    //
//    ((((((((()((((((((((((())vZc|(((M(B()()())(0%#Bor((((()((((((((())fMb%/rc&C%&))*/)(t%ZCd*W%|J@%%%|/YMMn)))))))(&//t%WB|))((((((((()(((((()(((((((((((    //
//    111)11111)11111111111)111111111)%)8r)11111111111111{)xMBB%Y1)))111111)&U1%BoBq1{qt0{uYd@X@Bap#&rbX{11111111111#B@@@@@B8)11111111111111111111111111111    //
//    {}}}{{{{}{{{{{{{{{{{{{{{{{{}{{}{{t)&{{{}{{{{{{}{}}}}{}{{{{}{{}1wBBq|{)1n{8%BBqBB@BMB@B@B%@k[8/dco1{{{{{{{{{{{}@@@@@@@@@o{{{{}{{{{{{{{{}{{}{}}{{{{{{{{    //
//    [[[[[}[[[[[[[[[[[}}}}}}}}[[[[}}}}B)B[[}}[[[}[}[[[}[[[[[[[[[[[[[[[}}}}}Lp@@@@B)f%8%8*&%MB8B@@f{qca(}}[[}}[[[}}}@@@@@@@@@&}}}[}[[[[[}[[[[[[[}[}}[}[[[[[    //
//    ]]]]]]]]]]]]]]]]]]]]]U@@@@@@@@@8f}O8]]][]]]]]]]]]]]]]]]]]]]]]]]]]}jqb@@@@@B@@%M8bfO@@@&zpBBBB&WaLU1[[[][]]]]]]][1Zp*}}Ba[[[]]]]]]]]]][]]]]]]]]]]]]]]]    //
//    ?????????-???-????-M@@@@@@@@@@@@B[B#0????????]????????????]]](o%B@@@@@@@@BJ@@%o/CQ<~]+Q_@+@@B*?W*)nJk8OkBopu[-??????[(8a??]???-??????????????????-???    //
//    _-___-_-_------___c@@@@@@@@@@@&BBB_BB---_------_---_YM8ox<>~YMW%hno~r@88@B@%*+&#++_~Wh]+BBjBB*BZ@8&______-_][--]qB8J[B-ZB@%X____--___-_--____---_____    //
//    ++++++_+++++++++++B@BW+BtjoY~q<%@@@>}x_+~_088Bk}+</#%%Wk/_+~+++++1o%B@@@@[{8BY}0hpk<|#8_n?hk##XBqok&%Z+++++++++++++%@@@@@@@@@B+++++++++++++++++++++++    //
//    ~<~<~~~~<<~~~~<~~~B#@U}>->ia<>Bx@@B##Bf!_J8%BBo(~<~~<<<~~~~<<<>+@J8BB%@&qMW%a%>hio>tL%+UCqk%M1a_QCd?<BrMB~<<<<<<<<~@@@@B@@@@@B~<<<<<~~~<~<<<<<<<~~~n+    //
//    >>>>>>>i>>>>>>>>>>?8>>Zl(ll&!!M%@BW@vwi>iiiiiiiii>i>>iii>iii>&a>>Um#L@&8iBWBM8h*a~Lo-)z+lfLL%c&]8zM*fiv!M!-%fi>>ii0@h~{I%ci>i>>i>ii>>>>>i>>>i>>>>>>>>    //
//    !!!!!!!!!!!!!!!!!!!BII#IItlM!IWI;;X&CIBlll!ll!!ll!l!!llll!po!Ilx8@$@%|*IBp<LoWU/%<?i&8IlOX%twaCb>XhbCq8>I;#Y;IBbiiirBll;Bh!l!!!!!!!!!!l!!!!!!!!!l!!!!    //
//    IIIIIIIIIIII;IIIIIIB;Iw;;%@B8k8:;:;?X>z{;;II;IIIIIIIII;%BlI;;IXB@@@@Bm~0[*%tbWaL[WxhI>lzaU_IhC@O(qBB&!*B|;:;lB:;;h%?B+voB#&bllIIIIII;II;IIIIIIIIIIIII    //
//    :::::::::::::::::::B!|@@@@@@@@B:::;v:&{8::::::::::::#@b]::,,:M/&X@@@qUBWI%ohYBlMdx#<+i}:LI,Ma#B%#>%>%hzh#*;,:;>JtY;;B;;MB@@@@h8(,,:::::::::::::::::::    //
//    """"""""""""""^"""q@@@@@@@@@@@@Bn",,M"n:%,"""""":&B""""""",ZjdtJBB8@Bk@@1]W8rou(Ow:z#_"naM%@@@@@wfkJ+&@x}8bd""""":&%@@@@@@@@@@Bi"""""""""""""""""""""    //
//    """"""^"^^"^"""^""}@@@@@@@@@@@@%?"""IB"W"Q"^^,#Wl""""""",kMbpv8@!:<lz&@@@Bq;q?b,&-0](IXaOb@@@@@@@B-Mu:n@|m#)8""^^")B@@@@@@@@@@q:""""""^""^""""^""""""    //
//    ^^^^"^"^^"^""^^^^",B@@@@$@@@@@@@I^""")+1,b"WM-""^^^"^":8kB)QM@:M"""c,h>@@@@@@;:J,omp8""*@@@@@@@@@@YM+WfUBZ/B8-*"^^^I@@@@@@@@@@,"^"^"""""^"""""""""^""    //
//    ^^""^^"^"^^^"^""^"""<@@@@@@@@@@@a"^"""B"k&p^^^""^^^"I@h]@(XB%IM,"",*xp,08h@@@@@Wt<(1Bpq%@@@@@@@@@@B)m"J8U&Y]j@,&f"""B"i;::,|<%""^^""^""""""""^"""^"""    //
//    ^^^^^^""""^"^^^^""""""B@@B@&(""""^^""""@8,/""^^"""l8L"0QwhtB:@:"""Q^~|,Wbd::B@@@@&[?]*@c@@@@@@@@BB*1*:^}B:MObLB,YB""In""""")-B^^^"""""^"""^^^""""^"""    //
//    """^""""^"^^"""^""^^"""^"""""^"^""+W@@B@@X"W,^""t*(,Xwmt#I&l]>"^^"8"%!"&Wr"W%,o@@@@w8*h@M@@@@@@@B;!0un"";MY%&raa&i8""8"""^":[8""^^^^^^^^^^"""^^""""^"    //
//    ^^^""""^^^"^^""^""^^""^^^^^""^I@@@@@@@@@@@@BW~"Bl""{B}BLlQJ:B"""""%"W:"8!8"MZ""oq@@@@@cB@@@@@@@@},IW/%""";M,8!k8Wk/h,z""^^^"w8"^^"^^""^^"^""^"^""""""    //
//    "^"^""^^^^^^^^^"^^""""^"^""""B@@@@@@@@@@@@@BtMJ""w@-Bl,"_x,&"""""hZxl""W,%,&^"*(fB@@@@@@@@@@@@@@;;l[rW"^^^,M"@,,wk}zY%L"]/--J0""""""^^^""""^"""""""""    //
//    ^^^^""^"^"""""^"""""^"^^"^"""@@@B@@@@BBW<"">^"/Bc{Lz""I;a,d~^"^^"f:@"""%d8~U""p0hd,@@@@@@8%B@@%@@@h#@/;""^^IW"%"""Wb8@ft@@@@@@:"^^"^"^^"""^"""^""""""    //
//    """""^"""""""^^^^""""^^""^"""i&Y";""u:,O""tWX8Q(c%"""",B";*^"^""@:Z{"""B,OwL^,LYhJ"a@@@@BpWk#mB%%@@@@@W""""";8"&""}vMUO@@@@B*:_"^""""^"""""""^^""""""    //
//    "^"^"""^"""""""^"^"""^^^""""^tn"q"""a""o,"^aMhL@p@!"""%,,%"""^^,B^B,^""_,wU""JrvvM"#@@@%/B8Ok#q8B@@@@@@;""""""*,@,l088%{Bd@+z,Y""^^"^^^^"^^^"""^^^"^^    //
//    """^""""""^""""""^"""^""^""""tnI["""%""/YBqI&/uB~Bl%:o),M,^""^"B"(t"""W*:%(""ntCt@&>@@@@B@8m&W@@@@@@@@@BI^^^""u|,@,/B*(tW0-zh",""^""^^^"""^^"""^""^^^    //
//    ^"^""^""^"""""^^^^^""""^^^"^^fW,i"""M""I@@m&/jh"^"(*<%i"&,"f@@@@8@^",%&",8/",d|px*"~B@@@@@@@@@@@@@@@@@@@x""""^"Qt:M;%%"oW?8MxBMd"^""""""^"""^"""""^""    //
//    ^""""^"""^"^^""""^""""^^"^"1r}@@@@@@@B""Bt&/J?"^""",k%W%M%@@@@@@@@@@BMB%:8|";rxOh"""@@@@@@@@@@@@@@%,B@@@B"""""""~ZXncBOjd@@@@@@@0""""""^""""^""^^""""    //
//    "^"""""^^"""""^^"""^"^"^""""B@@@@@@@@@@@@b|%,"""^""Y(*%@@@@@@@@@@@@@@@@@@ak,%jLfB"""B@@@@@@@@@@@@B""^@@@@_"^""^""w%@@@@@@@@@@@@@X"""^"^^"""^^"^^"""""    //
//    ^"^^^^^^""""""^""""^"^"^^"""B@@@@@@@@@@@@@#"""^""<LB@@@@@@@@@@@@@@@@@@@@@@WW%twfY""""@@@@@@@@@@@@%""""B@@B""^"""""B@@@@@@@@@@@@@1W,"""""^^^^^""^"""""    //
//    ^"^""^^""""""^"^"""""""^"^^"*@@@@@@@@@@@@@,""""^Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@Wkx|""^""@@@@@@@@@@@"""^""@@@B^"^"^""0@@@@@@@@@@@BWYn%Q"^"^"""""""^"""^"    //
//    ""^"^""^""""^"""""""^""^""""^,a@@@@@@@@BB&"""""%@M@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Bz""^""B@@@@@@@@@@""""^"&@@@B""""""8_@@@@@@@@@@,"~cvr%,^"""^""^^"""^^"    //
//    ^""^"^^^^"^""^"^^""""""^""^"""^"",,,zn/%"""oB@@@UMpu@@@@@@@@@@@@@@@@@@@@@@@@@@@@@M,"^"(@@@@@@@@@@J""""""@@@@?""^""O""""l<0qd]+"^":Cux&p"""""""^^^"^""    //
//    ""^"^"^""^"""""^^^"^^"^"^""""^^""""oXxM,,w@@@@@@@@@#U@@@@@@@@@@@@@@@@@@@@@@@@@@@@BB""""&@@@@@@@@@B|""""",@@@B""""m""""[f"It/|o""^^"lpjn#,"^"""""^"^""    //
//    "^""^^"^^"^"^^"""^""^^^"""""""""""&|j*"ZX@@@@@@@@@@h<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@:""*@@@@@@@@@@Bq"""""!@@B""""*""""m,"I((awa""""^,kjr&m""""""^"^^^    //
//    "^""^""^""""^^"^^"^""""^"""""^^",B(U#""kB@,@@@BJ%@@Bm@@@@@@@@@@@@@@@@@@@@@@@@@@B@@@8%}j%%@@@@@@@@@@#""^"""1@@,^"M"""":&vBB&Bjiv:"^"""^lOfjo,""""^""^^    //
//    """""""""^""""^"^^""""^^"""^""^,#/n8"""b@B:&II""",%_@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@MOaW@@@@@@@@@@@B""^^"""@@@""k,%BBB@@@@@@@Cqk"""""^""Mu/@M"""""^^"    //
//    ^"^"^""^"""""""^"^""^"^^^"""^":L/u|""^^n#u::*;"""8mit@@@@@@@@@c!@@@@@@@@@@@@@@@@@@@@@W#@@@@@@@@@@@@W"^""""""@@>BB@@@@@@@@@@@WkLmL""^^^"^":O|/%:""""""    //
//    "^""""Yh,MZJ*Qxi@",""""^"""^"bft%!^"^^"""8,,%""wWM"IB@@@@@@@:"""%@@@@@@@@@@@@@@@@@@@W8@@@@@@@@@@@@@Mq(!"^""W@/&@@@@@BBB@BMiJp8r1m"^^^^^""""8r/@r"^"""    //
//    """<d*h&@k%a&@o@pOB"""^^^^^"%/tB,"^"^"""&W,:f@-Bb"brB@@@@@@%""^"B@@@@@@@@@@@@@@@@@@8@@@@@@@@@@@@@@8dddddddb@@@@@@%@@@@8WI::-BX8Q(m"^"""""""">Utjo"""^    //
//    ""]lBB#B@@@8@@%ZBf1"x"^^""!bt[8"""""""""o@;;#@IW?B"x#@@@@@@""^",B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@M%dbbdbb&#h@@&@@@@@@@@@@%|oZ,YJ}/"""""""""":#f|B~""    //
//    ""|8db@B@@@@@@@@@%k>,""""Mr|mY"""""""",lB@@B@@@@@@%n,!BW@@B,,,,M@@@@@@@@@@@@@@@@8@@@@@@@B@@@@@@@@@B%ddddd%*dbdbbb&@@@@@@@@@@Bm-@@@@@@@C,,,::;;lCz/kq"    //
//    "Wk:&@B@@@@Bb@@@@c@&>?d,B/(&:::;:;:;;;>8@@@@@@@@@@@BIIIIIIIIIIIB@@@@@@@@@@@@@@@o@@@@@@@@@@@ha@@@@@B%bdpdbMkdddddddW@@@@@@@@@@@@@@@@@@@@@@j!!iii!iktt%    //
//    ,8oXok@B@_i)_I8@@0@@*XhQf{8llllIlllll!1@@@@@@@@@@@@@iii!!!!ii>-@@@@@@@@@@@@@@Ba@@@@@@@@@@&qpd@@@@@@%bdddbphdddddbd*@@@@@@@@@@@@kd;iB@@@@@@q<<~+~+~(aj    //
//    ::]&B@B%B:;t;lW@MBLZYBu/bqiii>>>>>>>>><a@@@@@@@@@@@B<<<<~~<~~~k@@@@@@@@@@@@@@%@@@@@@@@@@*8Ypdd@@@@@@bpdddLkdbdddbdb@@@@@@@@@@@@@8%@B%@@@@@@%________o    //
//    l:#B%B@BpB,::caBabW@qX)W+~~~+~+~+~+++++++LB@@@@@@BL?_________-B@@@@@@@@@@@@@@8@@@@@@@@@bbdhtdd&@@@@@@@BdbUbdddddddhB@@@@@@@@@@@@@hhhhhB@@@@@MB@B&aX)]    //
//    lllp@(Moo|Yo+bhiBBpXcf%_-------------???????-?????][)xa@@@@@B@@@@@@@@@@@@@@@@@@@@@@@@@mdddd&%ddB@@@@@@@@@qbddbdddb%B@@@@@@@@@@@@@aaaaaaB@@@@@hhhhhhaa    //
//    ?]]]fa##Z}hM-{bb-Udtm8?????]?]]??]]]][}fk%BB%88%8#hhhhhhhhhhh@@B@@@@@@@@@@@@@@@@@@@@@@@Mbbbbnbddb@@@@@@@@@Bbddbddd@@@@@@@@@@@@@@BaaoaaaaB@@@@*aoaaaaa    //
//    ??]]??}]]]][j][[d#-%r]]][}ZMBBB%B888ohhhhhhhhhhhahhahhaaaaaaa#%@@@@@@@@@@@@@@@@@@@@@@@@oddbbbjWbdbbd&%@@@@@@bdkbbp@@@@@@@@@@@@@@ooooaoaoa@@@@Bo%ooaoo    //
//    ][[]]]]][]]]]]u%t-B@B&#aaaahaaaaaaahaaaaaaaaaaaaaaaaaaaaaaaaaaaB@@@@@@@@@@@@@@@@@@@@@@@@dQbbbb0#kk#Obpdh@@@@@bbbb@@@@@@@@@@@@@@@oooooo*oo@@@@@*oooooo    //
//    }{jpB%B%B%%Wah%-+%haaaaaaaaaaaoaaaaaaaaaaaaaaaooaaaoaoooooooooaB@@@@@@@@@@@@@@@@@@@@@@@@Bq0bbpopbhbhkh0mWB@@@@kd@@@@@@@@@@@@@@@Bo*o**oo*o@@@@@B*oo*o*    //
//    hhhhhaaa8hhhk%ik%%haaaaaooooooooooooooooooooooooooooooooooooooo&@@@@@@@@@@@@@@@@@@@@@@@@@@mw#kkkMkahhkY#%Md@@@@@@8@@@@@@@@@@@@@oo******W@@@@@@&*o*o**    //
//    @@@*aaaab%@&W]B@@@@@@@ooooooooooooooooooo*ooo*o*oo**oo*oo***oo**@@@@@@@@@@@@@@@@@@@@@@@@WO%ZdkLkkhhOdh#B8JYC%@@#B*#@@@@@@@@@@@@**#*#***B@@@@@BM*#****    //
//    @@@@@@@W%%8o?BBBB@@@@@@@o*ooooo*o**o**o*o**o*oo****o*************W@@@@@@@@@@@@@@@@@@@@@B#pkho8kkdkhov8@WMqB88@@@&8#&B@@@@@@@@@@***#**##@@@@@@@B######    //
//    @@@@@@@@@@Y[%B88888%%B@@@%****************************************#@@@@@@@@@@@@@@@@@@@@BW0&n&%&@mqoL&@@Wj#W#8B@B8WMMW@@@@@@@@@@%#*####B@@@@@@@W######    //
//    @@@@@@@@@@@%8WMWMWW&&8%@@@B********#8&*##8***####*##**##***#####*###@@@@@@@@@@@@@@@@@@@8Bw1Lm%@%Q0fnbBBB#M#%@&@@WM8ab8@@@@@@@@@@#####WB@@@@@@@M######    //
//    @@@@@@B@@@@@8MMMMM##MW&8B@@M#W*#o*###*####*#####*##*##*#############8@@@@@@@@@@@@@@@@@@W###W8WWB@@B#M&MMMMM@J@@@&&&&%M#@@@@@@@@@@#M##@@@@@@B@%M###MMM    //
//    @@@@@@B@@@@@@@*######MW&%@@B**##################################M###M@@@@@@@@@@@@@@@@@@###MM##MMMMM#MMMMMMMMW@@@@@@@@MM##@@@@@@@@@MMMMM@@@@@@MMMMMM#M    //
//    @@@@@@B%BB@@@@@B###*##MW8B@@########M##############MM#M##M##M###MMM#MM@@@@@@@@B@@@@@@@@#M#MM#M#MMMMMMMMMMMMMMM@@@@@@@@MMMM%@@@@@@@@WMMM@@@@@MMMMMMMMM    //
//    @@@@@@888%BB@@@@&MMMMM#&%BBB%WMM##M#MM#M##M##M#MMM##MMMMMMM#MMMMMMMM##%@@@@@@@B@@@@@@@@8MMMMMMMMMMMMMMMMMMMMMMW@@@@@@@@BMMMM@@@@@@@@@MMB@@@@@%WMMMMMM    //
//    @@@@@@&8W8%B@@@@@MM@@@@@@@@@@@@@BB#MMMMMMMMMMMMMMMMMMMMMMMMMM%%8%B@BMMM%@@@@@@W@@@@@@@@MWMMMMMMMMMMMMMMWMWWMMMM@@@@@@@@@MMWWM@@@@@@@@&W8@@@@@@@MWWWWW    //
//    @@@@@@W&MW&%B@@@@@@@@@@@$@@@@@@@@@@@oMMB%BMMMMMMMMMMMMMMMMMMM8%WMMWMMMMM@@@@@@WW@@@@@@@MMMMWWMMWWMMWMMWWWWWWMWM@@@@@@@@WMWWWWM@@@@@@@WWB@@@@@@@WWWWWW    //
//    @@@@@@WWW#W&%B@@@@@@@@@@@@@@@@@@@@@@@@*WWWWMWWMMMWMMMWMMWWMMWWMMMWWWWWMM%@@@@@WW@@@@@@@MWWWMMWWWWWWWWWWWWWWMMWW@@@@@@@WWWWWWMMB@@@@@BWWWW@@@@@@@WWWWW    //
//    @@@@@@WWM##W8%@@@@@@BBBB%%%%BBBB@@@@@@@oWWWWWMhW%o#WMWWWWWWWWWMWWMMWWWWWW@@@@@BWW@@@@@@WWWWWWWWWWWWWWWWWWWWWWWW@@@@@BWWWWWWMWWW@@@@@WWWWWW@@@@@@@W&&&    //
//    @@@@@@BWW##M&@@@@@BB%%%%%88888%%%B@@@@@@BWW@@@@@@@@@BoWWWWWWWW&WWWWWWWWWW@@@@@@WW@@@@@@WWWWWWWWWWWWWWWWWWWWWW&@@@@@@WWWWWWWWW&W@@@@@W&WWW&@&@@@@@@&&&    //
//    @@@@@@@MWMMM@@@@@B%888&&&&&&&&888%B@@@@@%d@@@@BBBB@@@@BWWWWW&%@%WWWWWWWW%@@@@@@W&@@@@@@@&W&WW@@&WWWWWWWWWW&W&@@@@@@WWW&&W&&&WW&@@@@8&&&&&&&W@@@@@@&8&    //
//    @@@@@@@@WMM&@$@@%%8&&WWMM%#WW&&&88%B@@@@@@@@B88&&&8%B@@%WWWWWWWWWWWWWWWWW@@@@@@&W&@@@@@W&&WW&@@@@%&BWW&&&&&&&@@@@@&WW&&&&&&W&&&@@@@&&&&&&'''ll]]jjj00    //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ROW is ERC721Creator {
    constructor() ERC721Creator("Rider On The Wheel", "ROW") {}
}
