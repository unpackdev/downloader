
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KLEW
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd:;ddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddo:,'cdddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd:,;,ldddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddxc,;,;lddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddddollc:::::cllodddddddddddddddddddddddddddddddxl,;oc,,;;ld    //
//    dddddddddddddddddddddddddddddddddddddddddddddoc:;,,;;;;;;;;;,'...';codddddddddddddddddddddddddddddo;;;;cc.'o    //
//    dddddddddddddddddddddddddddddddddddddddddl:;;;:ldk0KNWWWMMMMWNKOdc,..':oddddddddddddddddddddddddddd;.:llc'.:    //
//    dddddddddddddddddddddddddddddddddddddl:,;:lx0NWMMMMMMMMMMMMMMMMMMMW0o;..,cdddddddddddddddddddddddddo:;;lo,.:    //
//    ddddddddddddddddddddddddddddddddddl;,;cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o,..cddddddddddddddddddddddddl,cxd:.;    //
//    dddddddddddddddddddddddddddddddo:,;lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:.'cddddddddddddddddddddxd''oxd''o    //
//    dddddddddddddddddddddddddddddl;,ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.,ldddddddddddddl,,,'',;ldo;.;d    //
//    dddddddddddddddddddddddddddl;;o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk;.:lloolodddoc,..:cc;;oddl..;d    //
//    dddddddddddddddddddddddddo;;dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd..;:,.','...',cdxxxllxko,.'o    //
//    ddddddddddddddddddddddddc;oXMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,,'..   .,colclxkOOdodc..cd    //
//    o:coodddddddddddddddddd;;OWMMMMMMMMMMWK00KXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.        .:cdxdclOKOl,.'ldd    //
//    d;.,;:dddddddddddddddd,,OMMMMMMMMMMMMNKKXXNNXNWMMMMMMMMMMMMMMMMMMMWNXWMMMMMMMWKl.          .:oO0xclxl;'.:xdd    //
//    ddc,;:;lddddddddddddx:.dWMMMMMMMMN00OdolllokXWMMMMMMMMMMMMMMMMMNOl;..,ckNMMMWOc,            .;xxll:,,'.'cddd    //
//    ddo;co,;ddddddddddddd''0MMMMMMMMO:ll;;loooolco0WMMMMMMMMMMMMMWKc.       ,kWMK:';.             ,:,,;',:lodddd    //
//    dd:;od;,:oddddddddddd''0MMMNOxxd:l00kdd00kk00d:dXMMMMMMMMMMMW0:          .lX0;.;,  ....,,.     ..'',oxdddddd    //
//    xl,:xxdc',odddddddddd,.xM0ocldkOkxxkkOxk0KOk0KO:cXMMNNWMMMMNxc.            ;xl..'...''. ,;      .clddddddddd    //
//    ddc,coo:.,ldddddl:::c, ;kc,okOxkKKxok00O0KK00KKO;cXMWK0XMMWO,,,             .c;..':dO0o. ,,     .:dddddddddd    //
//    dddl,'cool:,;lc:',:loc;:dd:lxkOxOK0xk00000KOO00Kd'dWMXOKWMNk..;.  ....;'     .lk0XNMMWKl. ,.     .lxdddddddd    //
//    ddddo:'':loc,,:ccoO00kxx0d:lxxkkk0KOkkO000KOdk00k;;KMNKOKMW0: .'...'. .;'     '0MMMMMMWO;.;,      ,ddddddddd    //
//    ddddddo:'.,clolclxkOkkxOkccoxxxOxkK0xkOOK000xd0KO:.dMWNkOMMXd' .':dOk: .;.     ;KMMMWX0o;'.       .cxddddddd    //
//    ddddddddd;..;cclxxxkxxOx::dldOx0xo00xkkkK0O00xkOd, lWWWxkMMWXkk0XNMMNO; .,.     cNMXo,.            ,dddddddd    //
//    ddddddddddc'..';coddkxdollxlkOdOdcOKkxcokxodxl:::. lWWNdxMMMMMMMMMMMMXd,.:'     .xKo'..            .lxdddddd    //
//    ddddddddddddl:;'.':ooooc:olckocdc;oxoc,::;;;;,';,..kMKxcxMMMMMMMMMMWX0o;'.       ';.  ..           .cxdddddd    //
//    dddddddddddddddo,...,,'.;,.,,',;,,;;;'','.'''..',c0WXl.cKWMMMMMMMW0l,.           .cd; .'           .cxdddddd    //
//    dddddddddddddddddlcccc:;;;:c;','.''',','':c:lxkkxxxxoloxKWMMMMMMW0l'..            lNk. '.          .cxdddddd    //
//    ddddddddddddddddddddddddxddddddl:cclodddlcxXMMMNK00XXKOKNMMMMMMNk,. ...           ;XKc ''          .lxdddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddllkNWOk0k0WMMMMMMMMMMW0xl. ..           ,KXd.''          'oddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddoco0kxKkONMMMMMMMMMMMMMXo..,.          ;KNx..;.        .:dddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddd:cOOkO0XWMMMMMMMMMMMMW0,.,.          cNWO,.;;       .:ddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddd,cXWNWMMMMMMMMMMMMMMMK:.'.          oMWKl. ',.....'cdddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddxc.dMMMMMMMMMMMMMMMMMMXl.,,         '0MMNOc.   ..'.,odddddddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddxo.:XMMMMMMMMMMMMMMMMMNx..:'       .kWMMMWXOdc::lx;.odddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddd'.OMMMMMMMMMMMMMMMMMN0: .''.....:OWMMMMMMMWWWWWWc.oxddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddd,.xMMMMMMMMMMMMMMMMMMXx;.  ...'lKMMMMMMMMMMMMMMWc.ldddddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddd,.dMMMMMMMMMMMMMMMMMMMNKkl:;:lkNMMMMMMMMMMMMMWNOoloc:lddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddd, dMMMMMMMMMMMMMMMMMMMMMMWNNWWMMMMMMMMMMMWNXKOkxxol:,:ddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddd' oWMMWWMMMMMMMMMMMMMMMMNXXNNNNNNXXXXKKK0Okxdolc:;::;,coddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddc,,lKNXKNMMMMMMMMMMMMMMWx:ldddddddddooolllc:;;;:::::;';oddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddo:cx0KNMMMMMMMMMMMMMM0:,;::::::::::;;;:::cllc:::::,,odddddd    //
//    dddddddddddddddddddddddddddddddddddddddddddddddddddo;dNWMMMMMMMMMMMMMXo,;::llc:::::::::::::clc:::::,cddddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddxl:OMMMMMMMMMMMMMMWk;;:::ccc::::::::::::::::::::;;lxdddddd    //
//    ddddddddddddddddddddddddddddddddddddddddddddddddddl,oWMMMMMMMMMMMMMM0c;:::::::::::::::::::::::::::;:dddddddd    //
//    dddddddddddddddddddddddo:,:ldddddddddddddddddddddl':XMMMMMMMMMMMMMMXo,;::::::::::::::::::::::::::;;ldddddddd    //
//    ddddddddddddddddddddddo'  ..',;codddddddddddddddo';KMMMMMMMMMMMMMMWx;;;::::::::::::::::::::::::::,cddddddddd    //
//    dddddddddddddddddddddo'  ',,'...',;:lodddddddddo''OMMMMMMMMMMMMMMM0c,;::::::::::::::::::::::::::,:dddddddddd    //
//    dddddddddddddddddddddo'  ',,,,,,,'..'''',cddddxc.dWMMMMMMMMMMMMMMWd,;;::cc:::::::::::::::::::::;;odddddddddd    //
//    ddddddddddddddddddddddo. .,,,,,,,,,,;,''..;ddddd:lKMMMMMMMMMMMMMMW0:,::cll::::::::::::::::::::;:oddddddddddd    //
//    ddddddddddddddddddddddo' .,,,,,'.....',,,..:dddddc;xNMMMMMMMMMMMMMW0oc;;:::::::::::;;:c::::::;cddddddddddddd    //
//    dddddddddddddddddddddd:..,,,,,.';;:l;..,,,..lddddxl,;ONWMMMMMMMMMMMMWXOxol:;;::::::;coo:::::;:oddddddddddddd    //
//    dddddddddddddddddddddo. ',,,,.,c,,cll,..... ,cc:;,,. .'c0WMMMMMMMMMMMMMMMNKOxdlc:;;;:c::::,,;ldddddddddddddd    //
//    ddddddddddddddddddddd; .,,,;'.c;,0MWNK0kxdooododdxOOx:'..:kXMMMMMMMMMMMMMMMMMMWKo,;::::::clooddddddddddddddd    //
//    ddddddddddddddddddddl..,,,,;'.;l:cox0XWMMMMMMMMMMMMMMWNO,  'cxXWMMMMMMMMMMMMMXx:;ldddddddddddddddddddddddddd    //
//    dddddddddddddddddddd, .,,,,,,. .,'. .':lodkOKXNWWWWWNNXXx.    .:d0WMMMMMMMMMWx.;dddddddddddddddddddddddddddd    //
//    ddddddddddddddddddd:..,,,,,,,,.     ..,''....';:;;,,''...   ...';cdKWMMMMMMMM0,,dddddddddddddddddddddddddddd    //
//    ddddddddddddddddddl..',,,,,,,,,,'..',,,,,,,,..colcc::::::cclooddxdlcdXMMMMWKd'.cdddddddddddddddddddddddddddd    //
//    dddddddddddddddddd, .,,,,,,,,,,,,,,,,,,,,,,,. :ddddddddddddddddddddo,,lddl;..:oddddddddddddddddddddddddddddd    //
//    dddddddddddddddddc..,,,,,,,,,,,,,,,,,,,,,,,,. ,ddddddddddddddddddddddc,'',;cdddddddddddddddddddddddddddddddd    //
//    ddddddddddddddddo. ',,,,,,,,,,,,,,,,,,,,,,,,. .odddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd    //
//    dddddddddddddddd; .,,,,,,,,,,,,,,,,,,,,,,,,,' .cxddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd    //
//    ddddddddddddddxo. ',,,,,,,,,,,,,,,,,,,,,,,,,'. ;dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KLEW is ERC721Creator {
    constructor() ERC721Creator("KLEW", "KLEW") {}
}
