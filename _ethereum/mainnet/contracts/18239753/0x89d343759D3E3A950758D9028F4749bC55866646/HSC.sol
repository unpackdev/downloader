// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Humans Since Creation
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//     _    _                                  _____ _                 _____                _   _                                                               //
//    | |  | |                                / ____(_)               / ____|              | | (_)                                                              //
//    | |__| |_   _ _ __ ___   __ _ _ __  ___| (___  _ _ __   ___ ___| |     _ __ ___  __ _| |_ _  ___  _ __                                                    //
//    |  __  | | | | '_ ` _ \ / _` | '_ \/ __|\___ \| | '_ \ / __/ _ \ |    | '__/ _ \/ _` | __| |/ _ \| '_ \                                                   //
//    | |  | | |_| | | | | | | (_| | | | \__ \____) | | | | | (_|  __/ |____| | |  __/ (_| | |_| | (_) | | | | By astrophuture>                                 //
//    |_|  |_|\__,_|_| |_| |_|\__,_|_| |_|___/_____/|_|_| |_|\___\___|\_____|_|  \___|\__,_|\__|_|\___/|_| |_                                                   //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXKK0000000000KKXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNK0kxdolc:;,,'''.......'''',,;:clodxO0KNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkxoc;,'..................................',;coxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkdc;'................................................';cdkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKko:'..........................................................':okKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo:'..................................................................':oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl;..........................................................................;lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOl,................................................................................;lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMW0d:......................................................................................:dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNOl,..........................................................................................,lONMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNkc'..............................................................................................'ckNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNk:....................................................................................................:kNMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNOc'......................................................................................................'cONMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWKl'..........................................................................................................'lKWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNx,..............................................................................................................;xXMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMW0c..................................................................................................................l0WMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNk;....................................................................................................................;kNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXd'......................................................................................................................'dXMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMKl..........................................................................................................................lKWMMMMMMMMMMM    //
//    MMMMMMMMMMMKc......................................';lddoc,................................,coddl;'......................................cKWMMMMMMMMMM    //
//    MMMMMMMMMWKc......................................:kNWMMMWKd,............................,dKWWMMWNk:......................................cKWMMMMMMMMM    //
//    MMMMMMMMWKc......................................:0WMMMMMMMNd'..........................'xWMMMMMMMW0:......................................cKWMMMMMMMM    //
//    MMMMMMMMXl.......................................cXMMMMMMMMWk,..........................,OWMMMMMMMMXc.......................................lXMMMMMMMM    //
//    MMMMMMMNo'.......................................,xNMMMMMMWKl............................lKWMMMMMMNx,.......................................'dNMMMMMMM    //
//    MMMMMMWk,.........................................'lkKXXX0d;..............................;d0XXXKkc'.........................................,kWMMMMMM    //
//    MMMMMM0:.............................................',;,'..................................',;,'.............................................:KMMMMMM    //
//    MMMMMNo........................................................................................................................................oNMMMMM    //
//    MMMMMO;........................................................................................................................................;OMMMMM    //
//    MMMMNo..........................................................................................................................................oNMMMM    //
//    MMMM0:..........................................................................................................................................:0MMMM    //
//    MMMWx'..........................................................................................................................................'xWMMM    //
//    MMMNl............................................................................................................................................lNMMM    //
//    MMMK:............................................................................................................................................:KMMM    //
//    MMM0;............................................................................................................................................;0MMM    //
//    MMMO,............................''................................................................................''............................,OMMM    //
//    MMWk'............................';................................................................................;'............................,kWMM    //
//    MMWk'............................';,..............................................................................,;'............................'kWMM    //
//    MMMk,.............................;:..............................................................................:;.............................,kMMM    //
//    MMMO,.............................'c;............................................................................;c'.............................,OMMM    //
//    MMM0;..............................;l,..........................................................................,l;..............................:0MMM    //
//    MMMXc...............................cl'........................................................................'lc...............................cXMMM    //
//    MMMNd...............................'ll'......................................................................'ll'...............................dNMMM    //
//    MMMWO,...............................,ol'....................................................................,ol'...............................,OWMMM    //
//    MMMMXc................................'ld;..................................................................;dl'................................cXMMMM    //
//    MMMMWx'.................................cdc'..............................................................'ldc.................................'xWMMMM    //
//    MMMMMKc..................................;dd;............................................................:do;..................................cKMMMMM    //
//    MMMMMWk,..................................'cxo;........................................................;ddc'..................................,kWMMMMM    //
//    MMMMMMXo....................................'lxd:...................................................':dxl'....................................oNMMMMMM    //
//    MMMMMMMK:.....................................'cxxl,..............................................,lxxc'.....................................:KMMMMMMM    //
//    MMMMMMMWO;.......................................:oxdl;'.......................................;ldxo:.......................................;OWMMMMMMM    //
//    MMMMMMMMWx,........................................':oxxoc;'..............................';coxxo:'........................................,kWMMMMMMMM    //
//    MMMMMMMMMNx'...........................................;cdxxdol:;'..................',:lodxxdl;'..........................................'xNMMMMMMMMM    //
//    MMMMMMMMMMNx,..............................................,:lodxxxdddooolllloooddddxxdol:,..............................................,xNMMMMMMMMMM    //
//    MMMMMMMMMMMNx,...................................................',;:ccllooollllc:;,'...................................................,xNMMMMMMMMMMM    //
//    MMMMMMMMMMMMWk;........................................................................................................................;OWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMW0c......................................................................................................................c0WMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWXo'..................................................................................................................,oXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNk:................................................................................................................:ONMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWXo,............................................................................................................,dKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMW0c'........................................................................................................'l0WMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNk:.....................................................................................................'ckNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNk:.................................................................................................':kNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNkc'............................................................................................'ckNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMN0o,........................................................................................,o0NMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'..................................................................................'cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:'............................................................................':d0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dc,......................................................................,cd0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKko:'..............................................................':okKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xo:,......................................................,:ok0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxoc;'..........................................';coxOXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOxol:;,'..........................',;cloxOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKOkxxddoollllllllllooddxxk0KXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HSC is ERC721Creator {
    constructor() ERC721Creator("Humans Since Creation", "HSC") {}
}
