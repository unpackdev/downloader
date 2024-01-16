
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPEPAINBANE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ;ddlxooxcdxldolkOkOkolkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOxldOkkkkkkkkkkkOolkOkOolkOkOklodlol:oloOxlcllllokloooololdloOdld    //
//    ;ddlxooxcdxldolkOkOkolkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOxldOkkkkkkkkkkkOolkOkOolkOkOklodlol:oloOxlcllllokloooololdloOdld    //
//    ;ddlxooxldxldolkOkOkolkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOdcdOkkkkkkkkOOOOolkOkOolkOkOklodlol:oloOxlcllllokloooololdloOdld    //
//    ;ddlxooxldxldolkOkOkolkOkkkkkkkkkkkkkkkkkkkkOOkkxxxxdoll;.',,,''',,;;;;:,,cloxllkOkOklodlol:oloOxlcllllokloooololdloOdld    //
//    ;ddlxooxcdxldolkOkOkolkOkkkkkkkkkkkkkkkkkkkxl:;'..''...........................':okOklodlol:oloOxlcllllokloooololdloOdld    //
//    ;ddlxooxcdxldolkOkkkolkOkkkkkkkkkkkOOOOOkd:'......................................,lxlodlol:oloOxlcllllokloooololdloOdld    //
//    ;ddlxooxcdxldolkOkkOolkOkkkOkkkkOkdollcc;.......'......................',,;;;;;,,,'.,,:llol:oloOxlcllllokloooololdloOdld    //
//    ;ddlxooxcdxldolkOkOOolkOkkkkkOkdlc::clll'.'::'.'.......,:,..........,:cooooooooooooolcc;;:c:oloOxlcllllokloooololdloOdld    //
//    ;ddlxooxcdxldolkOkOkolkOkkkkkdc:cloooool'.'cc'',......;ll;.......';looooooooooooooooooool;,,lloOxlcllllokloooololdloOdld    //
//    ;ddlxooxcdxldolkOkOkolkOkkOkl;cooooooooc...;;.;;.....:c;,......':oooooooooooooooooooooooool;;:oOxlcllllokloooololdloOdld    //
//    ;ddlxooxldxldolkOkOkolkOkkOo;coooooooodc..':'.::,'..;c;.......;cc::::::::cccloooooooooooooooc,lOxlcllllokloooololdloOdld    //
//    ;ddlxooxldxldolkOkOkolkOkOx:;oooooooooo:..''..cll:..;,......',::::ccccc::::::::::loooooooooooc;dxlcllllokloooololdloOdld    //
//    ;ddlxooxldxldolkOkOkolkOkOd;cdooooooood:......:oc'........;clloooooooooooooooolc:;;:looooooooo;:dlcllllokloooololdloOdld    //
//    ;ddlxooxcdxldolkOkOkolkOkOl;ldooollcc::'......,c'.......,looooooooooooooooooooooool:loooooooool;:lcllllokloooololdloOdld    //
//    ;ddlxooxcdxldolkOkOkolkOOkc,:::::::::cc,...............,oooooooooooooooooooooooooooooooooooooool,;cllllokloooololdloOdld    //
//    ;ddlxooxcdxldolkOkOklcolcc:::cllooooooo;.','....''.....loooooooolllllooooooooooooooooooooooooooo;,cllllokloooololdloxocd    //
//    ;ddlxooxcdxldolkOkOkc';:lodddoooooooooo;.,;,....',;,..;olc::::;;;;;;:::::::cloooooooooooooooooodc;:llllokloooololdl,'..:    //
//    ;ddlxooxcdxldolkOkkl;:c:::::::::clloood:.,:,...',';'..;:;,',,;;::::::::;,,,;::::::ccclooooooooooo:'clllokloooololdc.....    //
//    ;ddlxooxcdxldolkOkl',::::::::;;;;;;:::c,.';,...,;'...'::;,,:ccloooolcc::::::::::ccc::coooooooooooo:;:llokloooololdl;..'.    //
//    ;ddlxooxldxldolkkc;;:::::;;,,,,,,,,,,,'..............,,:ldkkxOXNNNNXKOddddoc;;::::::::ccooooooooooo:'clokloooololdl;....    //
//    ;ddlxooxcdxldolko',::;:coooxOO00Okoool:'..',:,.',,,.,lx00KXK0KKKNWMWNKXWMMNOdlcloolc:;',looooooooooo;:lokloooololdl'....    //
//    ;ddlxooxcdxldold;,ccldkKK0KNMMMNK0XWMWXO:,lll:';ol:,x00XXKX00OddONWN0KWWWWNXWWx;;:::::coooooooooooooc;:okloooolold:.....    //
//    ;ddlxooxcdxldolxl,cokXNNKKXWMMNKXKKNMMMMk,:ol;.:oo,:KWNNOl'..'...,cONWMWK0KXX0ocllclooooooooooooooool;,okloooolold; ....    //
//    ;ddlxooxcdxldolxldNXx:,',;,:dKWMMX0XWNKXXl';c'.':;.lNMXl.  ......  .lXMMX0kdl:,:dxooooooooooooooooooo,.cxcccoolold;.....    //
//    ;ddlxooxcdxldoldckXc  ...'.  .dNMMMMWKKXNO'........,xNx. .d00c       :xdol:;;;:oOkooooooooooooooooooc...':l:;::lld;.....    //
//    ;ddlxooxcdxldolkl;,  .kKc ..   lNWNWWWMMK:...........;'  .;lc' ..''';::::::;:lox0kdoooooooooooooooo:......cdddolcl,.....    //
//    ;ddlxooxcdxldolkx;''..;:.      cNN0000ko,......  .,........  ..cddoc:::::cloooodOOdooooooooooooooc,.......'dOkOkkxc,;'..    //
//    ;ddlxooxcdxldolkOxo:,cc:;,'.'.'cdl:,....... .....'c,. ............,ldxxdooooooooxOxooooooooooooc,..........lOkkkOkoOO:..    //
//    ;ddlxooxcdxldolkOkOxc;:lododkOdc'.................c:.... ..  .......;okOkxdooooookkdooooooool:'............cOOkkOxdX0:.;    //
//    ;ddlxooxcdxldolkOkkkkxoc::coO0x;.... .......................  .'.. ...;oxkOkxooooddooooooc;,...............:kOkkOdxN0;.l    //
//    ;ddlxooxcdxldolkOkkkkkOOd;':ol;.......'....,;. ...........'... ....  ..'lodkOxooooooolc;'..................;kOkkOdkXd.,d    //
//    ;ddlxooxcdxldolkOkkkkkOx::dOc........',....,l, .......,c,...............,oodOkdlc:;,'.....',:'.............,xOkkOdkk;.ld    //
//    ;ddlxooxcdxlddlkOOOOOOx::x0d.........';.....;,........:l....... .....'...;:;;;'......',;:cooo;.............,xOkkOdl;';dc    //
//    ;xdlxooxcod:lllddddddxc;oO0c....... ....  ............',.... .......,,... ......',;:loooooooo:.............,xOkkOd,.,ll,    //
//    ;do:lccoclolllloc:clll,:dOOc....,'............. ........''..........,,.......',,,,,,,;:loooool.............,xOkkOo'.cl;'    //
//    'llcllododddddddo:oxxl,cxOk;....,'.....,c,..',. ......';,;;,,........'.....,;;;;;;;;;;''cooool.............;kOkkOo,:d:';    //
//    ,ldodddxxkkOOOOOxldOOd;:dxl.....,'.'...;'.,c::'.......,:;;,';'... .........;;;;;;;;;;;;,':oool.............cOOOOOdoOo,,o    //
//    cxOOOkkkkkkkkkkOxldOkl,,,,.........,,..''..';;;lo:,...'::'.................,;;;;;;,',;;;''lool.............,coddolxd,,cK    //
//    cxOkkkkkkkkkkkkOxcdk:',;;..........':;''''. .:'',';'....,'...,;.............'''''''',;;;,'cooc............,:,lkkxlc;':0M    //
//    cdOkkkkkkkkkkkkOxcdo',;;,........'ldc'..... ................ .l:...........'',,;;;;;;;;,',looc............ld:;dOx:'':0MW    //
//    cxOkkkkkkkkkkkkOxldk:',;.',.  . .cc'........ .:c.. .cc........;:....';'..,;;;,,,,,,,'',,:lool'...........:ool;lOx:';kMMK    //
//    cxOkkkkkkkkkkkkOxldOko;...'...  ';.....';..  .cc....,c,.............l:...,,,;;;;;;:::cllc:;'............,oooo;:kkd:lOXKl    //
//    cxOkkkkkkkkkkkkOxldOkOl...',....;'.....,,... .',......'.....   ....'c'.':cllllcc::;;,''................;loooo;:kOkkxddl,    //
//    cxOkkkkkkkkkkkkOxldOkOo',;,'.'..;'.....,'.... ...............  ....';....''.......................',;cloooooo;:kOkkkOOkd    //
//    cxOkkkkkkkkkkkkOxldOkOkd:,,'....''.....',.... .'............   .....'.........................,;clooooooooool;lOkkkkkkkk    //
//    cxOkkkkkkkkkkkkOxldOkkkOkxolc.  ........'...  .................,,.. ......................';cloooooooooooooo:;xOkkkkkkkk    //
//    cxOkkkkkkkkkkkkOxldOkkkOkkkOOl.. ............   ....... .''.  .''......................';coooooooooooooooool;lOkkkkkkkkk    //
//    cxOkkkkkkkkkkkkOxldOkkOkkkkOkc''....... ..........'''..  ..............;'...........':loooooooooooooooooooo;:xOkkkkkkkkk    //
//    :dOkkkkkkkkkkkkOxldOkkkkkkOd:;cl' .'.... .''..........................,o:.........,cooooooooooooooooooooooc;oOkkkkkkkkkk    //
//    :dOkOkkkkkkkkkkOxldOkkkkkkOo,:o;. ...,,...............................:oc.....';cooooooooooooooooooooooool;lkOkkkkkkkkkk    //
//    cxOkkkkkkkkkkkkOxldOOOOkkkkko;:c'.. ..................................;ol,.;clooooooooooooooooooooooooool;ckOkkkkkkkkkkk    //
//    cxOkkkkkkkkkkkkOxlldoddddxxkko,:c'. ..................................:ll;,loooooooooooooooooooooooooool;ckOkkkkkkkkkkkk    //
//    cxOkkkkkkkkkkkkOkkxxdddddddddoc,:l:'............................',;,',:;:;coooooooooooooooooooooooooooc;lkOkkkkkkkkkkkkk    //
//    cxOkkkkkkkkkkkkkkkkkkkOOOOOOOkkx:;lo;.',,,,,,'''......'',;;:cclloooocccloooooooooooooooooooooooooool:;:oxxxxkkkkkOOOOOOO    //
//    cxOkkkkkkkkkkkkkkkkkkkkOkkkOkkkOkl,;;:odoooooooolllllloooooooooooooooooooooooooooooooooooooooooool:;',coddddoodddddooddd    //
//    cxOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkl,:oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooollolc:cloxOOOOOkkkxxxxx    //
//    cxOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOko;;:loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooc::cldxkOOkkkkkk    //
//    cxOkkkkkkkkkkkkkkkkkkkkkkkkkkOkdlc:ldoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooolc:cclldxkOOO    //
//    cxOkkkkkkkkkkkkkkkkkkkkkkkOkxlc:cloooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooocc:ccclo    //
//    cxOkkkkkkkkkkkkkkkkkOkkOkdlc::loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooolc:    //
//    cxOkkkkkkkkkkkkkkkkOOkdlc::loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    cxOkkkkkkkkkkkkkkOkdlc:clooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    cxOkkkkkkkkkkkkkkxc,:loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PPB is ERC721Creator {
    constructor() ERC721Creator("PEPEPAINBANE", "PPB") {}
}
