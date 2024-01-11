
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: StevenDailys1of1s
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNK000OOOOO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxoc:,'....     ...';cokKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0dc;'.                       .':okKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMN0xc,.....                             .,lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNOl,..........                                .:xXWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWXx:. ..........                                    'o0WMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMXd,............ ...         .......                    .lKMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNx,. .....................................  ..             ,OWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMW0c.............................................              .dXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNx,...............................................  .            ;kWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMKl.............................   ..................... ..         .xNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMK:............................    ................ .........         .dNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMK:. ........................              ....       ........          .dNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMNl. ...  .... ......    ...                          .......,;.          .xWMMMMMMMMMMMMM    //
//    MMMMMMMMMMWx.  ..   ..  ....                          .              .:ko.           'OWMMMMMMMMMMMM    //
//    MMMMMMMMMMK,  ..        ..                       ..''..             ,d00l. .          :XMMMMMMMMMMMM    //
//    MMMMMMMMMWx. ...                             ..,,,'..             'oO0OOo. .          .xWMMMMMMMMMMM    //
//    MMMMMMMMMNl  ..                           .,;;,.         .     .,ok0Okxxd,             cXMMMMMMMMMMM    //
//    MMMMMMMMMX; ...                  ..   ..,;;'.                .:xO0Oxddooo:.            ;KMMMMMMMMMMM    //
//    MMMMMMMMMO.                     ... ..'........       .....,:clocc:,'.....             ;XMMMMMMMMMMM    //
//    MMMMMMMMXc                 .;;',;,..     .'.........,'...........   .';:cc;.           .cxKWMMMMMMMM    //
//    MMMMMMMMO,            ..':clc;,;,,''','..                  ..,,,,,'''',;:ld:.       .    .c0MMMMMMMM    //
//    MMMMMMMM0;      ';. .;::c:'....''',;::cc:,..             .':xo,',,,;;;,,''''.        .   .:OWMMMMMMM    //
//    MMMMMMMMNd.     ...'ldc'...''','',;;:::c:;;'.           ';,;:,',,,,,;;,,,;,'..       ..  'dXMMMMMMMM    //
//    MMMMMMMMMNl.      'dkc..''','',,,,;;;;;:::,... .;;;;.   ';,,,,,;;;,,,,,,,'',,,.      .. ;0WMMMMMMMMM    //
//    MMMMMMMMMWx..     :kl..''''''','...',''',:,....lO00Ol'. .;;,,,,...';;;;::;;;;;;.     ...OMMMMMMMMMMM    //
//    MMMMMMMMMM0,..   .lo..',''''''''......';;:,'..,ldO0Odc,..;,,,.....,::ccccccccc:,     ..lNMMMMMMMMMMM    //
//    MMMMMMMMMMWo...  .od;',;,,;,'''''''...;,',,'..dx:;;;:ol..,;,'..',,,,:ccccc:;:c:.    ..,OMMMMMMMMMMMM    //
//    MMMMMMMMMMMO'..  .o0x;''''','''''...',,',,'..lo'     ,oc...,,,,''',,;:ccccc:c:;,.   ..,KMMMMMMMMMMMM    //
//    MMMMMMMMMMXo. .. .;xOd,''''.''....',,...'...:c.       'l;..;;,;;,'.',;:ccccc:;lo.  ...,kWMMMMMMMMMMM    //
//    MMMMMMMMMM0:,.... ,oxOd;'''.....''.',;:c;..cc.         'c,.,odl;,,,''',:cc:;:oxc. ...,cdNMMMMMMMMMMM    //
//    MMMMMMMMMMNo;:... .coxOkc'',',::clloddl,..ll.    ..     ,:'..:dxocc:;;'',',lddl;....,o:cXMMMMMMMMMMM    //
//    MMMMMMMMMMWk;::'....,codllxkkOOkxxdl:'..,dx,     ...    .c;.....;:clloolc;;odoc,..':dl':KMMMMMMMMMMM    //
//    MMMMMMMMMMMO:;;:;.......':cccc:,'.....;dxxd'     ...     ,:..;;... ...,,,'.,,'..':dkdl;:0MMMMMMMMMMM    //
//    MMMMMMMMMMMNxccccc;..','...........'cdOOo:l,     ...     ';'.':lc:,'.........,:ldxxdlc:xNMMMMMMMMMMM    //
//    MMMMMMMMMMMMWKxl::lc,'lkxxdddolloddxO00Ox:;:,.',;,',:,'',;,:lc;;cldddolc;;;ldl:loooollOWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWKxc;:c;:xxdooxkddkOOOdlk0Okl;;;:;:odoc::;,;ldloo;,;::::;:l;..,:,:lcodkXMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMXkc,';l:'.';,,;cdO0kxO0kOOxo:c:,:ol,,:::lxxlodc'''...'x0;     .;xXWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMXo.     ,d;.'':oxkxdkkkkOOkxo;lOd;:ooloddooddc'''..cXk.     .dWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMXc     'ko..',,oOl:xklokkdxklo0x::do:oxl:lc:lc,...lXd..  ..'OMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWx'.   .cl....cxl;lxc;ddccdkxx0klcdd;:dx:;:',ol'..:xc......;KMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM0:.''.......';'':l,'co;,cloldOxc:ll,,co:.',..,. .'...'cc'.lNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNo;cdc'.  ..''.:ko':xo;ckkc';lc,:xo;,lko',oc',,......:dl;,xWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWklodx:..  .,';oko:okdcoxkOl'.'cOkdocdOdlldkl;,.  ..,ldc,:KMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMKoloxx:.. ...,::;,,::,,codo. .cdl:clll:ccccc;:,  .'cdc;,dWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNo;oxOx;'.'c;:dl;coc,,:c:.      .'cc,':l;:ooclc..';oo:..xWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNd;:oxOx:..'':xc;oxl;lxkd.       ,dd:;dxc:oo:c:..,ldl:.'kWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNxcccdkOx,..,:l:;dOo:lkx:.      .cxo;lkd:oOo,;,..;dol;,;xWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWx:llcoxOx;..,:::coc;ckx;''   ','lo:;lc,:ooc::;..ldlll:;kWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWx,cdoclxOk:..:;,:;';::::c;  .:c;;;:c::;;::::c:.;doldd;,kMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMk;,cdxlcdOOc':c,cd:,clo;;;  .::;c:;';:.'ll;:d:'ododdl,.dWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMXx:,;okxodOOo;c:;do,:dkc;c,.;c:ldl;,lc'lxl;cl,cdddoc:,:0WMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMN0o;,:odkO0Oxc::lxc;okocddlc:lxdl,:d::xd:co::odxoc;:oKWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0xc;:ldxoxkoldkx:cdkxkxollxxoc;dd:dklcollddocc::xXMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxccldkkkkxkOOkodO0OxooxOdlcdkodkdodxdkxo:cld0WMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0ocokkkkxkO00OO0kxxdxkkdoxOxdddddolddloodONMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkllooxxxxkO000kooxkOkkxxdllcccc::clolo0WMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;:xOkxkxx00OkO000OxdolllccccodlcdXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOoloddoc:ccc:ccc:::ccccllodoc:lOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dl;,'',:cccccc:::;,''',,,:xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK0KXNNWWWWWNNNXK0OOOO0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SD1of1 is ERC721Creator {
    constructor() ERC721Creator("StevenDailys1of1s", "SD1of1") {}
}
