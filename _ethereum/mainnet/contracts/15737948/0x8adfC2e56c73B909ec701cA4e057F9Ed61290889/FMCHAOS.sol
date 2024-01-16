
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: feel my chaos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    mr|wTxmKB$WdMZIG})zXyPKdGz;|Vxv|<vr~<*)r):<^=xu)xxxr^<*!^=rvv|LY)xi}uYViY}i)rc}vYv|YTVLVXulykXXkIscuckzVlT}}vcwXwzVkycczXYVcVlcVVYLTllLTVV}lcuTzmOMwyy    //
//    d^,|zY##@BgggORZVulVkwlWKzVsk|rrxuvVV)".-,<xv<~)v)^^)!:-:_*x*rvv^xr^v^**_=!!^"-=YVLT=x*krrVTwVlY<*)vvkXcyzzwkzIzkXzmzXzkViTXwTVyuLYcTTiLuTTY}kclwkTL}V    //
//    T^~!|lQ##BbRDRO3cTVl}ixVw}))v*vylV)^Y^_-_:xx)~:"!|T}Lvilv_~!_:;)==~rxv*=.```-``-=*^vvl^k)}}LcyyYv*rYiVkTx}yywXIskIVc|xlIcVVywlTVc}iLTLiiuY}LLTiuuPxxLk    //
//    ~=:)x|$QQOOZDDMwi)VyTXwTc*=i)uriV9mLyv<^)*l^!-__-.xr^:~v^,;:__"=^--"=L)!v))rv!_ '^vcuz|wwzywwylcxLxv}TV}VlkucyyyksVkVVzzwkzwuY}l}TuYYV}Lyu}xVzYvylxvxV    //
//    =;^|yID9OmMGX3zyKxzVvc*Y}uiYlGx|xvLyWrxzTVVvTr":=_**::;)|Y*^<r<=:,:)uY}ir!=:|r_`.,*r)rx::lxxuiluV}uLYuTxTcluVykkVuvwXXsywxIkswVVcTVkzkVyIVu}TkclzyxixV    //
//    x!=rVwgBgGOs9yPlKmku}WcV))r^v)rx^)<TVi*xXL}r)u^kux*x;^)**rxu;<;x="_"*))Tr<uxVyuLvx)v^rxYvxlcLx}lyLXTVL}yyyIwXKXPI3sKiIO$B##VV)xurxxc}uulXwVlVuLTmyxx}y    //
//    IQdxvYIOBMmDzukzkmYxrwY)L*~;)=|l)^!*i)^!<}xvTccKG3X3VTkvur)x~i*=~*=!^^uTXwV}zTVv}Tvuxr*Vxrv:!*r}}xy*iuuVPmXwuIW0$QQB#@@@@@#Y)l~)X}lluzyT}TVyyVlVMwYVuu    //
//    ,xLvcxVGP0MK3sGKluxczTv=*^;~)~;;<rx}}x:^)Vi|ixx)LXWVwYVxwxvr*xLVwuxuyT)r)T^;)Vwz}wx;i):xvvYxuLzVsMOdO98QBB##@@@@@@@@@@@@@@0VwyTwmkykkmzXwlVlVcTwXIyzVi    //
//    rkxrxx|YwwszIzGsyLlxvrPd$W3WZmXKmMWW$gMPgZWsGMWdGWMMZdPsZGWwzsMRObD$D9OMDZWWMRQg0B#B#B8###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@kIV^vyzskVksmzGmkTkMVcKIzXsz    //
//    Q$Kix))xYczzYLILxLL<)xRgRgQ#@#gBB#QB##Q8##@@B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@yIIVmkLv*)zmIXsXVuXPuuzTYxxu    //
//    Q#WTY))xTlX33iyv)xxxYvcBQ#QB@#QQQ0g##B#@@@#@#@@@@@###@#@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BVw}wTVyVLx;xl}VccYuwVLsVT}xx    //
//    0$MTWmmOBgOQBdQWIVYx)rr9@@##@8B#B###@@@@@@@@@@@@@@@#Q###@##@@@@@@#@@@@@@@@@@@@@@@@@@@@B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@QLVXckwxLVwkmV}LwyVlxVuyTlxxxi    //
//    BDgd$ysgRbM8#d8ZO0PPTIcIGMwOWxVmWVwWMMMGz@@B@@##gQQ0Ggg$Q9O##B###@@#@##B#@@@@#B###@@@#0QQBB##BB#BBQgQ#@@@@@@@QOOOGZVvTx=!=^|YxkwlcVVXzzyT}Vur*^VLYxiyV    //
//    MbBQZsQBZKXZPKgbbZGOmO$DdzYlxv)r*)vcLr^~*#@@@@#B;v*~:,,--'-_.`!~,=!",'`.ZQB##O._--"::_.- `'__.,:v*^:=rQ@#QB#DxxY)*x)!:=:!:-!:,xVkzwVXyVTyTuVYVVIPzvIPy    //
//    WwQQQQ@#gWPRwMMZOkcKZ9bmKksw|vv)!!=*:,-_;B#gBBgO'_-_,-.`'-_```"_'```   `GQD#Qg:--."):.-.``-.!__:*:|r|Y@@@@#@QT|xY::^xx|vr~))~-*|TwuTVuLuY=!v}zcXwyl3zx    //
//    MBB##QB##mMPdOg$QgWlXKkKIY=ixTTzYVx)):"!v#BQB#QZ!r*)=:_-.--``._``_:-'`,:$#$@@@)"-"-)l:_::_,_:~=)xrLxr)#@@@@@@D|~<v)=_":,,--_-_-"=xullu}Vur^YyYlvvylmuu    //
//    BQQ9gQgK0zz}l}sODOGwLziuiLx}LXzIyx;||<vL3@@@@@@RTz):v)-`-..``.-.-"=--'!)B@#@@@_,-"_,i)!_::!;!;:*v^r=|^B@@@@@@gxv*v^^_:!~===_")vxYc}TLxxxi*xulyl}Y}x)v)    //
//    QDRQDDObOmgIscwWOOZW}cyzGG3mTlysT}LGr"_.z@@#@@@G;rVViY! --```.':_`''._,:$@#@@@,:)<*vx<!_:":~*=:v)iwcc*R@@@@@@QLiuyL|)L)ilTlTVlL)uVYTuxxxlivvVyul|vxvi;    //
//    #QgQ0sMQPu}x3wPg#8M$OmbO$$bPzTxVOQ0#@#B0Q#Q##@@#B@@@@g|,:"-_",__,,,:==;;8@@@BQ^r*^rX}!=!;<*|rx||vT@@@@@@@@@@@@@@@@BTzwI3ViLwkVVYcVXwXcwwkyVVkIVxVVY)}L    //
//    @@@@QwWXPulsQzO$g8g889RWMd@@@@@@@@@@@#@Q@@@@@@@@@@@@@@@@#BBB#g#g8QO0@@@#@@@@##@#@@@@@@#gB@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@0lwVVVVXyXzXXyVkmz|VIIXVwTxv)^    //
//    @@#BOYY}x)vibGbdOQ8$kTzOcL#@@@@@@@@#@@#@@@@@@@@@@@@@@@@@@@@########B###@@@@@@@@@@@@@@#@##@@@@@@BB@@@@##@@@@@@@@@@@@@@@@@@#BKwwws3zsXIVcwIsVs3IsksmuT3d    //
//    B@@#BR$dmwwWMVIkKIYv!^*}<*g@@@@@@@@#B#@@@@@@@@@@##@##B#@#BQQBB8BQQQBBB#@@#@#@#@@@@BBQG8QB#QB#######QB#$@@@@@@@#@#$g######QIywTxwXsLcL}lcwwsm3mIcVXyyM3    //
//    B@Q#B09WmuL=kxmwwyr<*;=r^xVxVx:^^3Yl=^RB@@@@@@@mcrxlv**vY:,-,!!:!LdBOzxwgBB###dMg##G*!vvVLc)yVVMIlkvIvK@@@@@@@@Rcv)TkRzx}VkVXVlXmz|)vLVIkzsKKIkyVkVkP0    //
//    Q#BBQdPWK}TV3uWWyc**^,:vlluVvx)*rx=!!:*Q@@@@@@#Tr!:":rL}r``'--*sg#P^-!!~^;vKYr^^*xM@QkiVwuYx;VIXMXPwuM8@@@@@@@#XlL*wuir)}VI}XxvYlyxxwYuXIKmXKmkVIKcKPD    //
//    QMbBQgWwIx}zXwXIYv)^;",=;x*T)xlc}r^^,-:#@@@@@@@8mWXTYYywyx)XO#$Icr;=:,=;=:~v<<=^*)^rP#@$PziV)VwszsX|xdQ@@@@@@@BYlxruzuxLcVwVTVkkGMs3ZmIKGmMmMMGlVG3POP    //
//    RQ9#Q93PdGKliYyVYvr=;:^}*cT}x}cixx*=,,*@@@@@@@BumzG$QggQD$MWV^r*;^^)r^r|=~rDVx|)|)|v=*b#@#QDGGGWMMO$Q@#@@@@@@@#Vc})VzVz}lyyT}kwwI3IKKkmywIKzGMycVW3IMR    //
//    bO$##MzKD$mzcxV3}*s)*^xL~ullxzIkVm}xxrl@@@@@@@QLxYiTlivx;*r**~*v)<;**^)|)xw@BzXVzwkz<)xVR$DQ######RgZW3@@@@@@@@cxVczVIMTx}TluVVlkzkVWyw}lVcYVwLLiucVVO    //
//    cVMPRmkW$Oi^YyssksKs*)*:r:v<|KY<!rx))iG@@@@@@@#sPsXzVTwy}kuwW}uVucv)iVVVyck@QTKcczyzzyVIO3kIzilcsTTxyWW@@@@@@@@|rLyvv^iVLuTyIuuluVckcXcyTVlY}}uciLxxKM    //
//    VvuRQ0X$D3i**=TG)rvir*T^V^*x}lixvLxLxYO@@@@@@#0*==*;^^ui)uk8@GkXzsl}ilzzIzy@QI3mkIwIXVsZ89VyIl|vxxVzzMG@@@@@@@@vrx^:=,,_~xT}}xYV}LcyXm3OOdwcIcVL|||)kw    //
//    bcsORGVXmkix}vvci*xr^=^|)*^^**xYw}vVzy0@@@@@#8Pr;*rvYv||<|VQ@mTxxVYul}VzVVTKcTcwiYxixrYVQ@cywulzuXyKOWs@@@@@@@@Y::ir=-""-"c3K3WOMZs9XGVzkxr^^)uVzVLYLz    //
//    Q8KIwlckyXV}yiix"-:::"*v|^!^r*x}lXVmc}Q@@@@@@#Mx)vril^)):!*W#GywTr)r;;xIr*::=rvvi}xYx)TVR#kwVuyk}}VPWPy@@@@@@@@3xryr:!_:-_!ks3kVVukzKuxLYv)*^rvYLTxx3i    //
//    ggMRKcyyzY**uYzur:!=!,~^)*:r)|ucyl}Xyx#@@@@@@Bz||^)));^x;*rwIvryu^)vvTuVTx=:;:rYrL)L*;xcB@wVcVXzIXI3d3s@@@@@@@@b*yY<":!,";YckVTyyTIPGKLwlxrr)lTTx)xv}l    //
//    #bVbP3sWMX*=urmmlY}yzlwzVTv*vTyluwwklk@@@@@@@@dyuxi*)<|x;*vxr)lV}rvuY=*)~<^!:~r)xvxxvrLkQQVusYyPPcTci}Y8@@@@@@@$luVTTcr~rVz}iLL}VTTmOPyuVxxxLv}llTcT|z    //
//    XY}wV3GMkWz)sXXwykPIKkwYIwL^*xXk3PXmyZ@@@@@@@@GwlxTLwYlu|uXs)Lk}luxcx*;v^^;*^v)vLVkyyvivLxvws)Xb}lykmzwQ@@@@@@@#vy)}uc}iVVcYlYcuYvLIV}xxLixxlzYylz}uyV    //
//    WYuVclLmMbIzGwGXVwssz}wcIyT)vxwIIKIKkd@@@@@@@@ukw)=:TVIX}ylkx;s###Q##QQBg$#8RgQQQ#QQQ9OkcTYywVyXMuIRDzkQ@@@@@@@@IVrVuyylcyVl}xL))!<lwcvrv))))x|ysKwTmk    //
//    WVkTVVvymIsMMIdZXsPKsyIccw}|)T}wsMKyz9@@@@@@@#wGIkyTzxVV)lssTYcTVT}gMrT}xk@w=xxLy@YlVr*rrvxx|xTmIX3P$MmR@@@@@@@@bu*cxuwcxTYivxixx)YXzVLiTx}xTVricwwXId    //
//    B##RbViswkXOOc9QPmGZMsVx))zuzkyXs3Ixr$@@@@@@@BwwwkuVu)iY*)VVYxcZ80RBQQg9QB@#gO$gQ@08OOlLxuuywVuXPXKGWPIb@@@@@@@@Bx)Vr}Llxyli}uGsGuV}TLl}ciTVskVlsbbXI3    //
//    B@@QBdD##BQg8R$QZuvmOMVT3WXiywVVXKXkvB@@@@@@@Or|civxv^vL^*}uuLcVlxyR$MQsV3Qs3bQPP@yiY^)VYVVIIwVPwzKGWIVu@@@@@@@@@dPbOdWGKODb3m9ZOXsPkwI3KzsXm3zlmZyybW    //
//    B@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@Ri}YxxxLr|x^|YclxvvxxLO$zQVxzRVzbBMX#zxv=xTV}xXyVLmzcysywxi#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@RmOM    //
//    #@8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@PccY||)v<|r)ul}xixYxVxObiO***):*)Oxv#z|)*xyu|xVywmmzImsmG|LB@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$PDM    //
//    #@g@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@s}xlVywy}ux)lTLLxYLxivOWT0xrr^**xOlrBGxTlcViiTxxcVsVwzzWw~~Q@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@KIdM    //
//    Q#RB#@$BBB@@@@@@$bg8g$9MbsGm3GmskLcvg@@@@@@@@YcY)iTluiVi)Li)*r^~;^^mmxVv*TxxYVzx}QWr)^|iYxYv)vumKykwmVVV8@@@@@@@@0VusPKsI3zVmGdGdbd9DZ@@@@@gM09dMGVOZy    //
//    BBQ$b99BQ#@@@@@@wYsMVuVLT):|ivvkVyTTg@@@@@@@Qvv)^~*))<*)))^^^<!=":^PVvy*!^);^|Y*|gl=<*|iY^!^;;xvlxciLiiYP@@@@@@@@B~=vcVT}T}VwIWzkTYuT}@@@@@yxv}y<x|PmT    //
//    BQ$bPPWQ8B@@@@@@GuimxxT|lxYwu=*zL}x)8@@@@@@@#^vvr^^xi!;xxr^;rx!r*;^suvi)<)}v^|YxxOVv*=||YxLYc;)rv)i=LrlrV@@@@@@@@@*-=;rviLv|xxxYxLx}kX@@@@@kiuk)}iviVv    //
//    Q#Q03D#@@Q@@@@@@QYI03uwPTivuur*})Y)*#@@@@@@@Q=r*<=^~):;xx~;!*Y^rx)rK|*x))YuxxLxxxclvr<))ivYTl<~;r^r:rxx)xB@@@@@@@@Y!:rv||v**xLTVViiLyV@@@@@w}yuTVsuVcx    //
//    dGM$#@@@@#@@@@@@g*vRmWOGsVvxY~r}^}Yv#@@@@@@@B*xLxL)=;,~rr*~!!^^;*^vXr)L)vV|v*}ii)k}v^;^rrxvll**^rrvv)v*LxQ@@@@@@@@3,xiuTTxvr)lc}L)^))T@@@@@XiT}xyk)ii}    //
//    DPI$##@#B#@@@@@#dIRBOGZMwx!YT^^^<xYT#@@@@@@@QY=:!Y)*r!^|xr~="!~~<vvzivYxL*^,_:*LYkLv|<x|uTLc*xVr^*xiYr<;r8@@@@@@@@GrYTVVLxxrvvxYxr)vxY#@@@@Pl}VVzw^v)}    //
//    swWQ#@@@##@@@@@#bG$#Bbb93cYcT|xz)xxT#@#@@@@@$i|<~L*rx;<xLi=^~^*)*vxLxv|ri*=",<:|)T)*^^vTx~<=Yxc|x|YTx~:)rQ@@@@@@@@vrcTx)YLc}x*rV}YlliTB@@@@by|)*lv:Y;*    //
//    Q#@@@@@@@@@@@@@#g$@@B@@BQ$8DDMbQdVvk@@@@@@@@#xXl|xiviv*xxx*vx!=YLTT))x|rvV="!^xT))rvrrzw)vuxlcl)xxxT))!v}#@@@@@@@@r:rrrr==*lT,=*lyYx)VB@@@@MvLvxwy}:~V    //
//    #@@@@@@@@@@@@@@#DQg@@@###BBQQBQBBQ8B@@@@@@@@#}YVuizYL)xx|xxx)=x)lxVL|x||)iv<TlYxvvvrrP@@gsVc)iuv*ruTixxY<#@@@@@@@#i)l)<)xxixv)kxlxyyKW#@@@@B$Q$gBQ$)cl    //
//    @@@@@@@@@@@@@@@@g##@@@##@#B####@#0$R#@@@@@@@@KMzmuzuTvvxvvYlxlLrl}}Y)v)ivT}XlxlLVzlxyB@#LTVyuvVx|vYLvTlYY@@@@@@@@@G}MZMMsDRDOO0OgMW3$bD@@###BQB####ggd    //
//    @@@@@@@@@@@@@@@@##Q@@@@@@#@###B@##Qg#@@@@@@@@09MOKPVkxTLx}VYLiYLxLlzixvvu;)Llx}i}Vv~B@@@k}VVuwyVx}xxi}lx}#@@@@@@@#MTwKX3Z0KkIX8$0WXMZ3d#####$Z0D##dsQQ    //
//    @@@@@@@@@@@@@@@@@##@@@@@@@@@@B#@@@##@@@@@@@@@#BM9GcIuimI}cuucTTkc^r}L}lx}Y|iTyV}YIxX@@@@mlkzVcvVTY|vxcVYx#@@@@@@@BOsxLzmmZmZXsdWwOz3bGP####B$D9BB#dGQ9    //
//    @@@@@@@@@@@@@@@@@##@@#@@@@@@@#@@@@#@@@@@@@@@@@#@@#g8DZ$OwzczkRKMOdRsy}yixVTLVuVTcK}z@@@@Qz}yT~};ix=*Lv*|9@@@@@@@@#8OTvwVV^lOYylKsyysZ3PB##B80RdOQQ$gdQ    //
//    #@@@@@@@@@@@@@@@@@B@@@@@@#@@@@g0#@##@@@@@@@@@#BMQ@@@@@@@@##@@@@@@@@BdVX}ucyuxiMuO$W0#@@@@kTl}lT*=!<ukVx*$@@@@@@@@@#QGmVvObZ9OMOR9MM$99b$QgDMQdMZ$QO$sZ    //
//    #@@@@@@@@@@@@@@@@##@@@@@@0B@@@BQ#@@Q@@@@@@@@@83d####@#@@@@@@@@@@@@@@@@@@#@###@##OPwV$@bO@DVVwl=::,"VcPlx8@@@@@@@@#$ZxVX=GcMMGzkKPZK3OdcZRdRMDRbgQQQ#BB    //
//    @@@@@@@@@@@@@@@@@#@@@@@@@8#@@@#$B@@#@@@@@@@@@9KM3dbmzKbOkKbgg8B@@@@##@@@@@@@@#gdR0dO@QGB@w*ix^r_:,=^yIWbB@@@@@@@@#gk!=T~w}uKIi^YusX3Md|VdD800$M9$B#B#Q    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BB#@@#@@@@@@@@@D0b$gDsyGR9GWOQ8@@@@@@OPMOB@@@@@@@QyXkcD#liQO;:!L~;<rVv)3PQ@@@@@@@@#$WVrx^rw}yMP)xXlx)cKWWMgM90#@@QB##QMI    //
//    @@@@@@@@@@@@@@@@@@@@@@@@#B@@@@@@@@@B#@@@@@@@@#gdd9$bGZg$MR8RO8B@##BOwVKK3PWXPGQB#9Kdg@##@#uxxxyM3GB3W39g@@@@@@@@#gODZYLwmzyKXIG0dkxZbZXlVxuG8#B@#@BQQs    //
//    @@@@@@@@@@@@@@@@@@#@#@@@B$@@@@@@@@@#Q@@@@@@@@Q$ZZ$QPP88R$bbZ9ORg9$kMzk3yMWZ9VZOWsMG##@@@@BQKixPBBBBRB###@@@@@@@@@##Q9M3M9M8ODQ#@#$$MDgg8QgD0BBR80gbzzY    //
//    @##@@@@@@@@@@@@@@@@##@@@@#@@@#@#@@@@#@@@@@@@@##$BB#QBB#BBMZQDgs$R$bbOO0MB##QB9R$3dGQ@@@@@BBB$ODQ##QB#@@@@@@@@@@@@@#B$$WQQ##Q8QB##BB#@@#@@@##@@gb9Omml)    //
//    #@@@@@@@@@@@@@@@@@@@@@@#@#@@@@@@@@@@@@@@@@@@@#@@@@@Q@####Qg###8QBB8$0QBQ@@@#@##QgBQ$@@@@#@#@#BBB@@#B@@@@@@@@@@@@@@BMdDG$Q#g$Q##B##@@@@#@@@##@@@8QgWKks    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@####$##@Q#gQ##@#B@#8$RBBg#@@@Q@@QQ0Q#@@@@@BQ##BB8@@###@@@@@@@@@@@@@8Pb9MRM$GdggB0BQBB####@@@#@##OQQgB0O    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@####$Q$BBBg$B#@#Q##QQB##8Q##@B@##B#$Q#@@@@DgQ#BQQ##gQ###@@@@@@@@@@@BQ#Q9$Z0MMO9$OgQQR#BBBB@@@@#@#@@#BOZ    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@####@#QBQBB@#@@#B#@###g##@QQ#@BBQB@@@##gQQ$Q$D##QQ##@@@@@@@@@@@@Q$g$O8g8#$gQ09Q##B#@#B@#@@@@#@BgZ00g    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@#@Q#QBQQ#####Q#@#@#$##@BQQB##$B@@@@##B#8QQ$BBg$B##@@@@@@@@@@@B8gO9D$B#Q$BBQQ#@@@@@###BQ#@B#8Q0bW9    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@#BB@@@@@##@8#QB#QB#@@BB@@@@@@@@@@@#@##BBBBBQB##@@@@@@@@@@@Bb3Pm3s$0DdBBBQ##@@@@@@@##QDKyGbR9MO    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@#@@@@####QB##@Q@@@@##@@@@@#@@@@@@@#####@@#@@@@@@@@@@@@@@#BBQOR9MGzsZ8Q$B#@##B@######B$QBQQB$    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@#@@#@@@@#@@@@@####B#####@@@#B#@@@@@#@@@@@@#@##@@@@@@@@@@@@@@@@@@@###B#####Q####BB@@@@@@@#B@#######@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@##@@@@#@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@##Q#@@@@@@@B@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BB@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#B#@@#@@@@@##@@@@@@@#@@@@@@@#@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Q@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@#@@@#B#@@@#@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@#@#@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@###@@@@@@@@@@@@@@@@###@#@@@@@@#@#@@@@@@@@@@@@@@@@    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FMCHAOS is ERC721Creator {
    constructor() ERC721Creator("feel my chaos", "FMCHAOS") {}
}
