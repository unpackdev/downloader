
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FUZZ_GAFFcartoon_3.5
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~(((~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~:~~:~~:~~:~~:~~:~~:~~:~~:~~:~~:(J7C<~?74&~:~(J>:(V+JJz1+J,~:~~:~~:~~:~~:~~:~~:    //
//    ~~~~:~~~~:~~~:~~~~_((__~~?4z(-~(u5~~_~~~~~(IJ5(:(d5<~:~:::<+n,~~~:~~~:~~~~:~~~~~    //
//    ~:~~~:~:~~:~~~:~(AJ--_~~?T4dx~Y($~~~fn_((~(fvS2Skgkau9~~~~~:~?1~:~~~:~~:~~~:~:~~    //
//    ~~:~~~~~~~~~~~_J<<<<<:~(HaJJJg>(4_(Jt~?a_~?TGdVVvGUS,~:~:~~~~:~h~~~~~~~~:~~~~~:~    //
//    ~~~:~~:~:~~:~(Z(((JJJ-(~(-UnJX4J@J=~1~~<WxC(<(dN-KX.W~:~:<?T9WxJc~:~:~~:~~:~~~~~    //
//    ~:~~:~~~~:~~:/7<(v=~~:~~(&M-(TSJjYCY^3--<~~_(>(<dJ4kWp_~~:~:~~?T,~~:~~:~~~~:~:~~    //
//    ~~~~~:~~:~~~~~(Y~(((-~?TTn-1-~_?3_~~~~~~~~j%_<<j<dNmZTT<~<?TBHX&+4,~~~~:~~:~~~:~    //
//    ~:~:~~:~~~:~_JY4V3:~::?7Tf4XD$?!~~~~.~~(J<~?<_~(fjM57?7o:~:~:~?G-(T<:~~~:~~~:~~~    //
//    ~~:~~~~:~~~:~(Z<~:~~:~~:(jHNO<~~.~~.~~(1>_::jgMM:+I(Ju,~I:~:~:_~?G~~~:~~~:~~~:~~    //
//    ~~~~:~~~:~~~~z:~:~::~~:(<~JWk_~.~~.~~.(=c(gM#WXJ~:#JY>$JgW-:~:1GJ3:~~~:~~~:~::~:    //
//    ~:~~:~~:~~:~~//_J>~(+3~~~~><H/~~_(<+.~.(jdMMaWuW:~$j$j4xHJN+i~~J>~~:::~::~~~~~~~    //
//    ~~:~~:~~~:~~:~?RC(gM3(C(<~(vTWnmz<:<,~~_N#TQQy=(~:G&7dJKTpd?hWv~~~~~~~~~~:~~:~~:    //
//    ~~~~~~:~~~~:~~~?g5(5d@(#:(!(JVMdNYMNgo~~J`   .JW~~dKWv85:#J~_~~~~:~~:~~~~~:~~:~~    //
//    ~:~:~~~:~~:~~~:~~~(3(J30~?c(6>dc<HmTWMl-~.<Z!(J1_((6dI~(&%1~~~~:~~:~~:~:~~~:~~~~    //
//    ~~:~~:~~:~~~:~~~:~~~(~~j(jJaJ(7l>(Nd2<(JwX6gWB4j>(JY?7>~~~~:~~:~~~~:~~~~:~~~:~:~    //
//    ~~~~:~~~~:~~~:~~~:~~~~~:~:~:~(JrnJT5ZTTXZXd01+<j>((-~~~:~~:~~:~~:~~~:~~:~:~~~~~:    //
//    ~:~~~:~~:~~:~(,::~::~~:~~~((gpv=~(J3>>>7VC7C>>>j>JdWh,~~:~~~~~~:~::~:~::~~::~:~~    //
//    :~:~~~::~::~(Mb~~~~~:~~~(us7!_<<?r?S4jzGuAu+&<>j<fJgWB+~~:~:~~:~(J<_:~~~~~~~:~~:    //
//    ~:~<<___~~~~(MMp~~~:~:(Z+W^~~.??TNdYC(kUUkZd(R&f(y45~(J~~~~~(Jzzzzw_::~_:::~:~::    //
//    ~~~~~~~~~<<~JggMp:~~:~((Bb~.~_<?7KhUZdbXZJXSSdH=_~~iJ:~:~~(zzuzzzzC<::_:~<<:___:    //
//    ~(((_~~~~~~~Jg@gMp;((:(4XMaJJc6+JXR?WXXWWwwVJMdMHQy~~~~~:~(zzzzzZ>(<:<+<zvo-<(((    //
//    (zzzzo~:~~~~J@MMggNJx<1+1OX0zzXU?6JC7?CC<+>>>d<?3THV&:~~~~(zzzuzx+<(<<;jzzzzw+<<    //
//    zzzzzz>~:~:~Jg@MHg@MmzzzzwzzzzzK>;>>;>>>>>>;>>I~~~j&>6:~(wuzzuzzz+<<>+<+zzzzzzzw    //
//    zzzuzzl~~~~~(HgMMMMHMuzzzzzzzzzP>>>;>;;>;>>;>;>S,~~~<2::jQgQHHHmmm->;<1xwzzzzzzz    //
//    zzzzzZ~~:::<~MM#ZMNyzzzzzzzzuzzb&&&&&&&&+<;>>>;+dwIj+gW9YjzzzzzzzWMHwwzzzzzzzzzz    //
//    zzuzw>:_:~~:~(7zzzzHMHmyzzzzzzzwUWr?<zMMMMYWHWaJwMM8+++++wzzzzzzzzzdNzzzzzuzzuzz    //
//    zzzzC:~<~::<<<+zzzzzzzXWHMgHmmmmQQ]~~_WQgQb~~~?MNkzzzwzzzzzzzuzzzzzd#zzuzzzzzzzz    //
//    zzzzz&(<;;>;++zzzzuzzzzzzzzzzzzuXVh__(JTHzwh-~(?<MMNmyzzzzzuzzzuAQHBzzzzzzuzzuzz    //
//    zzuzzzzo-+>+vzzzzzzuzzzzzzuzzzzzzb(`<`._JzL>(-.- JzzXWHMM@HHHHMH9zzzzuzzuzzzzzzz    //
//    zzzzzzzzz+>1zzzzzzzzzuzzuzzzzuzzzdJ....aHmwn<<`.-(Xwzzzzzzzzzzzzzzzzzzzzzzzuzzuz    //
//    zzzuzzzzzzzzzzzzuzzzzzzzzzzzzzzzz%..`.``._m@?<`..`.`(4zzzzzzzzzzzuzzuzzuzzzzzzzz    //
//    zzuzzuzzzzzzzzzzzuzzuzzuzzuzzwwQYT-.`.K!._(~``````.. .Wzuzzuzzuzzzzzzzzzuzzuzzzz    //
//    zzzzzzzuzzuzzuzzzzzzzzzzzzuks>>==vi.``.~~` j:.(KT4o-+?vTXzzzzzzzzzuzzuzzzzzzuzzu    //
//    zzzzzzzzzzzzzzzuzzuzzuzzw7~`.?G?===vn```.` (<``.T1==??>><?yzzuzzuzzzzzzzzuzzzzzz    //
//    zzuzuzzuzzuzzzzzzzzzzzwY_.```` jc????3.`..~(c.J<>>?uy"!`.-?Xzzzzzzzuzzuzzzzzzuzz    //
//    zzzzzzzzzzzuzzuzzuzzzQ^``.<.`.` Jx????;.~(JWdK;>>g@!.`````..Xzzuzzzzzzzumwwmwwwy    //
//    zzzuzzuzzzzzzzzzzzuzuS,..``... ._Nx>>+dW0UwrWZG+dF_``..._~``,XzzuzzuzzzuHkHKWXER    //
//    zzzzzzzuzzuzzuzzzzzzzVCuwXuUUUWHHYYTC>>+OAgW8We?4S-.``.``.`.JKzzzzzzuzzzHXHWMHMR    //
//    zzuzzzzzzzzzzzuzzuzzzkJ+??===?>>>>+jj&XHSzzzzzzWQ&?TXXwXUUSx4SzzzuzzzzzuHWdHWXkR    //
//    zzzuzzuzzuzzzzzzzzzzzzzzUWWHWHHH9S0zzzzzzzuzzzzzzzX9Ggae&&&dSzzzzzzzzzzuWHWWWXWS    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract FUZZGAFF is ERC721Creator {
    constructor() ERC721Creator("FUZZ_GAFFcartoon_3.5", "FUZZGAFF") {}
}
