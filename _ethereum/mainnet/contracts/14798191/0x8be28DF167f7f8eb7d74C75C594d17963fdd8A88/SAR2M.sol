
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SINGLE AND READY TO MINGLE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMWNWWWWWWWWWWWWWWWMMMMMMMWNXXNWMMMMMMMMMMWWWWWWWWWWWWWMMMMMMMMWWWWWMMMMMMMMMMWNWWWWMMMMMMMMMMMMWWNXXXNWMMMMMMMMM    //
//    MMMMMMMMNo'''''''''''''':0MMMN0o:,'..',:oONMMMMMNd,'''''''',;;lONMMMMNo,';kWMMMMMMMWk;''',dNMMMMMMMMW0o:,....',:oOWMMMMM    //
//    MMMMMMMMXc.....     ....'OMW0:.    ..    .:OWMMMX:    .....     lNMMMX;   dWMMMMMMMO'     .xWMMMMMMXo.   .'...   ,0MMMMM    //
//    MMMMMMMMWXKKKKk'  .lKKKKKNWk.   ,dOKKOd;   .xWMMX:   cKXXXKl.   ,KMMMX;   oWMMMMMMK;  .,.  .OMMMMMMk.   :0XNX0ko:cKMMMMM    //
//    MMMMMMMMMMMMMMX;  .xMMMMMMX;   :KMMMMMMXc   ,KMMX:   'ooool'   .dNMMMX;   oWMMMMMXc   lXx.  ,0MMMMM0;    ':lok0NWNWMMMMM    //
//    MMMMMMMMMMMMMMX;  .xMMMMMM0'   dWMMMMMMWx.  .OMMX:             'kNMMMX;   dWMMMMNo.  ;0WXc   :XMMMMWKd;..     .'lKWMMMMM    //
//    MMMMMMMMMMMMMMX;  .xMMMMMMX:   ;0WMMMMMK:   ;KMMX:   ;kOOOkl;.  .xWMMX;   oWMMMWx.   .,,,.    lNMMMNKNWX0kdl;.   ;KMMMMM    //
//    MMMMMMMMMMMMMMX;  .xMMMMMMM0,   .cxkkxl'   'kWMMX:   :O00OOo:.   lWMMX;   oWMMMO'   .......   .dWMMk'':oxO00x'   ;KMMMMM    //
//    MMMMMMMMMMMMMMK;  .xMMMMMMMWKl.          .lKWMMMX:              ;0MMMX;   oWMMK;  .lKXXXXXKd.  .kWMO'     ..   .;OWMMMMM    //
//    MMMMMMMMMMMMMMNd::l0MMMMMMMMMWXkoc;,;;cokKWMMMMMNxc:::::::::ccoONMMMMNx::cOWMWOl::dXMMMMMMMNkc:ckNMWKkoc:;;;:cdONMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNxccoKMMMWOlccccccccccl0MMMMMN0dlc::cld0NMMMMMMXdccdXMMMMMNxlco0MMMN0xocc:clokKWMMMMMMMNOoc:;;;:ldOXWMMMMM    //
//    MMMMMMMMMMMMMMK,  .xMMMWl            dWMMWO;.        .,kNMMMM0'  .OMMMMMK,  .dWMWd.         .;xNMMMNx,           :KMMMMM    //
//    MMMMMMMMMMMMMMK,  .xMMMW0dddddddl.   dWMMO.   ,lddo,   .xWMMM0'  .OMMMMMK,  .dWMWo.,codddl,.   :KMMO.   ;k0Okdl;.;0MMMMM    //
//    MMMMMMMMMMMMMMK,  .xMMMMMMMMMMMMN:   dMMWl   ;XMMMMX:   cNMMM0'  .o00000x'  .dWMWXKNMMMMMMNk'   cNMO'   .coxOKNWXKNMMMMM    //
//    MMMMMMMMMMMMMM0'  .xMMMMMMMMMMMMN:   dWMWl   lNMMMMWo   :XMMM0'             .dWMMMMMMMMMMMMWo   ,0MWO:.      .'ckNMMMMMM    //
//    MMMMMMMMMMMMMM0,  .xMMMMMMMMMMMMN:   dWMNl   lNMMMMWo   :XMMM0'   ',,,,,'   .dWMMMMMMMMMMMMXc   ;KMWWWXOdlc,.    cXMMMMM    //
//    MMMMMMMMWNXXXXk'  .oXXXXXWMMMMMMN:   dWMNl   lNMMMMWo   :XMMM0'  .kWWWWW0,  .dWMWkldOKXNX0x;   .xWMO:cdOKXNXk'   ,KMMMMM    //
//    MMMMMMMMXc.....    .....,OMMMMMMN:   dWMNl   lNMMMMWo   :XMMM0'  .OMMMMMK,  .dWMWo   .....    ;OWMMx.   ..''.   .dNMMMMM    //
//    MMMMMMMMXc..............,OMMMMMMNo..'xMMWd...dWMMMMWx'..lNMMMK:..;0MMMMMXc..'kMMM0l;'.....';oONMMMMXkl;'.....,:dKWMMMMMM    //
//    MMMMMMMMWNXXXXXXXXXXXXXXXWMMMMMMMNXXXWMMMNXXXNMMMMMMWXXXNWMMMWNXXXWMMMMMWNXXXWMMMMMWNXKKKXNWMMMMMMMMMMWNXKKXXNWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SAR2M is ERC721Creator {
    constructor() ERC721Creator("SINGLE AND READY TO MINGLE", "SAR2M") {}
}
