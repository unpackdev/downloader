
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Suelen Tieko
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMWK00xxNWWMMMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMWWMNXWMMMMMMMMMWW0;  .cKWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMWKxdkxxKWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'     ,kWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWWXxxXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNd.       .oXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXl.          ;0WMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWK:             .xNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWO,               .lXWWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.                  ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWWWMMMMMMMMMMMMMMMW0dkNMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.                    .dNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMWMMWMWWWMMMMMMMMMMMMMWWW0:.  ;ONWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMWWK:                        :KWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    WWWXXWWWWWMMMMMMMMMMMMWMW0c.     .oXWMMMMMMMMMMMMMMMMMMMMMMMMMMMWW0,             .            'kWMWWMMMMMMMMMMMMMMMMMMMM    //
//    WWWkx0k0WMMMMMMMMMWMMWW0l.         ,kWMMMMMMMMMMMMMMMMMMMMMMMMMWWk.            ,xOl.           .oXWWMMMMMMMMMMMMMMMMMMMM    //
//    WNOdkxxXWMMMMMMMMWMMWKl.            .lKMMMMMMMMMMMMMMMMMMMMMWMMNo.   ;x:     'dXWWN0c.           ;0WWMMMMMMMMMMMMMMMMMMM    //
//    MNXXXkOWMMMMMMMMMMWKo.                ,kNMMMMWMMMMMMMMMMMWWWWWKc   .lXWXl. .oXWWMWWWWO:.    .'.   .xNWWMMMMMMMMMMMMMMMMM    //
//    MWWWWWWMMMMMMWWWWKo'                   .cKWMMMMMMMMMMMMMMMMWW0;   'xNWWWNxdKWWWWMWMMWWNO:. .xXx,   .cKWMMMMMMMMMMMMMMMMM    //
//    MMWMMMMMMMMMWWWXd'                       'xNWWMMMMMMMMMMMMWkc.   :0WWMWWMWWMMMMWMMMMWMWWNkcxNMMXd'   ,OWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWWXd'                           :0WMMMMMMMMMMWNd.   .oNMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMWXo.  .oNMWMMMMMMMMMMMMM    //
//    MMMMMMMMWWWXx'             .::.             .dNMMMMMMMMWXc.   'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWW0c.  :KWWMMMMMMMMMMMM    //
//    MMMMMWWWWNx,           .'lkXWWKd;.            ;OWWMWMMW0;   .:KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:. 'kNWWMMMMMMMMMM    //
//    MMMMWWWXx,    .'.   .;oONWWWWWWWW0o,.   ,:.    .oXWWWWO'  .dKNMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNk, .lXWWWMMMMMMMM    //
//    MMMWWNk;   .,o0Xd,:xKNMMWWMMMMMMMMMNOl',ONO:.    ;kNNd.  ,OWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNx'.;0WWWMMMMMMM    //
//    MMWNk;  .;o0NMMWNNWMWMMMMMMMMMMMMMMWWWXXWWWNk;.   .,,. .cXWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd''xNWWWMMMMM    //
//    MWO:..;d0NMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNk;      .xNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWKo'cKWWWMMMM    //
//    Oc,:d0NWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNx,   ;0WWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c:kWWWMMM    //
//    cdKWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNd;oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWOoxXMMMM    //
//    NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOkXWMM    //
//    MMWMMMMMMMMMMMWWMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMX0XMW    //
//                                                                                                                                //
//               ######  ##     ## ######## ##       ######## ##    ##    ######## #### ######## ##    ##  #######                //
//              ##    ## ##     ## ##       ##       ##       ###   ##       ##     ##  ##       ##   ##  ##     ##               //
//              ##       ##     ## ##       ##       ##       ####  ##       ##     ##  ##       ##  ##   ##     ##               //
//               ######  ##     ## ######   ##       ######   ## ## ##       ##     ##  ######   #####    ##     ##               //
//                    ## ##     ## ##       ##       ##       ##  ####       ##     ##  ##       ##  ##   ##     ##               //
//              ##    ## ##     ## ##       ##       ##       ##   ###       ##     ##  ##       ##   ##  ##     ##               //
//               ######   #######  ######## ######## ######## ##    ##       ##    #### ######## ##    ##  #######                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TIEKO is ERC721Creator {
    constructor() ERC721Creator("Suelen Tieko", "TIEKO") {}
}
