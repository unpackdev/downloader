
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Star of Sirius
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    odoollxxdclxldkddxOx;...,:lccc;;:loodk0d,'':oolllool:;,,:c:;,,''lxddo:;:clkOo:cccoolxxl::l    //
//    olcooloodlldlx0dlxOd,..''';cllcllllloodc;,'coloddolc;,:ll;,;,',:::cool:::ldxolc;lxxkdlc::;    //
//    cc:lolollooddkOclOOdc;',,.':cccccooclol:cc;ldooddolc;,;cc;;,,,;:,':ooool:c::::;:dxkOdc:;',    //
//    :::loodl:oxolxOccxdc,'',,',;,,:clddocclclccdxxdolcc:,'..;:;;,,;::cloccooc:;;;;cdO0KOxdl;,;    //
//    ;;;cxOkl,cxdcdOc;,;:'.....,c;'';lxkkkdllc::cooool:;,....;:,';:;colccccc::ccc:cdOOOOOxdc::;    //
//    c:;;lkko;:xxcod;,;;:,.....:l:,',:lddkkxo:;,,clodl::;'.',,,;;,,clc:ccc;:ll:lxkxolloxkkd:clc    //
//    :;;,;odoc:dklll',doc;.....:oc,';lo::oxxxdoc,'.';clc;,:l:,cxkodkxo;;:clodoodkkkdllldkOdllcc    //
//    ::;;:lddl:oxodd;'lolc,...':o:,:oxol;;cloxOkl,..';;;::loc:oxxddol:,;cldxlcddlodolllloxdlllo    //
//    c:;,;:odc:dxxkxc::,:c;'..':c:;lxxodo::coo:;:::;;:;',,;:;cxkdloddccodddl,,:c;:ccccclllooolc    //
//    :;,,',coccoxxOOolc',cl'..,;:,':dkkdocclollloddooolcooc:;:ooloool::lll:;,,,,,;;;cllllccc:;c    //
//    c:;,'',::lodkOOdxd:;::...,;:,'cxxdl:::;;clc:llodxddkkdlllol:;;ll::c:,,;;,;:lllc;:ccll:,'':    //
//    cc:,...;:clcdkdloxdc:;..;:;;;:okkdllol,'lxdl:::cddlc::::clllc:lddlloolcoddoolodoll:,,,;,';    //
//    :;,'..',:;;lxkdooollc,'':c::,;cxOxllool:ldxo:;;::;;:;::::;:lccdkkdooxkxdxxxxkxxxxxolooodod    //
//    ;;:ccccclllxkxdoolll:,',cl:;:l:;:cloo:,,,,;,;;:;,;;,;:lo:;;:::lodl;,collloddolll::codddkOk    //
//    ;;cccc::cccldxl,''cl,..',,';oo:;:oddl:;,;;,:lc:;;;,'',clc:;;;;coooc:::;:llloxxd:',lxxxkOO0    //
//    :;;,'..';;::okx:'.','..'',,:c::llllddc:,,;cc::::ll:,'.',:loc:,,;cdo;,;:clookOxoolcoxxxxoox    //
//    ::c,...,:cccldxc...'';c:;;:oddoldoloolllc::;:llldkxdo;'',llcc:;'':olcdxlllllodxxdodkOOd:,l    //
//    ,'''..,;,;:lllo:'':c;,cllccdkklcodl;:ldxo:,;lddolcc;;;,,;loc;;;'',cloxkkkd::dxdlodxkkdl;';    //
//    ',,,,,;:;;:;,'';;',,';oxdc,,cxolll:',cc:;::;ldxxdol,',,;lxkkl;,,;;::coxko::lc;;codxxdxxl,;    //
//    ;coc;;:c;,'.'';oo;'',cdoclcldxolooc::;,':llcccloodl:;;:;:dkkxxl,;:;,,,:l:,cdl;,,,:oxkOd:,,    //
//    odl;'','...;cccdo:,;c:;cdkxdddxxxoclc:cloxkxl:clllcc::c::ol::ldc;;;,'''',;cdc;,,';loxd:;,,    //
//    ;,.....',',::cll;',loocokxxxddkl;::loooxkkOxlclllc:clldoc::;'':lll:,,,:;''cdo:,;:::;c:,,;:    //
//    ..',,,,:cc:,,;;,''cl:cc:cccoloxl,,:ldkllxkdc:coxxc,:okkOd::c:,,:c:llc,';cc;;llclc::;,,;;:c    //
//    :cllcclool:,,;,,''cl;cc,:lodc:dxlcldxo::oxc,:lcco:,;oxxxl,,::,,cl:;cdo:,,;;;:::::;,,;:lc:;    //
//    olc;,;coo:'.:c,'';lc;lc,;coxocodoolc:;ldooc,,;,':lc:loddc;:::,;c:;,;cool;;::;;,,;,,:cc;'''    //
//    ,,'.';ldl,..co,.;clc;::,;:ldo:coolll::lll:,.',:ccc:;;ccclc;;,;:c:::;::c;',;;;,';lol:;,..,,    //
//    '''',:ldl'..;;...co:,';:cddlc:colcokxo:':c:;,',:lll;,;;,,,,..';:loc:::,,;:;,,,,co:,';c:;cl    //
//    ;;,,,;ldl,.......;l;'';c:;;cool:;cdOkl:;:lol;',,:oo:;;''''''.',',;;,'''',;::cc::;,,,;ll:::    //
//    dl;,;looc:,.'..',;,;,,:c:::odxo''lkOkxolkkl;,',,,;;',,,;:coo;';;;;;,,,''';lllc:cc;;:cccc:;    //
//    cc::cool;;,,,,,;:,',;:l:',;clll'.'ldlc,.,ddcc:cc;'..,'':cclll:;;;;,;;;,,,;;c:,;ccccloollcc    //
//    '',coooc;,,;,,,:l;';codl,..;lolcl:,;:c,..,:,'';dx:.';;,cc,:::::;;;,,,;:::;,,,.',;;:lodxood    //
//    .':dlcloo:'....:o:;loll:...,coolkx,.,ll;'......ldc,;cc::;,:odoc;;;;,.'',;,,:ccc:,;:;cllodx    //
//    ';loc;,,;;,'''':c:cdo;::,',;coc:ll;;odxdc:;''',;,,;:;,;::clolccclc;..,,;;;;coolc:ll::cc::l    //
//    ;:lo:'.....'';:lc:lol:colcl:cdl;:ccoxooo:::,,cl:,;:llc:clddl;''co:,..,,;:::;:c::oddlcokko;    //
//    :,,;'..;:;'.:xkl;:ll::clddl::ldddl:cc;,'';::cll::c:cl::clc,..',:c;;,,c:::::,;:::oxxxdllc,.    //
//    :'.....''..,ldolcllc;:clllcccoxxdc;c;.,;cc;ldol:;,,,,..''...,;'..,::cll;'';;:cdxxdocc;,'..    //
//    l:;'.....':ccollc:::cc::::ll;',,cllddc;;:;,;::;;,,,,'......;:..,::clccc::coddxxoc:;;:lo;..    //
//    ;:c;''''.;l,'cdl:,,;::clol:,',;lddollc;,::,;:c:;,,,;,..',,,,,,cdo:,;:,,ckKXklldo:;:cldo;.,    //
//    '','..''.,c;,cc:;,;clddxdo:,,;cc:;cc,,,';::lllc:,.';:,'',cc:::;::,;:;,,ldddc,'lxlcl::lc,':    //
//    ,,''''''';llc:,,,'':loodooc;,:c;'..,::,..,cdoccc;;:ll::odo:;;,...;llc,',,:cc;;clccc:c:,;;;    //
//    ,'......'loll;'..',;;:cl:,'''coo:,,;:c;'',:oddl;;:c:,cdxxo:'...,cc,....':odoc;:loc;;lc,,;;    //
//    '','....,oxoo:;,;;;;,;ccc:;:c:clolc;;:;:llccloc,,co:;lllc,...,col,....;;coodl:::cccclc',;:    //
//    '','...'codl;:ccc:'...',;:clll:col:;;;:dOxl:;;;,,ldlcc:ccc:cooc;;,,;:c;;cllc:::;;c:;c;';c:    //
//    ',:;,',lkd;'.,cc:,'...,:loddxdololccoolclc:,'...'coc:::cllcll:;..';ll:;cllool:;;cl:;;;,;l:    //
//    '',,,:llc,.',,;:::::;;collcllldkOkkkkdccc:::;,,;lolclc::;:;,;::;,'';;,;loloxdlc:::;;;,,;:'    //
//    ....,:l;...'',:loddxdlc:,'';,';ccldkxdoodlclddxdodool;,:oolllccllc:;;cclccoddxdc,:lccc::;,    //
//    ..,cc:;,''',cl:clooc:;;:::,''...;oxkkdc;cdxkkkxdolol;,:dOkl,,,:ldxl:cllclodoooollddc:::ll:    //
//    .'ll:,,;;:codoc:;;c:;;:c:cl:;:cok0Odc;';x0Okdlc;;;;,',;:c:,,,..,:lllooolclddodloodo::c;co:    //
//    ldl:llccc::;:c:;'.';ccc:,:lloo:lxkxc'';:lkOxddl:;;;,....',;cc::::clloocccoxxdooo::llllll;'    //
//    d:,:llc:;,,,;:lo:,,;:cll:cllddllll:'.,cl::lddolc:;;,...',;;;:cl;;;,',ccclxkxocc;'',cl;co:'    //
//    '..'',::,',,;colcllllllc::loodd:',,,lOKx:,;:;;ccll,.....',;;:lc,;;'',:cooooddc,.,;';c:::'.    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract SoS279 is ERC721Creator {
    constructor() ERC721Creator("Star of Sirius", "SoS279") {}
}
