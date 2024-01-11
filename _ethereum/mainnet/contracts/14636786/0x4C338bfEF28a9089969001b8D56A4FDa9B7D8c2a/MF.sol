
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mind Fuzz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                           //
//                                                                                                                           //
//    .',,,,':c'.....':,;lc'',;',;;,...;,..,:::'',;;,'';;,'.,,......','......';;;'.,::;'..',;,,'...''....'cc;lo'.;o;.;;..    //
//    :xOOkkldOOOOkl,;ldk00OkkOO0KKOdoloook0KXOkOKK0Okk0K0kl;:ll:';ldxo:;cdollooodkOO0Kkl;,:ldkxo;:k0xo;'dXXo:lc;ld:.:l,.    //
//    ckKXNXO0NWWWWKxdkXNWWX0XWNXXNXXXK0O0K0OKXXNWWNXNNXXXX0dx0KOdk00KK0Okl;;:,,oXNK0KXX0c..,oOkc,oOOOx::ldd:,dxldl,.:x:.    //
//    :xKNWWXKXNWNK0KK0XNX0OKXNXXXXKKXXXKXNNKKXXNNK00KXXNWWNNNX0KX0kkOKKKOdoddc,l0XXXXXKx;,;ldo:'';:,,.;dl',:o0dcdl,;ol,.    //
//    lkKXNNWWWWWN00XXOKNNX000XNWXKKXKXWXXNWWNKXX0k0XNXXNNXXNN0kddkO00KXXKK00Ox:';cloddc,;cc:,.',:okd:.:Ox;':kKo;;;';o:..    //
//    oKNNNNNWWNNKOKNXKKNWWXO0XXX0KNWNXNNXXXKKX0d:o0KKXXKkxxxl,',:c:cdkxddxkkkxollc;,',:lc::;,loloxxdc'ckdc,ldddcc:'',,;'    //
//    l0NKKXXXNNNNXKXXXXNNXXKXKK0k0XN0xxdollllcc:;:cc:cc,';cclccc:::;;:lcc::c::lool::;:odl;,;,cc,'cl;,'lx:cxc;ll:::;.,dkc    //
//    cdOKKXK0XWNWWNXXNNNKKNNXOdc;:cc:;;',;:;:coooodl;;ccclc;cllddloxkkddddddc;;:;..,;,;:cc:cc:;;';lc;'lkl::::lc;;::,,cdl    //
//    cokXXXXXWWWX0kxxkOkl:cc;'.....'',,.';;;,'....;,',cdxxolclodxkkdl;....,:cloool:,,,,,..;cllcccokxl,:c'..;c:::;;;coldd    //
//    :odkOXWWNWKkc'';cll:'....';:clodxkkkOOOkkxollc;,....,::::::;'...':ldOKXNNWWWWNOdlcoxkkO00OkkOOd:,;,,cc:'.lxlcdxdxOc    //
//    llccoKNXXXKd'.;;,,,,,;ldkO0KKKK00XNWN0OOOO0XNXXK0Okxollccc:codkOKXXXXXKK000KXNWWNKOOOOOxdxkOkdlcd0Okkdc,cxOOxk0O0Oc    //
//    oocod0XKKXO:....';coxkkkkkkkko:ckXWWKxlllodxkOkO0KXNNWWWNNNXXK00kdddooolcc::oxk0XNNXXKd;,,,;cllldKN0k0K0OXWNK0K0kdd    //
//    dxodxOXKxl;..'cxOOkxkOKXNNNK0OOKK00KXK00KKXXKd,.,cccldxkxddlllcc:;:cldd:....',,:dk00kl......,locdXNXKKXKk0K0dddc;ll    //
//    cooxKX0o;,.'lk0kdk0XWWNXK00O0000O0KXNWWWWWWWXd;;clc:ccclooolcclodxOKNNO;...;ldc,,:ll,.......,llo0XKKKKKK0ko:,:ol;;,    //
//    oxd0KOo,,';dkkocdKXKK00OkxkOO0KXNXXXNNNNNNNNKkdodkxO00OkdoodkOKXWWWWWk,...:0NK0k:,::,'......'cxKWKdllodOKXOoldxooko    //
//    lxKXo;'..;odddddxkOOOOOO0KXNWWXKKOOKNXXXXXXKOl'.dK0k0Oxx0KXWWWWWWWWWXc...cONXl;ol;ldk0Odl,..'o0NNO;'collokKXOl,,cl,    //
//    lxX0:',.,looodxOO00OO0XWWWWWWN0kkk0NNXXKKXXXKo.'kWWkloONWWWWWWWWWWWNx'...dNWWk,..'o0OXWWKc..'oOOK0c..',,',lOXOooddc    //
//    oxOx,...;llodkKK000KKXXXNNNNX0ddk0XNXX0OKXKXXOc,oNXxlxNWWWWWWWWWWWWk'....:KWNo...'o0xoxko;;:ckKX00x'.......:OX0kxo;    //
//    oddo'..';coxkOK00KKXNNXXXXK0kddOKXNXNKxkKXXNWNX0OK0OOx0XNWWWWWWWWNO:....,dKOc....:x0o...,cocckK0dko.........lKKOkdl    //
//    ldkk,.';codoollloddx0XNXXKOddx0XXXXNXkdOXNWWWNKKNWXXXX0kkkkOOOKX0l....'dX0l....'cdkx;...,ok:'cookOc...';cl:.;OXdcll    //
//    ldOO;.',;,,'.,c:..,:coxkxdxxOKXXKXWN0dxKXNNNXOkKNNXO0WWN0OOOOOOkdlcc::lxOxlcclok0Ol,....'oOd''lONKc'.,:ldkOocOKl.',    //
//    cdOOc.;;';,,,dXx'....',clcoxO00KKXNKxdO00XNX0kONWNOx0NWNK0OOXWXKKKOOKXK000OOKXNNKo,......:kOodKNNO:.':okOOKKKKk;.,,    //
//    lxO0koc;'';lcxXd,..',;,',,;coooxO00OkOOOKNWXOkXWNKkkKNWNK0kdOXK0K0kkXWNKOkxKNWX0kdlc;,'',:d0XNWW0c..';lxO00XNXo':xc    //
//    cdO0kd;,::;,'lOolc:xxko;,...'',,;::loxk0K00kxOXXKOxOXNNKOkdldO0K0OkKWWNKOKXNWWNX0kkkxxdxkOKKXWX00x,.,:okOkOXNO:cxkl    //
//    xddOkolox0koooocc::dxxllo:;;,',,..','',::ccccdxddddxOOkdolc::cxOOxOKKK0OOkO0O0KXXXKK0kxdOKxo0WKokNx;:xOOkkOXKllkodo    //
//    lx0K000xdxlccc:;,,oko:dOxllxx;:o,.:c,,'..','',;;;;;;::;,'.'...':lclolc:::,;::;cldOKNWNK0XO;;x000XNd:ld:lxkKKdlxodKd    //
//    ;kKKKkdodl:'.'.',';l:,coclodo;oOd:dd,coc:;'',,'':c'';:,.........................';lx0XWWWKdoxkO00d:c:'.cOKXx;odcONx    //
//    :dOXXO:',:,,,..;:,';:loldkxc;ckKOcoooo::o:.,;:,:o;.;xl:;...........................':okKNX0kdlcc;,co;.'dKXO::dc:d0x    //
//    cd0KKXd;:c,,;..';::lolocccc::lodxl,':cclc,,ll:,,ldlod:':c;;'..................,,;;....,cdkOkddoc;;cdo;l0Xk:,lo;,oOl    //
//    ldk0kl,..'co;...;looc;::cclloolccc:;,',,,',;;;:dO0koooccc:cc:,...............;:'';,.....'';cx0XX0OO0KK00x;.;oocx0O;    //
//    :okX0o,.,dKXo..:loo:,loldkkxddoollllccc:cc;,,,;oOOc.,l;.'';;;:,...'....,;;:lo;....','.',::,.:xKNXXKOOkxl,.';ooxNXd'    //
//    oxONNXk,'cdd;.'.,ccc:;,cOKWWWWWNXKKx:looloc,'';d0K0kdccoc,'...';'.'....',;;lo'..........';c,,oOOOkdc::;'..;;:lkN0c.    //
//    cdx0XKd,.;:;.':':oc::';kKXWWWWWWNXKkolccddc:codolxkxc,,:c;,''',::'.........:d;............:::ddll:,'.....';,;lx0xl;    //
//    lxodOKk;.;oc..,:dOocldOKXNWNXK00OOxl::okOdlcxKOl'.;c;;;;,,,.',;:;..........,d:...........;loxd:'........'':c:lxxodo    //
//    :od0XK0c'oKd''lkKXkx0KKKKK0kl::clc:cdOO0XKo;cdoc;..'',,'....................cc..........clcdo,........'',cxc,dklcdl    //
//    :d0NNX0koc:;..l0KOdlxOkdlclollodxxOKXXddOdc;;;',;,..........................:xkkkxdl;'.,d:,c'........',,clc;,olclc'    //
//    ,ld0NXdcdd:,':dOxc;:lc:;::;,:xKNOldKXKkll:ll;,;::,......................;dk0XNWNXKXNXOdloc'....'''..:xOxkxo;,:;:kx'    //
//    :dodKXkc,cdl;:llc;;:,;dOKKx:dKNKxll::cc;;;;,,;,'......................:OXNNXXXNKK00KK00K0xoc,..','..oOOO0KKl';oOXd.    //
//    l0Kxk00k:.''',cxdc:lkkolO0d:clolodc;loc;'...............,:'...,,.....c0NNXXXXXXXKKKKKKKKKXNWO;,oOx,.'c::odo;:kXNKo'    //
//    lk0dcolxx;'';:lkdlcoko:;;:od::cllc:cl,............':;...,l:...,::lodk0KKKKKXXXXK0OOOkkOO0KXXXOdllc..':;,;;:;oXNXd,.    //
//    lxOxodc:c;cxxlcooolcc,;:':dl;::;,;:cxd;;c'...,;.,ododlcc;;;;cdk0KXXKK00O0KKKK0kkkxxxdooddxdodc'....cdl,':coxKNXOdl'    //
//    lxolx0o;,,:oxdloooc;;;cl:lo;'....lo;cdllx:;c;cxc:olcol,lxxkOKNWNKO00OOOkkxxxddolodooolcccc;,'...':oo:';odooxxdoloc'    //
//    ;oxxdkxol;,ldlddddlllc:;;c;',,'';do,'',dOclkxoo:.,coollx00KXXNNWNOkkxxdlcccc::c:coocc;,'''...':lc:;cox0NKoccc;;ol;.    //
//    ;dx0X0OdccxKK0kddxkOkdoloc,,:odlc:;',;;co:;lddl:;cdkO0K0kddloddxkO00Oxl,'',,,,;,,;;,'......,ldl;,:dXWXkdl:d0kddkxc'    //
//    ,kKOO00dc:lk0XK0kx0NKOkxxxolodxkdlccldoc::cdkkkxkk0KXXXNXXK000OkkkO00Okdl;'...........,:'.lko,.c0NX0kddO0xxxdkkkOl.    //
//    'd00KNKdol;;ldxkO0KK0kkooxdxxdxOxxkxdxkkkkxxk0KKNX000KKXXKKKKK0OOxxxxlccll;.........'lkl'cOo:dOKNN0oodxOxdkkdol:l:.    //
//    :k0XNXXkolc,,,;:cldxk00Okxllc;cl;;lc:ddcodo:l0XWWXXNNXXXXNX00Okxddlcc;,'.....,::'.'';locck0dOWWNOo:lkdokkdol::lodo.    //
//    lOOXWXOo:;:::'',,'';:ldxOK0OOkkkxxdolllcoxxk0XNWWWWWX00KKK0kkkdolc;,''.....cxO0kdxO0kccook00XNKk:,;cooddc;:d0KKOko'    //
//    cxkXN0xl::,'od:oo:,'.',:codxkkkOOOkkxdxxxxkOO0KKXNNWKOkdddooccc:;,.......;x00OKKOkk0kdxxxkOO0Oo::;;lxd:;lOKXXXNOko.    //
//    'oO0X0kl,,''dOdkocc;,,'..',:ldoclcccc:cc:cllodxkxk0Okdlc;;;;,''...'',,',oO0kxkkxxOKXOodk0NKkdlc:;cxk:,;cokKNWN0kOl.    //
//    'oO00K0Oxd:lOdldoclccll:,..',,'''''''',''',;;,,;:;:::;''.........,clooldOOkxxxxOKXXOxkXNNWXxokOooko'.;ol,,dKNWOkk;.    //
//    'd0X0OXX0doxdldxkdoxxkxolclooc,;::;;,'....''''.............,;,;oodkxkxxdldxxxokKX0kod0NWWNKxdkxkx:'';',cl:o0NKO00l.    //
//    'lOK0OKOolddxO00Oxdk0K0koccooclcoxkxddoolcllccccc;',;;codddlcccxdd00Oxxxloxdocd0OodKNNWWN0xddxOx:lxo:,:odokXKO00d:.    //
//    'lkOOkocoxOO0000Okxk0000Oxl:coxoldkkxOkxkxxkxxxdlclllldxxkxlokOOl,dOOOkxodkdllddodxO0NWNKOkkkOd:oKNNKkkO0XX00XXkc'.    //
//    .ckxlclxkOOOOOO0OkkO00OOOOkdlldxolddddlcoodkxxxocllcoolxxoc:okkxccxXKkOkdkOdolldOxllokXKxdkkOo;dKXKXNNNNKK000kxl::'    //
//    'odclx00000OOOO0kxdx000OOOOOkdodooxdddc:lddllooooccdo:ldc;,;oxdlccdOkO00O0Odxo;od:oxoxXKdodkd,lKXXK0OOO0OOXKocccdl.    //
//    .,;coddddooollcc:;,,:::;;;;;;,,'',,;:c:;:c:::ccllcl:,,:,'',;,,,,',clloxdxxddxc'',:oo:lddOxod:,okkkkxkOX0oll:;:clo:.    //
//    ........................................................................''.,,..........;oc'.'',;::::;coc'..........    //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MF is ERC721Creator {
    constructor() ERC721Creator("Mind Fuzz", "MF") {}
}
