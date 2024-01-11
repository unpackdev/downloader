
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SVDP
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMWKxooooooooooxKWMMMMMMMKdooookNMXxooooxXMMMMMMMNkooooooooooooxXMMMMMMMXxodooooooooodONMMMMMMM    //
//    MMMMMMMO'            ,0MMMMMMMO.    cNMX:    ,KMMMMMMMNc             ,0MMMMMMK,             lNMMMMMM    //
//    MMMMMMMd             .xMMMMMMMK,    dMMWl    :NMMMMMMMMo             .kMMMMMMN:             ,KMMMMMM    //
//    MMMMMMMd    .dkOo.   .xMMMMMMMK,    dMMWl    :NMMMMMMMMo    'xOOl.   .kMMMMMMN:    ;kkk:    ,KMMMMMM    //
//    MMMMMMMd    ,KMM0'   .xMMMMMMMK,    dMMWl    :NMMMMMMMMo    ;XMMO.   .kMMMMMMN:    lWMMd    ,KMMMMMM    //
//    MMMMMMMx.   '0MM0'    dMMMMMMMK,    dMMWl    :NMMMMMMMMo    ;XMMO.   .kMMMMMMN:    lWMNc    ,KMMMMMM    //
//    MMMMMMMK;    ;0MXo::::xWMMMMMMK,    dMMWl    :NMMMMMMMMo    ;XMMO.   .kMMMMMMN:    ,dxc.    oWMMMMMM    //
//    MMMMMMMMKc    'kWMMMMMMMMMMMMMK,    dMMWl    :NMMMMMMMMo    ;XMMO.   .kMMMMMMN:            cXMMMMMMM    //
//    MMMMMMMMMNd.   .dNMMMMMMMMMMMMK,    dMMWl    :NMMMMMMMMo    ;XMMO.   .kMMMMMMN:           :KMMMMMMMM    //
//    MMMMMMMMMMWk'    cXMMMMMMMMMMMX;    oWMWc    cNMMMMMMMMo    ;XMMO.   .kMMMMMMN:    ,dxxxxONMMMMMMMMM    //
//    MMMMMMMMMMMM0;    ,0MMMMMMMMMMWl    :XMK,   .dMMMMMMMMMo    ;XMMO.   .kMMMMMMN:    lWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXl.   .kWMMMMMMMMMk.   .OMk.   '0MMMMMMMMMo    ;XMMO.   .kMMMMMMN:    lWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNx.   .dNMMMMMMMMX;    dWo    :NMMMMMMMMMo    ;XMMO.   .kMMMMMMN:    lWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWx.   .OMMMMMMMMWo    cX:    dMMMMMMMMMMo    ;XMMO.   .kMMMMMMN:    lWMMMMMMMMMMMMMMM    //
//    MMMMMMNkooookNMM0'   .xMMMMMMMMMO.   ,d'   '0MMMMMMMMMMo    ;XMMO.   .kMMMMMMN:    lWMMMMMMMMMMMMMMM    //
//    MMMMMMWl    ,KMM0'   .xMMMMMMMMMX;   .'.   :NMMMMMMMMMMo    ;XMMO.   .kMMMMMMN:    lWMMMMMMMMMMMMMMM    //
//    MMMMMMMd    ,0WWO'   .xMMMMMMMMMWo         dMMMMMMMMMMMo    ;KWWk.   .kMMMMMMN:    lWMMMMMMMMMMMMMMM    //
//    MMMMMMMd     ',,.    .xMMMMMMMMMMO.       '0MMMMMMMMMMMo     ',,.    .kMMMMMMN:    lWMMMMMMMMMMMMMMM    //
//    MMMMMMMx.            .kMMMMMMMMMMX;       :NMMMMMMMMMMWl             .OMMMMMMX;    cWMMMMMMMMMMMMMMM    //
//    MMMMMMMNd;'''''''''';xNMMMMMMMMMMNo'''''''dWMMMMMMMMMMNo'''''''''''';xNMMMMMMKc''''lXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWWNWWWWWWNWWMMMMMMMMMMMMMWWWWWWWWWMMMMMMMMMMMWWWWWWWWWWWWWWWMMMMMMMMWWWWWWWWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SVDP is ERC721Creator {
    constructor() ERC721Creator("SVDP", "SVDP") {}
}
