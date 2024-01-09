
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mahi HQ
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//             M['']   ['']     ['']     ['']  ['']  ['']       ['']  ['']   ['''''']                          //
//         MMMMM[  .\ /.  ]   [  /\  ]   [  ]  [  ]  [  ]       [  ]  [  ]  [  ]  [  ]                         //
//      MMMMMMMM[  ] . [  ]  [  ----  ]  [  ----  ]  [  ]       [  ----  ]  [  ]  [  ]                         //
//     MMMMMMMMM[  ]   [  ]  [  ]  [  ]  [  ]  [  ]  [  ]       [  ]  [  ]  [  ]  [  ]                         //
//    MMMMMMMMMM[..]   [..]  [..]  [..]  [..]  [..]  [..]       [..]  [..]   [......\ ]                        //
//    mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM[..]                       //
//    ..aMMMMMMMMMMMMMMMMMMMMMMMMMMMMM./\[thankyou]/\.MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                        //
//    ....dMMMMMMMMMMMMMMMMMMMMMWXOdl:,..             ..,cokKWMW0lldKMMMMMMMMMMMMMMMMMMMMM                     //
//    .....eMMMMMMMMMMMMMMMMMNkl,.   .'!peace!love!=:.      .,ldoo;.;cOMMMMMMMMMMMMMMMMMMMMMM                  //
//    .....MMMMMMMMMMMMMMMW0l'  .,lx0XWMMMMMMMMMMMMMMWN0xl;.   .;art:lifeXNMW00WMMMMMMMMMMMMMMM                //
//    ....wMMMMMMMMMMMMMWO:. .;dKWMMMMMMMMMMMMMMMMMMMMMMMMWXkc'  .;c,..:xkdooOWMMMMMMMMMMMMMMMMM               //
//    ..iMMMMMMMMMMMMMMXl. .cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:.  ';ccc,.:KWWNXWMMMMMMMMMMMMMMMM             //
//    .tMMMMMMMMMMMMMWO,  ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo.  'cddxllxXMMMMMMMMMMMMMMMMMMMM            //
//    .hMMMMMMMMMMMMWx. .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'  .,xkxXMMMMMMMMMMMMMMMMMMMMMMM          //
//    ..MMMMMMMMMMMWx. .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMLOokNMMMMMMMXo.   :KMMMMMMMMMMMMMMMMMMMMMMMMM         //
//    ...lMMMMMMMMWk. .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0, ,0MMMMMMMMW0d:  'kWMMMMMMMMMMMMMMMMMMMMMMMM        //
//    .....oMMMMMM0'  oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM!joy!MMMMMMMMMMMNd. .oNMMMMMMMMMMMMMMMMMMMMMMMM       //
//    ......vMMMMNc  :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO'  cXMMMMMMMMMMMMMMMMMMMMMMMM      //
//    ......eMMMMx. .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;  :KMMMMMMMMMMN0kxdxkKNMMMMM     //
//    ......MMMMX:  lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;  :XMMMMMMNkc'.     .,dNMMM     //
//    ....aMMMMMO. .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;  :XMMMXd'  .:ox0xo'  cNMMM    //
//    ...nMMMMMMd  ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,  cXNd'  ,dXWMMMMMx. '0MMM    //
//    ..dMMMMMMMo  :NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'  ,,  'xNMMMMMMMNl  ,KMMM    //
//    ..MMMMMMMMo  ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.   .cKMMMMMMXxl,  .kWMMM    //
//    ..gMMMMMMMx. ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,   cNMMMMMMMO.   .kWMMMM    //
//    ...oMMMMMM0' .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;    '0MMMMMMMWKd'  :XMMMM    //
//    .....oMMMMNl  :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.  ;,  ;KMMMMMMMMM0' .dMMMM    //
//    .......dMMMK,  cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo. .dNK:  ,kWMMMMMMMN:  oMMMM    //
//    .........MMM0,  ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMK:  'kWMMXo. .:ONMMMMWx. .kMMMM    //
//    .........!MMMXl. .:kNMMMMMMMMMMMMMMMMMMMMMMMMN0d;,dNMMMMMMMMMMMMMMMMWO,  ;KMMMMMW0c.  !vibe;. .dNMMMM    //
//    ........ vMMMMW0c.  'lkKWMMMMMMMMMMMMMMMWX0xc,.  .xNMMMMMMMMMMMMMMMNd. .lXMMMMMMMMW0o,.     .c0WMMMMM    //
//    .........iMMMMMMWKd;.  .!create!kindness:.      cKMMMMMMMMMMMMMMNkl,  'kWMMMMMMMMMMMMNKOxxk0XWMMMMMMM    //
//    ........bMMMMMMMMMMWKkl,..    ...      .';cd;  '0MMMMMMMMMMMMWKd,   .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    .......eMMMMMMMMMMMMMMMWX0!wander!wonder:WMM0,  ,xXWMMMMMMN0d:.  ':oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    ......sMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl.  !imagine'.  'ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    .....MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXxc,..   ..':oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    ...MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK00O0KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WAVES is ERC721Creator {
    constructor() ERC721Creator("mahi HQ", "WAVES") {}
}
