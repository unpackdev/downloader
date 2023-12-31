// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reded 1/1s
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@%%%%%%%@@@%%@@@@%@@@@@@@@%%%%@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%@@@@@%%%@@%%%%%%%%@@@@@@@@@@@@@@@@%%@@%@@%%%%@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%@@%%%%%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@@%%%%%%%@@@@@@    //
//    @@@@@@@@@@@@@@@@@%%@@@%%%%%%%%%%%%%%%%%%@@@@@%%%%%%%%%%%%%@@%%%%%@@@@@@@@@@@%%%%%%%%%@@@@@    //
//    @@@@@@@@@@@@@@@@%%@@@@%%%%%%@@%%%%###%%%@@%@%%%%%%%%%%%%%@@@@%%%@@@%%%%%%%%%%%%%%%%@@@@@@@    //
//    @@@@@@@@@@@@@@@@%%@@%@%%%@@@@%%##*####%@@%%@%%%%%%%%%%%%%%%%%%%%%%@%%%%%@@@@@%%%%%@@@@@@@@    //
//    @@@@@@@@@@@%%@@@@@@@%%%%%%%%%%%#####%%%%%%%%##%%%@%%#####%%%%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@%%%%%%%%@@@%%%%%%%%%%%%###%%@%%%%%%###%%@%%#######%%%%@@@@@@%%@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@%%%%%%%%%%%%%%%%%%%%####%%@@@%###%#****##########%%%%@@@@%#%@%%%%%%%%@@@@@@%@@@@    //
//    @@@@@@@@@@@@@@@%%%%%%%%%%%%%#%%#%%%%%%%###+****+++****##*##%%%%%@@@#*%%%%%%%%@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@%%%@%%%%%%%%%%%%%%%%%%###*+++++***########%%%%%%@@##%%%%%%%%@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@%%#%%%%%%#%#%%%%%%##*+++*****######%%%%%%%@@@%##%%%%%%%%@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%#%%%%%%%###********######%%%%%%%@@#%%%@@%%@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@%@@%%%%%%##%%%%%%%%###******#####%%%%%%%%@@@@%%%@@@@@@@%@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@%@@%@@@@%%#%%%%%%%%%%###########%%%%%%%@%@@@@@%@@@@@@@@%@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%####%#%%%%@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@%%%@@@@%%%%%%%%#%#%%@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@%*++**#%%@%@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%#%%%@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@#%@@@@@@@@@@@@@%%%%@%@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@%###%@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@#*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@**%@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@%%*%@@@@@@@@@@@@@@@@@@@@@@@@@@@%#@@@@@@@@@@@@@@@@@@%@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#*#@@@%#%@%%@@@@@@@@@@@@@@@@@@*%@@@@@@@@@@%@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%###@%###%%#%%@@@@@@@@@@@@@@%*#@@@@@@@@@@%%@@@@@@@%@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@%%%#%%%@@@@%%%%%%@%#*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%###%%%%#%##%%%%%%@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%###%%%%%#%%%@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@%@%@@@@@@@@@@@@@%%%%%@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%@@@@@%@@@@@@@@%%@@@@%%@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@%%%@@@%%%%%@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@%@%%@@@@%%%%%%%@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@%%%%%@@%%@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%@@@%@%@@@@@%%%%%%%%%%%%@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@%%@%%@@@%%%%%%%%%%@%@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@%@@%%@%%%%%%@@@@@%###%@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@%%%@@@@@@@@@@@@@@@%@@@@@@@@%@@@%%%%@%@@@@@@@%%%%@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@%%%@%%@@@@@@@@@@@@%@@@@@@@%@@@@@@@@@@@@@@@@@%##%@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@%%%#%@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@%%@@@@%@@@@@@@@@@@@@@@%@@@@@@@@%%%%%@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@%%@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@%%%@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@%%@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@%%@@%@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract RO is ERC721Creator {
    constructor() ERC721Creator("Reded 1/1s", "RO") {}
}
