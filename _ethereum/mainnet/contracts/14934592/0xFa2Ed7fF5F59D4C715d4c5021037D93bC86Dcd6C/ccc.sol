
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I BROUGHT YOU THIS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrxxxxrrrrxxxxxxxrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrB$$%rrr#$$$$$$$rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrrrrrruuuuuuuuuuuuuuu8%%&rrr#$$$B%%%uuuuuuunrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrrrrrr$$$$$$$$$$$$$$$nrrrrrr#$$$crrr$$$$$$$&rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrrrrrrWWWWWWW%$$$$$$$*zzzzzz&$$$MzzzWWW&$$$%zzzxrrrzzzvrrrnzzznrrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrrrrrrrrrrrrrz$$$$$$$$$$$$$$$$$$$$$$rrrn$$$$$$$urrr$$$%rrrz$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrrz**********&$$$$$$$$$$$$$$$$$$$$$$***M$$$$$$$M***$$$@***&$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrr%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrruWWW*zzz$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrc$$$urrr$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrxvvvW888vvv*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrr%$$$rrru$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrr%$$$%%%B$$$$$$$$$$$$$$BuuuW$$$*uuuuuuc$$$8uuuB$$$$$$$$$$$$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrr%$$$$$$$$$$$$$$$$$$$$$%rrr#$$$crrrrrrn$$$&rrr%$$$$$$$$$$$$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrr%$$$$$$$$$$$$$$zxxxxxxxrrrrxxxrrrrrrrrxxxxrrrxxxxxxxv$$$$$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrr8@@@$$$$$$$$$$$crrrrrrrxxxrrrrrrrrrrrrrrrrxxxrrrrrrru$$$$@@@crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrrrrrr$$$$$$$$$$$crrrrrru$$$#rrrrrrrrrrrrrrc$$$urrrrrru$$$Wrrrrrrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrruvvv888%$$$$$$$crrruvv*$$$Wvvvxrrrrrrrvvv#$$$*vvvrrru$$$8vvvxrrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrr%$$$rrru$$$$$$$crrrB$$$$$$$$$$crrrrrrn$$$$$$$$$$$rrru$$$$$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrnzzzMWWWrrru$$$$$$$crrrMWW8$$$%WWWurrrrrrxWWW8$$$8WWWrrru$$$$$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrc$$$urrrrrru$$$$$$$crrrrrru$$$#rrrrrrrrrrrrrrc$$$urrrrrru$$$$$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrruMMMxrrr***M$$$$$$$crrrrrrxMMMvrrrrrrrrrrrrrruMMMxrrrrrru$$$$$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrrrrrr$$$$$$$$$$$crrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrru$$$$$$$crrrrrrrrrrrrrrrrrr    //
//    rrrrrrrrrrr*MMM$$$$$$$$$$$crrrrrrrrrrrrrrrrrrjjjjrrrrrrrrrrrrrru$$$$$$$&MMMMMM*rrrrrrrrrrr    //
//    rrrrrrrrrrr%$$$$$$$$$$$$$$crrrrrrrrrrrrrrrrrrffffrrrrrrrrrrrrrru$$$$$$$$$$$$$$%rrrrrrrrrrr    //
//    rrrrrrrrrrr%$$$$$$$$$$$$$$%&&&&&&#fffc&&&nfff+++?fffn&&&xfff&&&8$$$$$$$$$$$$$$%rrrrrrrrrrr    //
//    rrrrrrrrrrr%$$$$$$$$$$$$$$$$$$$$$%fff*$$$vfffIIIifffv$$$xfff$$$$$$$$$$$$$$$$$$%rrrrrrrrrrr    //
//    rrrrrrrrrrr%$$$$$$$$$$Wjjj&$$$njj\!!!}jjjW@@@///j@@@@$$$@@@@jjju$$$$$$$$$$$$$$$@@@*rrrrrrr    //
//    rrrrrrrrrrr%$$$$$$$$$$MfffW$$$xff(III]fffW$$$fffx$$$$$$$$$$$fffx$$$$$$$$$$$$$$$$$$#rrrrrrr    //
//    rrrrrrrc$$$$$$$$$$%fff}III{fff%$$%fff*$$$$$$$$$$%fffv$$$xfffIII>fffc$$$$$$$$$$$$$$#rrrrrrr    //
//    rrrrrrrc$$$$$$$$$$%jjj1!!!)jjjB$$%jjj*@@@$$$$@@@8///n@@@ujjj!!!~jjjz$$$$$$$$$$$@@@*rrrrrrr    //
//    rrrrrrrc$$$$$$$$$$$$$$MfffW$$$$$$$$$$*fffW$$$fff|III+fff%$$$fffx$$$$$$$$$$$$$$%rrrrrrrrrrr    //
//    rrrruuu*$$$$$$$$$$$$$$WxxxM%%%$$$$%%%u|||*%%%xxxf>>>]xxx%$$$xxxv%%%B$$$$$$$$$$Buuuxrrrrrrr    //
//    rrrn$$$$$$$$$$$$$$$$$$$$$$vfff%$$%fff]III{fff$$$%fffv$$$$$$$$$$%fffc$$$$$$$$$$$$$$#rrrrrrr    //
//    rrrn$$$$$$$$$$$WWW&$$$BWWWt{{{*WWMvvv|+++tvvv$$$BvvvzWWW@$$$WWWz{{{fWWWB$$$$$$$$$$#rrrrrrr    //
//    rrrn$$$$$$$$$$$fffx$$$Mfff+III|ffx$$$*fffW$$$$$$$$$$Wfff%$$$fff(III_fffW$$$$$$$$$$#rrrrrrr    //
//    rrrn$$$$$$$W###[[[)###*zzz(???uzz#$$$&zzz*###$$$@###x[[[v###zzzn???|zzz%$$$$$$$$$$8***nrrr    //
//    rrrn$$$$$$$xfffIII>fffc$$$vfff%$$$$$$$$$$vfff$$$%fff{III(fff$$$%fffc$$$$$$$$$$$$$$$$$$crrr    //
//    WWW&$$$$$$$&WWW{{{|WWW8$$$8WWWccc*$$$&ccc1___ccccWWWu{{{zWWW$$$@WWW#ccc%$$$$$$$$$$$$$$8WWW    //
//    $$$$$$$$$$$$$$$fffx$$$$$$$$$$$xffx$$$*fff+IIIfffx$$$Wfff%$$$$$$$$$$MfffW$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$&&&Wuuu#$$$*uuu-~~?uuu*&&&f)))&&&8$$$@&&&cuuu$$$Buuu|~~~/uuuB$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$%fffc$$$vfffiII>fff*$$$vfff$$$$$$$$$$$xfff$$$%fff}III{fff%$$$$$$$$$$$$$$    //
//    $$$$$$$&xxx%$$$xxxt>>>[xxxM%%%t||f%%%@$$$B%%%xxxv$$$&xxx_>>>xxxv%%%c|||*%%%$$$$$$$$$$$$$$$    //
//    $$$$$$$Wfff%$$$fff(III_fffW$$$xffx$$$$$$$$$$$fffx$$$Wfff>IIIfffx$$$MfffW$$$$$$$$$$$$$$$$$$    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract ccc is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
