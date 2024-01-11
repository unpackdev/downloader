
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Frenemy CS Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                      'xKXNMMMMMMMMMMMWo                                                                                        //
//                       ..'oNMMMXxolcodc.                                                ...                                     //
//                           ,ldl'                                                .,:,..lOKXXk,      .'.                          //
//                                                                           'cc,,xNMN0KWMWWWM0oxOo:dKNXx,;ll;.                   //
//                                                                       :OOkXMMNNWMMMMMMMMMMMWWMMWWMMWMWNWMWK;                   //
//                                                                       cKWWWWMWMMWWMMMMMMMMMWWMMMMMMWMWWNx;.                    //
//                                                                        .,,;l0WMWXNMMMMMWWKOXWMMWNOOXWNKl.                      //
//         .,:,.                                                               .;:;.:0WMMMNk' .:cc:'  .,'.                        //
//    ko''dKWMWk;;ldxxo;.                                                            .cooc,                                       //
//    MWXXMMWMMWNWMMMMMNl                                                                                                         //
//    MMMMMMMMMMWMWWWWWK;                                                                                              .  .';l    //
//    MMMMMMMMMMMNx;,;;.                                                                                             'x0OOXNWM    //
//    WMMNOllkOOd;.               ..                                                                                 .,:oO00KW    //
//    ;c:,.                    .oO00x;                                                                                    ...:    //
//                            ,0MMWWWNl.... .:odl.                    ...                                                         //
//                         .,,xWMMMMWMXOKXOx0WMMW0ool,      .:.     .,x0d;..     ::                                               //
//                       .lXWNWMMMMMMMMMMWMMMMMMMMMMNd.     :k,  ':cldo;,coo:'. .c:.                                              //
//                       .dNWWWMWMMMMWWMWWMMMMWWXd::'.     .:d;.:olccd,.k0ccooc',',,                                              //
//                        .';;lOKKdoOXN0ocxXWWXk;          ':;:ldl:;lo,:00,.';:c;.'ol.                                            //
//                              ..  ..'.   .',.            ;:.:00d:cdxkO0kc,,,:l, .,;'                                            //
//                                                         :; :llo:;;;;;lkOOOkoc;'';l;.                                           //
//                                                     .',:o' ..,:.     .:odoc''cll:,,,,,.            .;:,                        //
//                                                  .,;;'.':.  .cc..   ;oc.    ;ddo'    ';;.         :KWMNd';dxc..,,.             //
//                                                .;;,.   ,c;,,c:.     .,. .;,            'c'    ':coKMWMMWXNMMN0KWWO'            //
//                                              .:;:o,     .'. .            ..             .c'  :XWWMMMMMMMWMMMMMMWWW0xd;         //
//                                            .;:. 'c..,;.              ..   '.    'c;..;;. ::  'x0K0KWMMMMMWMMMMMMWWMMWO'        //
//                                           .:,     ,OWWo       'c' .,lo;,,;c:,,,,;:;,,ll,'c;    ...'oxkXMMXXWMMWKl;:c;.         //
//                                          'kd.    '0WWX:      'll:,;,,,,..   ..        .;dc            ,ol'.:oo:.               //
//                         ,xOl.           'OWWc    ,KW0:    .,;:'.,lxO00kd:.         .cxxol.          .,:'                       //
//                         :XNd.          .kWNx.     ',.     ;o,'lOXMMMMMMMWO,        oNMMMk.         .kWMK;                      //
//                        ..;c. ..        :lc;.              :,.,cd0MMMMMMMMk:'      .:OWWMN:        ..lOOc.                      //
//                       lK:.;..d0:      ':.    .oc       . 'c.',..cXMMMMMWO'';      ...dNMWl       lO, ,; 'o,                    //
//                   ';. 'c:;:,,;'.,,.   ;,    .dNl       'lc. .,.  .cdxxo;. ;,      .'..;dOd,..   ..::.;;';,.                    //
//                  ,KWO;'',dKx;''lXX:  .:.    .::.        c;   .,'.  ......:,.:xOOOo'.'..'';o:,..dOl',lkkl,,oc.                  //
//                  .:o;...;cdd:;..',.  .:..'''''.         ;;    ..,'.......' .ckOOxc..;'....l,.,.;l;,:cdxc'.'.                   //
//                      .cl'.,cxXl      .ll:;'..:c.       ,o,            ..;,..     .,;;:,,co;..,    ;c.,;.::.                    //
//                      .,'  ,,.'.      'ol:;...;c.       'l,         ';',::,'....'',;:l:;.':,..:,.....:00:.'.                    //
//                          ,kx'      .::;',:c,,c,         .c.        ', .;:;,::;::;:cc;,l,;Ok:,'.::':;l0O;                       //
//                      .   ;xd'   .;dKXkc,,.;dl'           :;        .,..',;,;;;cccc;ll;;c0MMWXkol;';. ':'.,:.                   //
//                ..   .::.   ..;lkKWMMMWXd;:c;.            ;d,.       .,,',:;.;l;'cc,:ccl0WX0KWMMWXKOl'':c:',:'.:c.              //
//                .c;..,:'.,;,,c0WMMMMMMMMXl'.              ..,:,.'''..  .'..',;:::;,';xd..,;,;oXMMMMWx,'c:. .:,,c'               //
//               .';:'.;;   ,:,'lXMMMMMN0kc                    .c;''',,,,,,,:cccllc:;::,::.  ..':xOXW0;.,c'  .;'.::,.             //
//               .::'. .,    ,:,:OWN0dc'.;'                             ':,....':,...;'  c,.,;;'   .;:',co;.....';.               //
//         ...    .,:.  .    ;l::c:'.    ;'          .             ..            .'.    'c..;..',. .,'.'l:''''..,:,.              //
//       .',,'..  .::'......''..         .c:',;;'..',,,,''',;,,'''',,,',,,,,,,',,,;,,''cl.         ... .:'                        //
//       ;xO0ko:.  .'....                .c,.  .'''.  ...............  ....'.....',....cl''...'''...',',.                         //
//       lNWWWN0:.','.. .                .c;',,;;'.',;;,,,,;;,''',,;;,,,,,,,,,'','';l:,,...  ....   ...                           //
//       '0MWMWWKO00xool;'.               ..:l. .'''.  ...     .      ...        .,;'.           ..                               //
//        :XWMWWWWWMWWWKc.                   .;,'..      . .',.              .';;,.           .'',;;'....                         //
//        ,0WWWWWMMMMMM0, .'''..,,,.           .''''''''..   .:'     ....',,,,;:,'';'        .,. ....;,.,.                        //
//        .o0KOO00kOkxd; .,. ,oc. :,                  ..;,.   .cc'',,,col,...    'od,      ..;'    .''.'.                         //
//          ... ..       ''  ;d,  ;'                   .;; ..  ,;      .,,'.  ...;c,,,...,:;;:c' .''.''.                          //
//                       ,. .:c' .;.         .',,..'..'co:.    ':.        .,,.'lllc;;oc.;OXOKKkxc''''.      '.                    //
//                      .,. ',,, .;,.       .,'oNX0:.;l:cx:'. .:,           .,:'.';lo;'cKXKWWWKl'',.       .l;                    //
//                  .   .,' .,,;;',,''.     '',000K,.ll,,::cl;;'          ..       .;,oNMK0NNd,''.       .:olloc:'                //
//              ..'',;,.'''..,;,,,:;.'.     .;;OXKNo.,oollccc;           'kO,       ...:kXXx;''.         .oKKKK0d'                //
//            ''':; ...,;;'',;;;;,.,,,.      ;;lXWXxcc:,...,;.         .c:od:.          .:c''.           ..:c::c;.                //
//           :dcc,   .:;'','.',,',..;cc,.    .:;c00dc.     .,,'       .ldodkdol.          ..                                      //
//          .ONNk.   ',..... .......;c.,l;'.  .ol;;c;.     .',:'      .cllxxodc.       .,:clooddddddolc,.                         //
//          .xWMx.   ''......  ...  .;;'. :Oo':KWKo:,'.....''';:.       ';ll';.  ..    'dkO00KKKK00Okdo:.          ..             //
//           .oXO.   .:,'',,'...'...;;..''cOx;.':lodl:,',;;,,'..         .cl.    'l.       .......               .:c;:;..,;;'     //
//             .;,.;,.,lollccc:;'..':l::c::.          ........                  .';'                             ;l''':cdl.'::    //
//                ..':dkklcc,:kkddddd,,oxc':llc:,.                              .'.'';; .,.                      :c.:o;,o; 'c;    //
//                  .xXWMWWWk;oXMNx:;';OMNk:xNMMWXl.                            .,.;c;:;,;.           ..   ';;,'.c: .c:;l.'l,.    //
//              .,,.  .;cldxkockKKOkOKXNNNN0k0Okdc.            ....           ..:dkOkkOxoc;,.       .:c;;;:o;..,;olld;:kl. c:'    //
//            'c;'';c'        ......''''''....                ,c;:lc.         .:xKNWWWWNNx,.        ,l,..'do.     ':xo,ol;c;lo    //
//    .      ;l.    'l'                                      'l'   :c.         :0XXNN0kO0o.         :c'o;.lc.  .. .. .;docOc.c    //
//    c;.   .l'      :c                                      :c    .l,         ....''.  ..      .;,;olcxlo0c;o'::.xKc.  ,:l:..    //
//    .c:   :c       'l.           ...                       :c     c:                         'l:,:lc:,cod:.'..l;;KWo.   .:k0    //
//     ,l.  c:       .l,        .;;;;;:.                     ;l.    ;l.                        c:.c, .;cokk;    'l,'oc.     .d    //
//     .l; .c;       .l;       ,l,    ,l.                    .l'    ,l.                       .l, :c.';.,xK;     .c:.   cxc.      //
//     .dd;lk:        l;      ,l.     .l;                     c:    'dc'                      ,l. 'l'lNo .o:    . .,c;. lNW0;     //
//     .:, .x: ':;.   ld;,.  .l,       c:                     ,o.   .oooo;'                   ;c  .l,.c;  :c   lKx' .;c;.lXMK;    //
//          . 'l':l.  co'cl..;l..,.    cc.,'                 .cd;      ,l:o'                  c:   c;     ,l.  cNMK:   ,c::kKc    //
//            .;..,.     .lccOc :olo;. ld;'cc.               :o.         ,o'                  c::o.;l.    .l;  .xWMX;   .cc..     //
//                          .:' ...',. .   .l,              .;:lc,,,,;::;:c'                 .l;cK;.l;     ;l.  .dNMd     :c.     //
//                                         .l;                 ..    .,c'                     l;..  'l' :k:.l;    ,c'     .l,     //
//                                         .l;                                                c:     ;o.cWX;;l.    .::.    ::     //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FRNMYCSED is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
