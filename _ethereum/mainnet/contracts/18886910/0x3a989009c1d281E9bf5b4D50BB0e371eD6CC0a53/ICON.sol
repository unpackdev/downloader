// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monster Icons
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    XXXKKKKKKXKKKKKKKKXKKXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNXXXXXXXXXXXXXXXXXKKKKKKXNWWWWWWWWWWWWWWWW    //
//    XKKKKKKKKKKKK000KKKKXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNXXXXXXXXXXXXXXXXXXXKKKKKXNWWWWWWWWWWWWWWWWW    //
//    KKKXXXKKKKKKKXK0KKXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXXXXXXXXXXXXXXXXXXXXXXKXXXNXOdONWWWWWWWWWWWWWW    //
//    XXXXXXKKKXXKXXKKXWWWWWWWNXXWWWWWWWWWWWWWWWWWWWWWWNNNXXXXXXXKKXXXXXXKK0kxddookKNWWXc .oXWWWWWWWWWWWWW    //
//    XXXXXXXXXXXXXXXNWWWWWWNk:.cXMWXkdoooooooodxO00KKKKKKKXXXKK0Okxolc:;;,,'',,;:xXWWWNl   ;ONWWWWWWWWWWW    //
//    XXKKKXXXKXXXNNWWWWWWNx;,'.cNWW0occcc:,''''''''..'',,;::;,'.....',:lodkO00KXNWWWWWWd.,:..cKWWWWWWWWWW    //
//    XXXXXXXXXXNNWWWWWWW0:'ckl,kWWWWWWWWWWX0Odl:,.........,:::;,'..''',:coxOKXNWWWWWWWWd'dXd..lNWWWWWWWWW    //
//    XXXXXXXXNWWWWWWWWNd',kNK::KWWWWWNKOdl;'...',cldkOOOO0KXXXXKK0OOxoc:;''',;lxKWMWWWWo,kWNO,'kWWWWWWWWW    //
//    XXXXXXNWWWWWWWWWNd.:KWW0;lNWWWW0c,,,:loxkO0KXKKKXXXX0xooollldOKKKKKKK0OxoloOWWWWWK:;0WWWk':XMWWWWWWN    //
//    XXXXNWWWWWWWWWWWk':0NWWO;lNMWWWXkk0KXXKKKKOd:,;;;:::'..,;;;...,;;;;cxOOOKNWWWWWWWx'oNWWNKc'xWWWWWNXX    //
//    XXNWWWWWWWWWWWMXc'docOWK;:KWWWNNXXKKXKKKk:. .::'..   ,kKKKKx. ,dxd:......oNWWWWW0;:KWW0cld,:XWNNXXXX    //
//    NWWWWWWWWWWWWWWO';d'.kWNd'lXNNXXXXKK0xc,. . .'...''...ldx00o. cKXXk'.lkl.,0WWWWK:,kWWWx.;0o,xNXXXXXX    //
//    WWWWWWWWWWWWWMWd.cOc:0WWNx;:d0XXXXXO:..;lxkc. .o0KKk, .'.:d;'lOKko;.;c;...xWWKd,.oXWWWO:oXO':0XXXXXX    //
//    WWWWWWWWWWMWWWWk'cXNNWWWMWKd:;cdk0Oc..lO0KKd..l0KKKx' ,dxxkkkO0k:.'od'.:' ,oc',l0N0llKWNWWO';OXXXXXX    //
//    WWWWWWWWWWWWWWWK;,OWNklkNWWWXkc....   ...''.  ',,,,.   .......... .;, .'. .':xKWXd'.oXWWWWx.;0XXXXXK    //
//    WWWWWWWWWWWWWWMWx':KNk,.c0NKold:              .                         'lx0NW0l,,cONKodXNo.c0KKXXXK    //
//    WWWWWWWWWWWWWWWWNo.;ONKo..cd:...            .d0o.                       .':OWW0dxKWWK:.lX0'.dKXXXXXX    //
//    WWWWWWWWWWWWWWWWWKo..dNWKo,.',.             :XWk.                        .,:l0WWWKkl,'lKXc.c0XKKKKKK    //
//    WWWWWWWWWWWWWWWNXXKd,.c0Xx;'''.            .xWNl                          .,oOOd:..;o0XO:.c0XXKKKKKX    //
//    WWWWWWWWWWWWWNXXXXXK0d,,:c;...     ....    :KW0,                         ...''',:d0XKx;';d0XXXXXXXXX    //
//    WWWWWWWWWWWWNXXXXXXXXX0xc;,'.    ;k000OOkkk0WWKdlc:;,,'....                 .:dO0Oxc,,ckKXXXXXXXXXXX    //
//    WWWWWWWWWWNXXXKKKKKXXXXXX0d'     ,Monster Icons by Des Lucréce;.             ......:dOkdooodkO0XXXXX    //
//    WWWWWWWWNNXXXXK0O0KKXXXXXKd.         .....cKW0c,,;;;::clodkOKXk'                 .lxl,.    ...,l0XXX    //
//    WWWWWWWNXXXXXKKKKKXXXXKko,.               ;KWO'            ....                 .lo'     ...    :0KX    //
//    WWWWWNXXXXXXXXXXXXKKXKd'                  ;KMO'                                .ox,   .:dkOd'   .dXX    //
//    WWWNXXXXXKOxx0KXXXXXXXOo,.                .lxc.                               .d0o'...c0XKkc.   .dXX    //
//    WWNXXXXX0d:..':d0XXXXXXK0x;                                                   .:kc.. .dXX0c.   .:OXN    //
//    NXXXXXXX0d'     'lOKXXXKKKd. ..,.                                            .'lk:   .dKXKx:,,:d0NWW    //
//    XXXXXXXXXKkc.    .cOKKKKKK0xdkKN0;                            ,c.        .cdxO0KKl.   ;OKKKKKKXNWWWW    //
//    XXKxlccccccldo;..:kKXKKXXNWKd:oKWO'       .;'        ,xo.   .ok:         :KXXXXXXO;   .;kKXXXNWWWWWW    //
//    XXO:.       cKKkx0XXXXXNWWWk'  ,ONd.    .;xX0;     .:xkko'.;kk;          cOXXXXXXXk;    .:d0NWWWWWWW    //
//    XXOl,......'lko,:d0KXNWWWWXc    'kXx,......cKKl..,ll;. .lkOOl.            .;dOKXXXX0o;.    .:dOXNWWM    //
//    XXXK00OOOOOxc.   .c0NWWWWW0'     .xX0c.     :KNKx:,.    .:o;                 .:x0OOKXKOd:.    ..;lON    //
//    XXXXXXKKKOl.    .;ONWWWWWM0,      .;,        ;Ox,                              .,..cONWWWKkl,.    .,    //
//    XKXXXXKK0l.   .;kXWWWWWWWMK;                  .                                     'lkXWWWWNKkl'       //
//    XXXXXXKKKOo;,lkXWWMWWWWWWMK:                                                          .,o0WWWMWWXd.     //
//    XXXXXXXXXXK0KNWWWWWWWWWWWWNd'                                                            .l0WWWWWWk'    //
//    XXKKKXXXXXXNWWWWWWWWWWWWWWWN0kdlloooool:;'..     ..........                                .oKWWWWWx    //
//    XXXXXXXXXXNWWWWWWWWWWWWWWWWWWWMWWWWWNXXXK00OkxddxkkOO00000Oxoc;.                             'xNWWWX    //
//    XXXXXXXXNWWWWWWWWWWWWWWWWWWWWWWWWWNXXXXXXXXXXXXXXXXXXXXXXXXXXXKOc.    .,cooo:.                .lXWW0    //
//    XXXXXXNNWWWWWWWWWWWWWWWWWWWWWWWWNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKl.  .oXNKKXNKx,                ,kNx    //
//    XXXXXNWWWWWWWWWWWWWWWWWWWWWWWWNXXXXXXKKKKXXXXXXXXXXXXXXXXXXXXXXXXKl. ;KWk'.'cOWXl.               .:,    //
//    XXXNWWWWWWWWWWWWWWWWWWWWWWWWWNXXXXXKKKKXXXXXXXXXXXXXXKKKXXXXKKXXXXk' cXXl    .kWXc                      //
//    XXNWWWWWWWWWWWWWWWWWWWWWWWWWNXXXXXKKXXXXXXXXXXXXXXXXXKKKXXXXXXXXNWXc.cXXl     'OW0,                     //
//    XNWWWWWWWWWWWWWWWWWWWWWWWWNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWNl.cNNo.     lNWd.                    //
//    WWWWWWWWWWWWWWWWWWWWWWWWNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWMNo.:XWx.     'OW0,                    //
//    WWWWWWWWWWWWWWWWWWWWWWWNXXXXXXXXXKKKKXXXXXXXXXXXXXXXXXXXXXNNWWWWWWWx.,0Wk.     .oNXc                    //
//    WWWWWWWWWWWWWWWWWWWWWWNXXXXXXXXXXKKKXXXXXXXXXXXXXXXXXXXXNNWWWWWWWWWx..kW0,      cXNd.                   //
//    WWWWWWWWWWWWWWWWWWWWNXXXXXKXXKXXXXXXXXXXXXXXXXXXXXXXXXNNWWWWWWWWWWWd..dNNc      ,0Wk.                   //
//    WWWWWWWWWWWWWWWWWWWNXXXXXXKXXKXXXXXXXXXXKXXXXXXXXXXXXNWWWWWWWWWWWWWd. cXWo.     .xW0,                   //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ICON is ERC721Creator {
    constructor() ERC721Creator("Monster Icons", "ICON") {}
}
