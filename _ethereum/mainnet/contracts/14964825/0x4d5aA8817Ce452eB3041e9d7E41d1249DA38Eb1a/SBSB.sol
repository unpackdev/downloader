
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: StarBase by SpaceBoysNFTs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                 //
//                                                                                                                                                                 //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xol:;,''.....',;:coxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxl;....';cllooodooolc;,....,cx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o;...;lx0XNWMMMMMMMMMMMMWWX0ko:...,oONMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx;..'lkXWMMMMMMMMMMMMMMMMMMMMMMMMWXOo,..,dXWMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd' .cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl. .oKWMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNx' .oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd' .dXMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMK: .cKWMMMMMMMMMMMMMMMMMWNK0kxxddddxxkOKXWMMMMMWKl. ;OWMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWO' 'kWMMMMMMMMMMMMMWXOdl:;,''''''''''..'',;cdOXWMMWO, .xWMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMWk. ;0WMMMMMMMMMMMWKxc,..',,;:cccccllccccc::;'..':dKWMK: .dWMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMNOdlc. .xWMMMMMMMMMMNOc'.';ccclcccccccccccccccllcccc;'.'ckNX: .xWMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMWKo,.  .,:;,c0WMMMMMMWO:..;ccllclllccccccccccccccclccllccc;..:O0, .:kNMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMXo';okOx:';kk;'dNMMMMXo..;ccclcccccccccccccccccccclcclcccllcc;..lo. ..:0WMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMXc.oNMMMMWk''kXc.dWMMXc.':lcccclcccccccccccccccccccccccloddolll:'.,. .l;,OMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMWd.cNMMMMMMWk.;K0',KMNo.'ccllclcclccccccccccccccccccccccoxkkkxolcc'.  .dk':XMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMX:.kMMMMMMMMX;.kNc.kMO'.:lcclccccccccccccccccccccccccccclxkkkkdlcl:.   oXc'kMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMX:.kMMMMMMMMX;.kNc.xWo.'cccccccccccccccccccccccccccllccclodxxdolccc'   oNo.xMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMWo.oWMMMMMMMO',0K,'0Wo.'cccccccccccccccccccccccccclccccllclllllllcc'  .dNc'kMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMK;.xWMMMMMK:.dXo.oNWx..clcccccccccccccccccccccccccccllcccclloddlc:.  .OO':XMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMK:'cOKX0d,'d0l.cXMMK;.;cclcccccccccccccccccccccccccccccccllllllc,.  :x;,OMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMNkc'....,lc,;xNMMMWk'.;ccccccccccccccccccccccccccccccccccccllc;.   '':0WMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMWKxc:;. .dXMMMMMMWk'.,cccclcccccccccccccccccccccccccccccllc,.   .:kNMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMWNd. cXMMMMMMMW0c..;ccccccccccccccccccccccccccccccccc;..   lXWMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNd. ;0WMMMMMMMNk:..,:clccccllcccccccclcccccclccc:,..'. .oNMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWk, .dNMMMMMMMMNOl,..,;:cccllccccccccllllcc:;'..;lc. .xNMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMKl. ,xNMMMMMMMMMNOo:,'..'',;;;::::;;;,''.';cdOx;..cKWMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c..,dKWMMMMMMMMMWN0Okdlc:;;;,;;;::codOKNKx;..;ONMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c. .:xKWMMMMMMMMMMMMMMWWNNNNNWWWMMWXkc.  ;ONMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo,     .;lx0NWMMMMMMMMMMMMMMMMWNKko;...   .ckXWMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWXxc'   'cxOkl,....,cloxxkkOOOkkxdlc;'...,cx0Oo,.  .lOWMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMW0l.  .;oONWMMMMWXOdl:,'.............,:ldkKNMMMMMNOl'  .;kNMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMKl.  ,d0WMMMMMMMMMMMMMWWNXK00OOOOO0KXNWWMMMMMMMMMMMMMXk;. .cKMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMW0,  'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'  ;0MMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMM0,  ;0WMMMMMMMMMWNKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0,  :XMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMNc  ,0MMMMMMMMMMMXc.,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNko0WMWx. .xWMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMk. .dWMMMMMMMMMMMO. .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' ;XMMX;  :XMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMNl  ,KMMMMMMMMMMMWd. ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK; .OMMWd. .kMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMK,  oWMMMMMMMMMMMK;  oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl .dWMMK,  cNMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMk. .kMMMMMMMMMMMWx. '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx. lNMMWo  .OMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMWl  ,KMMMMMMMMMMMX:  lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO. ;KMMM0'  lNMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMK;  lNMMMMMMMMMMMk. .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX; .OMMMNl  '0MMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMO. .dWMMMMMMMMMMWl  ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc .xMMMMk. .dMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMM  #####  ######     #     #####  ####### ######  ####### #     #  #####  MMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMM #     # #     #   # #   #     # #       #     # #     #  #   #  #     # MMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMM #       #     #  #   #  #       #       #     # #     #   # #   #       MMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMM  #####  ######  #     # #       #####   ######  #     #    #     #####  MMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMM       # #       ####### #       #       #     # #     #    #          # MMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMM #     # #       #     # #     # #       #     # #     #    #    #     # MMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMM  #####  #       #     #  #####  ####### ######  #######    #     #####  MMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                         //
//                                                                                                                                                                 //
//                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SBSB is ERC721Creator {
    constructor() ERC721Creator("StarBase by SpaceBoysNFTs", "SBSB") {}
}
