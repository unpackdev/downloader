
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kye Honoraries
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNX0kdoc:;'...             .cddoolloo:,;codk0KNWMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxoc;'............             .oOKKKKKx' ......';:ldOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xo:'. ................               'lxO0d' .............';cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xdoodl,.  ................                  ... ................  'lodOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkdoodk0KKx;.  ................                     .................  ;kOdolox0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxolok0KKKKKKk;.  ................                    ..................  ;OKKK0kolod0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd::ok0KKKKKKKKKOc.   ...............                   ...................  :OKKKKKK0OdllxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNkc.  .;ok0KKKKKKKK0o'.  ................                 ...................  .l0KKKKKKKKK0kolokXMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWKxlc'      .,lx0KKKKKKk:.   ...............                 ...................  .dKKKKKKKKKKKKK0x:,oKWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWKdlokx;.        .':ok0KK0d,.  ...............                 ...................  :OKKKKKKKKKKKOxl,. ..c0WMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMW0oldO0k:.  ..         .,cokOo'   .............                  ..................  .d0KKKKKKKOxl;.       ..:OWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWKdcdOKKOc.  ......          .',..   ............   ..              ................  .l0KKK0kdl;..             .c0WMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXxcoOKKK0o'.  .........                   .......   .;:;,'.....      ...............  .:xxoc;'.           ...     ..oKMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWOllk0KKKKk;.  ..............                        .;:c::;;,,,'....   ............     ..             .:ldkkkdl,. ...,xNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMKocx0KKKKK0o'.  ...............            ......      ...............                                  'xKKKKKKKK0d' ....c0WMMMMMMMMMMMM    //
//    MMMMMMMMMMMWOclOKKKKKKKOc.  ................             ........                                           ...      :0KKKKKKKKKKx. ....'xNMMMMMMMMMMM    //
//    MMMMMMMMMMNd:d0KKKKKKKKk:.  ................              .:ccc,.                     .....          .........       ;OKKKKKKKKKKO; ......lXMMMMMMMMMM    //
//    MMMMMMMMMKlck0KKKKKKKKKk;.  ................                .,;. .....        ..,;::clllol;.   ..............        .o0KKKKKKKKKO; .......:0MMMMMMMMM    //
//    MMMMMMMM0clOKKKKKKKKKKKk;.  ................                    ......   ..,;lxO0KK0KKKKKOc.  ...............         .d0KKKKKKKKx' ........,OWMMMMMMM    //
//    MMMMMMMO,':ccccclllloodl'.  ................                   ...    .,cdkO0KKKKKKKKKKKKx,.  ...............          .:k0KKKKK0l. .........'kWMMMMMM    //
//    MMMMMWO'                            ........                       .,lxO0KKKKKKKKKKKKKKK0d'.  ...............            .;ok000x' ...........'kWMMMMM    //
//    MMMMM0,............                                             .,lxO0KKKKKKKKKKKKKKKKKK0o'.  ...............               ..',. .............'kWMMMM    //
//    MMMMK;.................   .'',,'.                             .;oxOOOOOOOO000000KKKKKKKK0o'.  ...............                     ..............,OMMMM    //
//    MMMXc...............     ;x00000Ox:. ......                   ..............'',,;;:clodxkl'.  ................                   ................;KMMM    //
//    MMWo..............      ,kKKKKKKKKKx, .....        ......                               ..     ...............                   .................lNMM    //
//    MMO'............        c0KKKKK0kxoc'    ...',;:lloddo;.   ....................                       .........                  ..................xWM    //
//    MX:............         c00koc;'.....,:codxkO000KKK0x;.  ....................    'codddoc,.  ..             ....                 ..................;KM    //
//    Wx............          .,'....,:ldxO00KKKKKKKKKKK0x;.  .................       ;kKKKKKKK0d,.........    ..                      ...................oW    //
//    X:............          ..,coxk00KKKKKKKKKKKKKKKKKk;.  ................        .dKKKKKKKKKKk, .......... .;c:,..                            ......  ,0    //
//    x.............      ..;ldk00KKKKKKKKKKKKKKKKKKKKKOc.  ................         .xKKKKKKKKKK0c ..........  'x0Oxoc;..                                .d    //
//    c...........      'cdk0KKKKKKKKKKKKKKKKKKKKKKKKK0d'.  ...............          .oKKKKKKKKKKO: ...........  :OKKKK0kdc,.   ........     ...           ;    //
//    '..........       .oOKKKKKKKKKKKKKKKKKKKKKKKKKKKO:.  ................           ,kKKKKKKKKKd. ............ .d0KKKKKKK0ko:'.   .    .;oxkkkdl;. ....  .    //
//    ..............      ,d0KKKKKKKKKKKKKKKKKKKKKKKKKx,.  ...............             ,k0KKKKKKk, .............  :OKKKKKKKKKK0Odc'.     c0KKKKKKK0x, ......    //
//     .............       .;d0KKKKKKKKKKKKKKKKKKKKKK0o'.  ...............              .lk0KKKk, ..............  ,kKKKKKKKKKKKKK0Odc'. .:k0KKKKKKKKk' ....     //
//     .............         .,d0KKKKKKKKKKKKKKKKKKKK0l.   ...............                .;lol' ...............  .dKKKKKKKKKKKKKKKK0Od:...;dOKKKKKK0; .....    //
//     .............            ,oOKKKKKKKKKKKKKKKKKK0l.   ...............                      ................  .o0KKKKKKKKKKKKKKKKKK0xl,..'lk0KKKk, .....    //
//     ..............             .cx0KKKKKKKKKKKKKKK0l.   ................                    .................  .o0KKKKKKKKKKKKKKKKKKKKKOo'  .ck00l. .....    //
//     ..............               .;oO0KKKKKKKKKKKK0o'.  ................                   ..................  .d0KKKKKKKKKKKKKKKKKKKK0kc. ...':c. ......    //
//     .............                   .:dOKKKKKKKKKKKx;.  ................                  ...................  'xKKKKKKKKKKKKKKKKKK0Oo;.  .'cxd'  .......    //
//      ............    .                 .:dO0KKKKKKKOc.   ...............                  ...................  ;kKKKKKKKKKKKKKKKKOd:.      .:l:. ........    //
//         ........   .;;,'....              .;ok0KKKKKx,.  ...............                 ...................  .l0KKKKKKKKKKKK0Od:.              ........     //
//                   .;cc::;;,''....            .':ok0K0o'.  ..............                  ..................  'xKKKKKKKKKKOxl;.                .........     //
//    .              ...............                .':od:.   .............                  .................  .l0KKKKK0Oxl:'.                  ...........    //
//    '                                                 ...    ...........   .'....          ................  .:OK0Oxoc,.                      ...........,    //
//    l......                         .....                          ....   .;c:::;,'......   ..............   'cc:,..                         ............c    //
//    O'..............                                                      .,;;;;;;,,'.....   ......                                          ............k    //
//    Nc................                            ......         .......                                                 'ldxxdl;.            ..........:X    //
//    Mk'...............               ....  ................     ,;,'........                 .................          :OKKKKKK0Ol. ...          ......kW    //
//    MNl................         .';coo:.  ...............      .x0Okxdolc::;.                 .',,;::cloddxkkkdl:'.    .o00KKKKKKK0o. ......         ..cNM    //
//    MMK;...............    ..;coxO0K0o'  ...............       .oKKKKKKKK000l. ............   ;xOOO00KKKKKKKKKKK0Oxoc,...';ok0KKKKKk' .........  ...  ,0MM    //
//    MMWk...........    ..;ldk0KKKKKKk;.  ...............        ,kKKKKKKKKKKl. .............  .o0KKKKKKKKKKKKKKKKKKK00kdc.  .,cdOKKd. .........  .lo,'xWMM    //
//    MMMWd......     .,cdk0KKKKKKKKK0o'  ...............          ,x0KKKKKKK0: ...............  ,kKKKKKKKKKKKKKKKKKKKKKKKx,  ..,;ckk, ........... .cx:dNMMM    //
//    MMMMNl.     ..;oxOKKKKKKKKKKKKKOc.  ...............           .ck0KKKK0d. ................ .l0KKKKKKKKKKKKKKKKKKKKOo. ..,d00Ox, ............  ';lXMMMM    //
//    MMMMMXc  ..:ok0KKKKKKKKKKKKKKKKk:.  ...............             .,ldkkx, .................  ,kKKKKKKKKKKKKKKKKKK0d,   .:k0K0o. .............  .cXMMMMM    //
//    MMMMMMXc.ck0KKKKKKKKKKKKKKKKKKKk;.  ...............                 ...  .................  .o0KKKKKKKKKKKKKKK0x:.     'ldd;. ..............  :KMMMMMM    //
//    MMMMMMMXo:kKKKKKKKKKKKKKKKKKKKKk:.  ................                    ................... .cOKKKKKKKKKKKKK0x:.            .................cXMMMMMMM    //
//    MMMMMMMMNd:x0KKKKKKKKKKKKKKKKKKOc.  ................                    ...................  ;OKKKKKKKKKKK0d;.             .................lXMMMMMMMM    //
//    MMMMMMMMMNx:o0KKKKKKKKKKKKKKKKK0l.   ................                  ....................  ;kKKKKKKKK0Oo,.             ..................dNMMMMMMMMM    //
//    MMMMMMMMMMWOclkKKKKKKKKKKKKKKKKKx,.  .................                 ....................  ;OKKKKKK0x:.               .................,OWMMMMMMMMMM    //
//    MMMMMMMMMMMMXo:d0KKKKKKKKKKKKKKKOc.   ................                 ....................  cOKKK0xl'.                .................lKMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWkclk0KKKKKKKKKKKKKKx;.  .................                 ..................  .o00xc,.                   ...............,kWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMXdcoOKKKKKKKKKKKKK0o'.  ................                 ..................  'c:'.                     ...............oXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMW0lcd0KKKKKKKKKKKKOl'.  ................                  ..............               .,'.           .............c0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWOl:cdkO0KKKKKKKKOl'.   ..............    .              .........                  .;c::;'...       ..........:OWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNk:...,:ldxO00KK0o,.   ............    ':;,,'''......                             .',;;;;,,'....   ........:kNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNOc.  ....';:clol,.   ...........   .:c::;;,'.....          ......',;;'.             ..........   .....cONMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWKo,............                  .......                  .,:ldk000l.                           .,o0WMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMXkc'..................                                  .ckKKKK0o. .......         ..........:kXMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:,,;cc:;,'''......                                   .:okkl. ..............   .::,..':xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxolldkOkkxxddoo:.             ......                  ..  ................  ;olclxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkdolodO0KKKKx,.  ................                     ................. .:okXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkdolldkOx;.  ................                    ...............';lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxdol,.   ...............                   ...........';ldOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xoc:,...............                 .....',:cox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xoc,...                       ..,:ox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Kye is ERC721Creator {
    constructor() ERC721Creator("Kye Honoraries", "Kye") {}
}
