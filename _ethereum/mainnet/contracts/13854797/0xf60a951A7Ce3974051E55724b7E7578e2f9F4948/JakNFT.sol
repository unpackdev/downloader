
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JakNFT - Manifold ERC721
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    llodoc;:cllllclolc::ccc:;:clccclc:::::,''',,:;,:,',,'..:;',;;,,;;:cccclc::cccllllcc:;cccllcclc::ccco    //
//    lccllc::::clllcccccc::::ccllc::;;;,,,,''.'',,,,,,,,'',''',;,'''''',;;;;::::cclcccclc:clcccc::ccccl:c    //
//    ccclc::cccc::::ccccccccccc:;,,;;;;,''''''',,,,,,,,''',,,,,,'',,,''',,'',;:::loolcllcccccccc:::cccccc    //
//    ccll:ccccccc::ccclooolccc;,,',,;:;,,;;;;;:cccccc:cccc;;;;;,,,,,,,,,,,',',cloddxdoc:cccc::ccc:ccccc:;    //
//    cllc:llcc::::cc:cdkkdoxkd:,;,,',;;::;:;:lddxOO0OkkxkkOOOkolc::cc:;;,,,;,:dOkkkOOxolc::ccccc::cc::c::    //
//    cccc:lolccccccldxdxkkOKkddoc;;;;;',,',,;;;;::clc:::::clcc::;;;,,,,,',,;;:lodxkkxdxkoc:ccc:ccccc:cc:c    //
//    ::cc:cc:cccclxx:,;d0XN0ooxkOoc:;;;,,,,;,,',,,,;,,,,,,,,;,',,,,'','',::od:,,lOXxlodkkl::clcclccc:c::c    //
//    ccclccc:cc::o0d...:ldkxxO0O0klcccll:;,;;,,coolc;'',,,'.,:cllc:'...'cdol:,..,coddoxkkdc:cccllccc:clcc    //
//    ccccccc:c::cx0k;';;;,;:ldxkOo:clxdc;,,;,,;lOKOd;..''...'xOkxl:'...;ddoc,'....;okkkk00o::clocclc:cccc    //
//    ccc:c::ccc:cx0Kl,,,,,;,,,,:cccokdc:;,,'..'',coc;'......'okdl,'....c0x:..,,...'lxxkOOkdc:ccc::::clc::    //
//    lc::ccccclldOOXx,,;,,;;;;'',;:oko;'',,,'...''':c:,'',,;,,,'.......:dl'.........;xkdoddc:cccccc:ccclc    //
//    clccccll:clood00c,;,;:;,,,,,,,,,;:;;:,,,;;,,,,;:;;;,'''..'.......'cl'..........,oxxxxocccc:ccc::clcc    //
//    cccllllllcodlcokl,,,;:,',,,;;,,;;:;',,,,,;,,;;;;,,,,'...........';cc'..........:oxkddlcc::cccc::cccc    //
//    cclollooccllccldxo:,,;;,,'.',',,;;,,,,''...';:;;;;;;;;,...'......,coc..........;lxxkkolcc:cclcccclll    //
//    lcllloolccccccodO0d:,',,,''''''';;,,;;,;'.....,,;;;;::;,..'..'..'.:dd:,'.......':dxkkdlcclc:clclolcc    //
//    ccccccccclcccoodO0KOddxkxolc,:c:ldoolcclloolllccoddddxxkdoddddoolldOOdooool::ccclOWWNKOxlllcccclolll    //
//    llclcccodddxdkK0KWWWWWWWNXKKkdkOXXK0OO00XNK0KK0000KK0OKNNWNNNNNWNXXNXXXWNKOO000KOk0XNK0Oxxolcccllolc    //
//    llclllldOxOX00NNNWWWMWNXNNKNWXKXXK00KKK0XX0KKOkkOOOOxoxOKNNXXNWWWXXK0XNNWXKXXKOkkkk0K0K0Okxdlcllllcc    //
//    oooooddkKXK00KKKKXNXXWX0NKkXXkxkxxxdkddkxoll:;;;,;;;;,,;lkkkkxxO00OkOK00XX00KNXKKKKKK0KXK0kxooooolcc    //
//    ooooodOXNWNK0kO0O0KOkKXXXNKOxlxKkddooooo:;,'',,',,'',,',;cccldxxoccccccoxO0OXNNNXNNK0KKXXKkxdoloolcc    //
//    xoxkddxKWMWNXKKKXXKO0XNXKX0kk0NNOloddkOdlc:,,''',,''''',,;okdodc:ll;;:;;:dO0KXKNNNXXKXXXN0xxxdolcccc    //
//    xoooooxKWMMMMWWWWNX0KXXXXWNOKWKxdloxO0kdolc;,'..,,'''',,.;ONKxxxdxdoodxddOKXXKKKXNNNXNXKKkdkOoloc:cc    //
//    olccodkXWWWWWWWNNNXKKNWMWW0dONkodxkOXKxlll:,,;,,,,',,,,,':xOkodolllddOKXNNXXNNXXNKKXKKKXX0kxd:;llclc    //
//    ccccllkXNNWWWWWWWWNNNWWWNXkddxxkxO0xdddoc:ccc;,',,,,;cc;''';lxkxkkOOkOO0XNK0KXKXXOKXKXK0Okxddl:loccc    //
//    lcclldKWWWWNWWWWNNWWXXNNXkodOXNN0k0klolcokK0Oxl:;;,,l0Xkol;,lkOk0NNWNXKKXNNXXNNXXKXXK0OO0OO00xlcllc;    //
//    ccclldKWWNNNNNWNXNNXXKKX0xxONMMMWNNX0xdONWWWNX0Ooc:coKMWNN0dlx0KXMMMWWWNNNXXKKXXXXXK0NK0XK0Okdl:coll    //
//    lc:ood0WWNWWNNWNWWWNXKXXKkONMWWWWWWWWNNWWWWWWNXOdlld0NWWWWWNOxKWMMMMMMMMWNNNWNNNNNXXNWNNN0OOkoccccll    //
//    cccldxOXNNWWWWWWWMWNKKXXXOdONWWWWMMMWMMWWWWWNXkl;;:cd0WWWWWWWWWMMMMMMMNNNXXNWNWWNNXXNNXKkxkOdlclooll    //
//    ccclox0KXNWWWWWWMWNXK0XKKKxdONWMMMMMMMMMMWWKxdl;;,,,,lONWWWWMMMMMMMMWXkkKNXXNWNNNNXNNNN0xkOxlcllllll    //
//    cccldk000XWWWWWWWNNNNXNKO0xok0NMMMMMMMMMMWKo;::;;,,;;,,oKWMMMMMMMMMNOolxXX0OKNNNXXKKKXNXK0kdllllllcl    //
//    lccoxkxx0NMWNXKKXNWWNNNKOOxox0NMMMMMMMMMWXd;,,,,,;;;,,;dXMMMMMMMMMWO:lx0X0KKKXNNXXKKKKNKOkxllddlolll    //
//    cclodk00OKNNWX000XWNXXXXXNOkKNWWMMMMMMMMWNKx:,,,,;;,;l0WMMMMMMMMMWMXkkOKNKXXNNNNXXKKXNXOxxdclolodlcc    //
//    oolllkK000KKKKK0XNWXNNX0OKNWMMWWWWMMMMMMMWX0d;'',;:ckNMMMMMMMMMMWWWWN00NWNNXKXXXXXNK0KKkdolllcccllcl    //
//    ooolcoxk0KXKKXKKXNNXXK0KNWMMMMMWWXKXWMMMMMWXx:,,,lkKWMMMMMMMWWWWWWNXNWNNXKKXNWWNNNNN00XOk0xllcccclll    //
//    lllc:lk0O0KKKKKXXK0KKOOXWMMMMMMWKdlo0WMWNK0kl;;:cOWWMMMMMMMWKdxKNNNXXNNNXKKKNWWWWWXKKXXKXMKocccccccl    //
//    llcc:cx0O0000KKXNNXXOdllxxkKN0kxc::;ckKKOdlc:;,,:dkk0WMMMNOol::o0XXKOdxKKKKKXWWWWWWXXNKOOOxc:clllccc    //
//    lccclodO0KK0KXKKXXX0xdoc::cldoc::::;;:clc:;;,;;,;;::dXXKXO:;:;;;cxko::d0XNNXXNNXKXNNXXKxoolc:cclc::c    //
//    ccllloldOKK0XNKK00K0dolccccllc::c:::::::;,;;;::;;::::llclc::;;,;;::;;:x0KXXXXXXWNKNNK00kollc:ccccccc    //
//    llclllco0XXXKK0KXO00xloodoc:;::ccc:::;:::;;;;;;,;:c:;::;:;::,;;;,;;;;cxKNXKXXXKKKNWNNWNXX0dcllllcccc    //
//    lc::c::oOKK00KXXXXXOocloooc:;:ccc::::;;;;;::;;;;::::::;;;;::;;;;;;;,;cxKXXXNNWXXNNK0XXKOOOololllc:ll    //
//    ccccc::oOXXXNXXXXXXOo::ccc:;::;:;;;:::c:;,;::;;:::;::;;;;:;;;;;::;;;;lxOXXKXNNNXNNNKKXKOdololclc:clo    //
//    ccc::ccoOXXKXNXKKKKOoclcc:;;:c::;:cc:ccc:;;::;;;::::;;;::::;;;:;;,,;:ldk0XNNNNNXXNNNNNXKOdcclc::cccl    //
//    oollccldOKXXXNXKKXKxlc:;;;;;cc::ccc::c:;;:::cc;;::cc;;;::;;:::;;;,,;;clxKKKXNNNNNXXNXKKKkollol::llld    //
//    cccllccx0XXXXXXXXKKxc;,,;;;;;;::::c:::::;:::c:;::,,;;;;;;;;:;,;,,;:::ccxK0xOXXNNNXXXKKKKOkdolc::clod    //
//    cccllllxKNNNNNNNNXXkc;;;;::;;;:::cc::;;::::;:c:;;;,,;::;;;;:;;;;;:cccloxOOOkkOXNNNNNXKKK0Odl::clllll    //
//    lcllolld0XWNWWNNWNNOc;;;;;;:::::::::;;,;::;;:::;;:;;:c;,,;;;;;;:::coo::dxlolodONNWWWNXXX0xdllcllcool    //
//    olclodxOKXNWWWWWWNKd:;;;;;::::::::;;;;;;;;;;::;::;;;;,;;;::;;;:::cdOx;';c,;:;:cdOXWWNXNN0dddooolclol    //
//    lllxxxkOXWNNWWWWNXOl:;;;;;,;;::c:;;;;;;;:cc::::;;;:::;:::;;;;;;;::lxo;,,:,;c;;:ok0XNNNNX0OkOOOOOkxdl    //
//    dxdooxkOXWWWWNNNN0xlc:::c:,;:c:::::cc;:;;cc::::okl,;:c::c:::ll::::oo,';;cl:cdo::dxk0XNNKkkkxookOO00O    //
//    kxloxxdxKNNWNNNNKkdoccldxd:::cl::cclc;;:cdo::::dko:;;:cl:;;coc,::;oc,:::lc;cOk::dkONNXK000OxollllldO    //
//    xxddxdld0XXNWWWNOxkkdddddoloddxocllddcclclkkocodc:cc::c:clodxolc:oxlldkxxddx0XkxO0XWNKKK00Okdolcccox    //
//    dxxxdkOOXNXXNNNNKxdx0XXKOdkKXOdddk0XK0KK0KXNXKXXKOkxdxxxxxOO0K0KXNNK0OXKKKKKXNKxooKWXKXK0Oxddllllddl    //
//    lldkKKKKKNNNNNKK0xx0NWNKkxOK0dccd0WMNWWWWW0k0XNNNWNX00XKkO0xkK0KKx0WXOKWNXO0XWNO:lXWXOKNK0kdl:cclddo    //
//    dkxxO0K00KNNNNNXXNNWNXKOkO0OdolxOkOXWNNWWWKkkkOXNNNXOkKXXNXxd0NXKxkXNNWXKXNWWWW0xOXKOOXNKOkdc:cccclo    //
//    olodOXKXXKXWWWWNWXXWWNk;,dNKd:;d0KKXNWWKooKKxxxdxO0Oxc,:kKK0d:ck0xxxxxdlllooc;,....'xNNN0kkxllllcccl    //
//    odxkkO0NWNXNWWWWWKXWM0'  :XKc. .kWNNNW0,  oXo'. ,OXO,   cKXk'  cl.                  cXWWX0KKxddolcc:    //
//    coxOkkOKXXXNXXNXKKXWNo  .dN0;   lNNNN0,  .;;   .:xOc    cKXd. .l,   .','        ':ccd0NXKKXKOkkxo::c    //
//    dkOO000K0KNNKKKKKKXNO.  ;KNl    :NWWXc       .,okl,.    .k0;  ;l.  cXXXNOoxd.  ;KXK00O00kOK0xddlc:ll    //
//    OO000XXKKXXNK0KXXXNK:  .kXd.    'k00l.     .lxxkx'   ..  ld. .l;   ;o0MWWNXl  .kMWWWXOOKO0XXOkdlcllo    //
//    K0000XNXXXXN0kOOKWWd   lXd.  ..  ..        ,OkxOl   .dl. ..  :l.     'OWNNx.  lNMWWNWXKKKXNX0kO0Okxk    //
//    NNK00XNNNXKXo..:KWk.  ;Kk.        .    ,;. .o00k'   c0k;    .c'   .,cdKWW0,  ;KWWNXNXX00XKXX0kOXNKKO    //
//    MMWXXNNNNXXK;  cXk'  .kk'   ...  .,.  :kd.  ,xk;   'dkOo.   ;,  .oKNWWWWNc  .xWWNXKK0KNWWNN0kO0KKOOK    //
//    MMMMMWNNNXX0,  oO'  .kO'  'd0XO'    .ckOO;  ;Kk. .;dKXX0;  'c.  cNWWWWWWk.  lNWWWWNXNWWMWWWN0KX0OOO0    //
//    MMMMMWWWNXNK,  ..  'OWd  '0WWMNc   .oKXNNd. ;Ko  :OKNWW0,  c:  ,0WWWWWMNc  ,0MWMMWWWWWMMMMWWWWN0kkO0    //
//    MMMMMMMMMWWNd.   .cKMMNdc0WWWWM0; .dWNWMWXo'lXOc;xNNWWWXd,:l. .xWWWWWWWXc .dWMWMWWWWWWWMMWWWWWNOxkOk    //
//    MMMMMMMMMWMMW0xdkKWMMMMMMMMMMWWWNOkXWWWWWWWNWWWWNNWWWWWWWWNKxokNMMWWMWWWXxdXMWMWWWWWWWWWMMMMMMWKkxxk    //
//    MMMMMMMMMWMMMMMWWWMMMMMMMMMMMMWWWWMWWMMWWMWWWMMWNWMWWWMMWWWWWWWWWMWMMMWWMMMMMWMMMMMMMMMMMMMMMMMXxdxx    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JakNFT is ERC721Creator {
    constructor() ERC721Creator("JakNFT - Manifold ERC721", "JakNFT") {}
}
