// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Web3 Art & Coffee
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXKKK000OOOOOOOOOOOOOO000KKKXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXK00OOOOOOOOOOkkOOOOOOOOOOkkkOOOOOOOOO00KXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK0OOOOOOOkdolc;;,''ckOOOOOOOOkc'',;;:lodkOOOOOOO0KXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OOOOOOOOOOOl.        ,xOOOOOOOOk,        .lOOOOOOOOOOO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWNX0OOOOOOOOOOOOOOOc.        ,xOOOOOOOOk,         :kOOOOOOOOOOOOOO0KNWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNX0OOOOOOOOOOOOOOOOOOc.        .looooooooo'         :kOOOOOOOOOOOOOOOOO0KNWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWXKOOOOOOOOOOOOOOOOOOOOk:                              ;kOOOOOOOOOOOOOOOOOOOO0XWWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNX0OOOOOOOOOOOOOOOOOkxo:,..                               .,:ldkOOOOOOOOOOOOOOOOO0KNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNK0OOOOOOOOOOOOOOOOxl;'.                                        .';lxkOOOOOOOOOOOOOOO0KNWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWX0OOOOOOOOOOOOOOkxc,.                                                .,cdkOOOOOOOOOOOOOO0KNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWX0OOOOOOOOOOOOOOxl,.                                                      .,lxkOOOOOOOOOOOOO0XWMMMMMMMMMMMM    //
//    MMMMMMMMMMWNKOOOOOOOOOOOOOkd:.                                                            .:dkOOOOOOOOOOOOO0NWMMMMMMMMMM    //
//    MMMMMMMMMWX0OOOOOOOOOOOOkd;.                        ..,;'                                   .;okOOOOOOOOOOOO0XWMMMMMMMMM    //
//    MMMMMMMMWKOOOOOOOOOOOOOd;.                      .,:oxkOd'        .,;:;,.                      .;dkOOOOOOOOOOOOKNMMMMMMMM    //
//    MMMMMMMN0OOOOOOOOOOOOxc.                     .,lxkOOOOx,       .lxOOOOkxl;.                     .:xOOOOOOOOOOOO0NMMMMMMM    //
//    MMMMMMN0OOOOOOOOOOOko'                     .:dkOOOOOOkc       .dOOOOOOOOOOxc.                     'okOOOOOOOOOOO0XWMMMMM    //
//    MMMMMN0OOOOOOOOOOOkc.                    .:xOOOOOOOOOd.      .lOOOOOOOOOOOOOx:.                    .ckOOOOOOOOOOO0XWMMMM    //
//    MMMMN0OOOOOOOOOOOx;                     ,dkOOOOOOOOOk:      .;kOOOOOOOOOOOOOOOd,                     ;xOOOOOOOOOOO0NMMMM    //
//    MMMN0OOOOOOOOOOOx,                    .:xOOOOOOOOOOOd'     .;oOOOOOOOOOOOOOOOOOkc.                    ,dOOOOOOOOOOO0NMMM    //
//    MMWKOOOOOOOOOOOx,                    .lkOOOOOOOOOOOOl.     'oxOOOOOOOOOOOOOOOOOOkl.                    ,dOOOOOOOOOOOKWMM    //
//    MWXOOOOOOOOOOOx;                    .lkOOOOOOOOOOOOOc      ;xkOOOOOOOOOOOOOOOOOOOOo.                    ,xOOOOOOOOOOOXWM    //
//    MN0OOOOOOOOOOkc.                   .ckOOOOOOOOOOOOOk:      :kkOOOOOOOOOOOOOOOOOOOOOl.                    :kOOOOOOOOOO0NM    //
//    WXOOOOOOOOOOOo.                    :kOOOOOOOOOOOOOOk:      :kkOOOOOOOOOOOOOOOOOOOOOk:                    .lOOOOOOOOOOOKW    //
//    N0OOOOOOOOOOx;                    'dOOOOOOOOOOOOOOOOc      ;xkOOOOOOOOOOOOOOOOOOOOOOx'                    ,xOOOOOOOOOO0N    //
//    XOOOOOOOOOOOo.                   .ckOOOOOOOOOOOOOOOOo.     'lxOOOOOOOOOOOOOOOOOOOOOOOl.                   .lOOOOOOOOOOOX    //
//    KOOOOOOOOOOk;                    .dOOOOOOOOOOOOOOOOOx'     .'lOOOOOOOOOOOOOOOOOOOOOOOx'                    ;kOOOOOOOOOOK    //
//    0OOOOOOOOOOd'                    ;kOOOOOOOOOOOOOOOOOkc       ,xOOOOOOOOOOOOOOOOOOOOOOko:;;;;;;;;;;;;;;;;;;;lkOOOOOOOOOO0    //
//    0OOOOOOOOOOo.                    cOOOOOOOOOOOOOOOOOOOx'       :kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOl.                   .lOOOOOOOOOOOOOOOOOOOOl.      .lkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOl.                   .oOOOOOOOOOOOOOOOOOOOOkc.      .oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOl.                   .lOOOOOOOOOOOOOOOOOOOOOk;       'dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOl.                   .lOOOOOOOOOOOOOOOOOOOOOOx,       ;xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0OOOOOOOOOOd.                    :kOOOOOOOOOOOOOOOOOOOOOOd.      .lOOOOOOOOOOOOOOOOOOOkddddddddddddddddddddxkOOOOOOOOOOO    //
//    KOOOOOOOOOOx,                    ,xOOOOOOOOOOOOOOOOOOOOOOkc       ,xOOOOOOOOOOOOOOOOOk;....................;xOOOOOOOOOO0    //
//    XOOOOOOOOOOOc.                   .lOOOOOOOOOOOOOOOOOOOOOOOd.      .oOOOOOOOOOOOOOOOOOo.                    :kOOOOOOOOOOK    //
//    N0OOOOOOOOOOd'                    ;xOOOOOOOOOOOOOOOOOOOOOOk;       cOOOOOOOOOOOOOOOOk:                    .dOOOOOOOOOO0X    //
//    WKOOOOOOOOOOkc.                   .lOOOOOOOOOOOOOOOOOOOOOOOc.      :kOOOOOOOOOOOOOOOo.                    :kOOOOOOOOOOKN    //
//    MX0OOOOOOOOOOx,                    'dOOOOOOOOOOOOOOOOOOOOOOc..     ;kOOOOOOOOOOOOOOd'                    'xOOOOOOOOOOOXW    //
//    MWKOOOOOOOOOOOd.                    ,xOOOOOOOOOOOOOOOOOOOOOc.      ;kOOOOOOOOOOOOOx;                    .oOOOOOOOOOOOKWM    //
//    MMN0OOOOOOOOOOOl.                    ,xOOOOOOOOOOOOOOOOOOOk:.      :kOOOOOOOOOOOOx;                    .lkOOOOOOOOOO0NWM    //
//    MMWX0OOOOOOOOOOkl.                    ,dOOOOOOOOOOOOOOOOOOx'      .lOOOOOOOOOOOOx,                    .ckOOOOOOOOOOOXWMM    //
//    MMMWXOOOOOOOOOOOkl.                    .lkOOOOOOOOOOOOOOOOl.      'xOOOOOOOOOOko.                    .lkOOOOOOOOOOOKWMMM    //
//    MMMMWKOOOOOOOOOOOOo'                    .;dOOOOOOOOOOOOOOx,       ckOOOOOOOOOx:.                    .okOOOOOOOOOOOKWMMMM    //
//    MMMMMWKOOOOOOOOOOOOx;.                    .:dkOOOOOOOOOOk:       'dOOOOOOOOxc.                     ;dOOOOOOOOOOOOKWMMMMM    //
//    MMMMMMWXOOOOOOOOOOOOkl.                     .;okOOOOOOOkc.      .lOOOOOOko;.                     .lkOOOOOOOOOOOOKWMMMMMM    //
//    MMMMMMMWX0OOOOOOOOOOOOx:.                      ':odxxdc'        :kOOOxo:'.                     .:dOOOOOOOOOOOO0XWMMMMMMM    //
//    MMMMMMMMWN0OOOOOOOOOOOOOd;.                       ...          ,ooc:,.                       .;dkOOOOOOOOOOOO0XWMMMMMMMM    //
//    MMMMMMMMMMWK0OOOOOOOOOOOOkd:.                                   .                          .;okOOOOOOOOOOOOOKNMMMMMMMMMM    //
//    MMMMMMMMMMMWN0OOOOOOOOOOOOOOxc'                                                          'cdkOOOOOOOOOOOOO0XWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWX0OOOOOOOOOOOOOOko:.                                                    .:okOOOOOOOOOOOOOO0XWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNK0OOOOOOOOOOOOOOOko:'.                                            .':okOOOOOOOOOOOOOOO0KNWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWNX0OOOOOOOOOOOOOOOOkxl:'.                                    .':ldkOOOOOOOOOOOOOOOO0KNWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWX0OOOOOOOOOOOOOOOOOOOxdl'                              'coxkOOOOOOOOOOOOOOOOOO0XWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWNK0OOOOOOOOOOOOOOOOOOOc         .,,,,,,,,,,.         :OOOOOOOOOOOOOOOOOOO0KXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWNXK0OOOOOOOOOOOOOOOOc.        ,xOOOOOOOOk,         :kOOOOOOOOOOOOOOO0KXNWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWWXK0OOOOOOOOOOOOOc.        'xOOOOOOOOk,         :kOOOOOOOOOOOO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OOOOOOOOOd:,'...   ,xOOOOOOOOk;   ....,:dOOOOOOOOO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKK0OOOOOOOkkxdolldkOOOOOOOOkdllodxkkOOOOOOO00KXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXKK000OOOOOOOOOOOOOOOOOOOOOOOOO00KKXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXKKK00OOOOOOOOOOOO000KKXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract W3AC is ERC1155Creator {
    constructor() ERC1155Creator("Web3 Art & Coffee", "W3AC") {}
}
