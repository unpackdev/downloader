
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FUD - FEAR, UNCERTAINTY & DOUBT OF THE MIND
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ccccccccccccccccccccccccccccccccc::::c:;,''......'',;:ccc:;;;;:ccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccc:;,.....  ...              .....     ..'...';ccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccc:,...   ..,;;'   'ldxkOOOkxol:'.   'oxdo;  .';'. .,;::cccccccccccccccccccccccc    //
//    cccccccccccccccccc:;,'.      ;0NWWWX:  oWMMMMMMMMMMWNOl. .lXMM0,'kNWNO,    ....',:cccccccccccccccccc    //
//    ccccccccccccccc:'.. .        :NMMMMWo  :NWKxolloONMMMMWO, .dWMK,:XMMMX:.dxo:,.    .':ccccccccccccccc    //
//    ccccccccccccc;...'lxl.       ;KMMMMWo  :Xk.      ;oOMMMWo  cNM0' ,oxo, ;XMMMNX0xl'   ':ccccccccccccc    //
//    cccccccccc;'..,lONMX:        ;XMMMMNl  c0:        .lWMMWo  cNMO.       .::cokKWMMNk;  .,cccccccccccc    //
//    ccccccc:,.   ;KMMMMk.        oWMMMMX;  oO'       .,xWMMX: .dWMk.  ...  ,do;...;kNMMNd.  ':cccccccccc    //
//    ccccc;..':lo;,OMMMWd.       ;KMMMMWx. .OO.      .oKNMMWx. ,0MWd. cKXd. :XMWKd,  :0WMWO,  .:ccccccccc    //
//    cccc,.'xXWMMx,kMMMMx.      .OMMMMM0,  ,KK,    .;kNMMMWO' .xWMNc .xMMx. cNMMMMXo. ,0MMMK:  .:cccccccc    //
//    cc:'.:KWMMMWd'kMMMMX:     'kWMMMW0;   cNWk;;cd0WMMMMNx. .oNMMO' '0MWo  oWMMMMMWx..dWMMMX:  .:ccccccc    //
//    c:'.cXMWWMMWd,OMMMMMXo'.,oKWMMMNx.   .xMMWWWMMMMMWW0:  .dNMMNl  cNMNc  :xxOKNMMWOdKMMMMMK:  .:cccccc    //
//    c'.:XMXllXMWo'kMMMMMMWNXNMMMWXk;     '0MMMMMMMMW0l;.  .kWMMM0' .kMMK,      .,o0WMMMMMMMMM0,  ':ccccc    //
//    ;.'0MMx.'0MWo.,ONMMMMMMMMNKxc'..,;;' .xWMMMMN0d;.    .dWMMMWo  :XMMk. 'dxdl;. .dNMMMMMMMMWO'  ,ccccc    //
//    ' lNMNl .OMWl  .,codxdol:;;cok0NWWWO'.xWKOdc,.       cXMMMMK; .dWMNc .dWMMMWk' .xWWOccxNMMWk. .;cccc    //
//    ..xMMK; .OMWo          .ckXWMMMMMMK:.cKd.  ..,c,    ,0MMMMWx. ,KMMO. ,KMMMMMWx. ,0Wx.  cXMMWd. .;ccc    //
//     '0MM0' .kMWd.       'oKWMMMMMMWKo'.lKx. ,x0XWK;   .kWMMMMK; .dWMNc .dWMMMMMMNc  lNX:   :KMMNl  .:cc    //
//    ..OMMO. .xMMO'     'dXMMMMMMWXx:..:ONk. '0MMMWd. ..oNMMMMWd. ,KMMO. ,0MMMMMMMMO. .OMk.   :KMMK:  'cc    //
//    ..cXMO. .dWMNo.  .lKMMMMMMXkc'.;xKWWk. .kWMMMK;  :OXMMMMMK; .dWMNl  oWMMMMMMMMX:  dWK;    cXMMO' .;c    //
//    :..:K0,  lWMMNkcckNMMMMW0l'.,o0WMMWx. .xWMMMWk'.,OWMMMMMWd. ;XMMk. ,KMWX0KWMMMNc  oWWd.   .dWMWo  .:    //
//    c;. 'd:  ;XMMMMMMMMMMNO:..cONMMMMNo. .xWMMMMMNXKXWMMMMMMO' .kMMK; .xW0:...cKMMWl  lWMK;    ,KMMK, .;    //
//    cc;. ..  .OMMMMMMMMMXl.'oKWMMMMMXl  'OWMMMMMMMMMMMMMMMMX: .dWMNl  lXk.     lNMWl  lWMMk.   .dWMWo  '    //
//    cccc;'.   ;KWMMMMMMXc.lXMMMMMMMK:  ;0MMMNOdddxxk0NMMMMNl  cNMWd. ;KO'      cNMNc  oWMMNc    cNMMk. .    //
//    cccccc;.   .lkKNWW0:.dWMMMMMMWk' .cKMMMNl.      ;KMMMNo. cXMMO' 'ONl       oWMX; .xMMMMx.   cNMM0, .    //
//    ccccccc:;'..  .,;,. .kMMMMMMXl. .xNMMMKc       .kWMMNo. cXMMK; .dW0'      .xMMO. '0MMMMK,   cNMMX; .    //
//    cccccccccccc;'.      :KMMMNk, .:0WMMW0;       .dWMMWx. cXMMXc .oNMx.      '0MWd. :XMMMMNl   lWMMX; .    //
//    cccccccccccccc:;;,.   ;0W0c. ,kNMMMNx.        lNMWNx. :XMMWd. cXMWo       lNMN: .dWMMMMMk.  oWMMX; .    //
//    cccccccccccccccccc:'.  .;. .dXMMMMKc.        ;KMWx;. :XMMM0' '0MMWl      'OMM0' .OMMMMMMK,  oWMM0' .    //
//    cccccccccccccccccccc:,.   ,OWMMMWk'         .kWWx.  ;KMMMWo  oWMMWx.    .xWMWo  cNMMMMMMX;  oWMNo  ,    //
//    cccccccccccccccccccccc;.  .':ldd:.          :XXo.   ;XMMMX: .OMMMMNx:;:oKWMM0' .kMMMMMMMX:  .::,. .:    //
//    cccccccccccccccccccccccc;..                 .;'     .kMMMX; '0MMMMMMMWWMMMMX:  lNMMMMMMWx.   ....,:c    //
//    cccccccccccccccccccccccccc::,'.     ..,'',;'...',.   cXMMNc .kMMMMMMMMMMMMNl  ;KMMMMMMNd.   ':cccccc    //
//    cccccccccccccccccccccccccccccc:;''',:cccccccccccc,.  .dWMWx. lWMMMMMMMMMMWx. '0MMMMMW0:.  .,cccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccc::'  'OMMK; 'OWMMMMMMMMWx. .kWMMMNOc.   .;ccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccc:.  ;KMWx. 'kWMMMMMMXl. .oXXKkl,     ':cccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccc;.  :KMNl  .:kKXKkl.    .'..     ..;cccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccc;.  ,0WK;    ...   ...       ..,:cccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccc;.  .xNx.  .....';:c::;;,,;:cccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccc:.  .lo.  .:ccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc,.      'cccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:,.   .:cccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:,.':ccccccccccccccccccccccccccccccccccc    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZEBRAFUD is ERC721Creator {
    constructor() ERC721Creator("FUD - FEAR, UNCERTAINTY & DOUBT OF THE MIND", "ZEBRAFUD") {}
}
