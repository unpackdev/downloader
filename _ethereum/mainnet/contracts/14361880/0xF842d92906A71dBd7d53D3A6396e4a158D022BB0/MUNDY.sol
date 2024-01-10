
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sean Mundy - Select 1 of 1 NFTs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                         //
//                                                                                                         //
//       _____                     __  ___                __                                               //
//      / ___/___  ____ _____     /  |/  /_  ______  ____/ /_  __                                          //
//      \__ \/ _ \/ __ `/ __ \   / /|_/ / / / / __ \/ __  / / / /                                          //
//     ___/ /  __/ /_/ / / / /  / /  / / /_/ / / / / /_/ / /_/ /                                           //
//    /____/\___/\__,_/_/ /_/  /_/  /_/\__,_/_/ /_/\__,_/\__, /                                            //
//       _____      __          __     ___         ____ /____/  _   ______________                         //
//      / ___/___  / /__  _____/ /_   <  /  ____  / __/  <  /  / | / / ____/_  __/____                     //
//      \__ \/ _ \/ / _ \/ ___/ __/   / /  / __ \/ /_    / /  /  |/ / /_    / / / ___/                     //
//     ___/ /  __/ /  __/ /__/ /_    / /  / /_/ / __/   / /  / /|  / __/   / / (__  )                      //
//    /____/\___/_/\___/\___/\__/   /_/   \____/_/     /_/  /_/ |_/_/     /_/ /____/                       //
//                                                                                                         //
//                                                                                                         //
//    ________________________________________________________________________________                     //
//                                                                                                         //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKK0000KKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxoc:,..........,;coxOKWMMMMMMMMMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMMMMMWKxc,...,:codo'    'odoc:,...,cx0NMMMMMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMMNOo,..,cxOXWMMMWd.    .dWMMMWX0xc,..,oONMMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMXd,..:xKNMMMMMMMMk.      .xMMMMMMMMWKx:..,dXMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMKo. 'dKWMMMMMMMMMM0' :;  ;: 'OMMMMMMMMMMWKd,..lKMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMNd.   ;OWMMMMMMMMMMK; ;0:  :0: ,KMMMMMMMMMMW0:   .dXMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMWO;..  ...:OWMMMMMMMXc '0X:  ;X0' :XMMMMMMMW0c...  ..,OWMMMMMMMMMMMM                     //
//    MMMMMMMMMMMWx. cx..d0c..:OWMMMMNo .kMX:  ;XMk. lNMMMMW0c..:Od..xl .dNMMMMMMMMMMM                     //
//    MMMMMMMMMMWd..oNO..dMWO:..:OWMWd..dWMX:  ;XMWx..dWMW0c..:OWMx..ONd..oNMMMMMMMMMM                     //
//    MMMMMMMMMWd..dWMO..dMMMWO:..c0x. lNMMX:  ;XMMNo .x0c..:OWMMMx..OMWd..oWMMMMMMMMM                     //
//    MMMMMMMMWk. lNMMO..dMMMMMWO:... :XMMMX:  ;XMMMXc ...:OWMMMMMx..OMMWo .kWMMMMMMMM                     //
//    MMMMMMMMX; ;XMMMO..dMMMMMMMWx.  ;OWMMX:  ;XMMW0;  .dWMMMMMMMx..OMMMX: ;KMMMMMMMM                     //
//    MMMMMMMWx..xMMMMO..dMMMMMMMNc .;..:OWX:  ;XWOc..;. cXMMMMMMMx..OMMMMk..dWMMMMMMM                     //
//    MMMMMMMX: ,KMMMMO..dMMMMMMWo .kW0:..ck:  ;kc..:ONk. lNMMMMMMx..OMMMMX; ;KMMMMMMM                     //
//    MMMMMMMO. cNMMMMO..dMMMMMWd..dWMMWO:..    ..:OWMMWd..dWMMMMMx..OMMMMWc .OMMMMMMM                     //
//    MMMMMMMk. lWMMMMO..dMMMMWk. lNMMMMMWO:.   ,OWMMMMMNl .kWMMMMx..OMMMMWo .kMMMMMMM                     //
//    MMMMMMMk. lWMMMMO..dMMMM0, :XMMMMMMMMX:   .cOWMMMMMX: 'OMMMMx..OMMMMWl .kMMMMMMM                     //
//    MMMMMMM0, :NMMMMO..dMMMK; ,KMMMMMMMMMX:  ':..:OWMMMMK; ;KMMMx..OMMMMN: '0MMMMMMM                     //
//    MMMMMMMNl '0MMMMO..dMMNc 'OMMMMMMMMMMX:  :K0:..:OWMMMO' cXMMx..OMMMM0' lNMMMMMMM                     //
//    MMMMMMMMO. oWMMMO..dMNo .xWMMMMMMMMMMX:  ;XMWO:..:OWMWx. lNMx..OMMMWo .OMMMMMMMM                     //
//    MMMMMMMMNl .OMMMO..dWx..dWMMMMMMMMMMMX:  ;XMMMWO:..:OWWd..dWx..OMMMO. lNMMMMMMMM                     //
//    MMMMMMMMMK; ;KMMO..dO. lNMMMMMMMMMMMMX:  ;XMMMMMWO:..:0Xl .kx..OMMK; ;KMMMMMMMMM                     //
//    MMMMMMMMMM0, ;KMO..c, :XMMMMMMMMMMMMMX:  ;XMMMMMMMWO:..cxc ,l..OMK; ,0MMMMMMMMMM                     //
//    MMMMMMMMMMM0; 'OO.   ,0MMMMMMMMMMMMMMX:  ;XMMMMMMMMMWO:..,.   .O0, ,0MMMMMMMMMMM                     //
//    MMMMMMMMMMMMKc .:.  .OWMMMMMMMMMMMMMMX:  ;XMMMMMMMMMMMWO:.    .:. cKMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMNx'   .xWMMMMMMMMMMMMMMMX:  ;XMMMMMMMMMMMMMWO:.    .xNMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMXo. .xXMMMMMMMMMMMMMMMX:  ;XMMMMMMMMMMMMMMMXc  .lXMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMWKo'.'lONMMMMMMMMMMMMX:  ;XMMMMMMMMMMMMNOl'.'oKWMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMXx:..'lxKNMMMMMMMMX:  ;XMMMMMMMMNKkl,..:xXMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMMMWKxc'..,coxOKXNWX:  ;KWNXK0xoc,..'cxKWMMMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMN0xl:'....',,.  .,,'....';lx0NMMMMMMMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0Oxolcccccclodk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                     //
//                                                                                                         //
//                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MUNDY is ERC721Creator {
    constructor() ERC721Creator("Sean Mundy - Select 1 of 1 NFTs", "MUNDY") {}
}
