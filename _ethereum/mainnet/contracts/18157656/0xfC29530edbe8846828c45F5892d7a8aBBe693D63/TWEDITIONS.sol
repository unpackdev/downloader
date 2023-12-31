// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Tara Workman
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                             //
//                                                                                                                                             //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓████▓▓▒▒▓▓█▓▒▒▒▒▒▒▒▓▓▒▒▓▓▓█▓▒▒▓▒░░░░░░░░░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░▓▓▓▓▒▓▓██▓▒░▒▓██▓▓▓▒▓▓████████▓█▒▒░░░░░░░░░░░▒░░░░░░░░░░                                               //
//    ░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▒░▒▓▓▒▒░▒▓▓█▓▓▓██▓▒█████████▓░▓█████▓▓▓▓▓▒░░░▒░░░░▓▓▓▓░░░░░░░░░░                                               //
//    ░░░░░░░░░░░░░░░░░░░░░░▓██▓▓██▓▓▓▓██████████▒▓█████████▒░▓█████▓▒▓▓▓▓▒▒▓▓▓░░░▒▓▒░░░░░▒▒▓▒░░                                               //
//    ░░░░░░░░░░░░░░░░░░░░░░░▓█████████████████████████████▓░▓██████████▓▓▓▓▓▒▒░░▒▒▒▒░░▒▓█████▓░                                               //
//    ░░░░░░░░░░░░░░░░░░░▒▓▒▓████████████████████████████▒▒░▓███████████████▓▒▒▓▒▒▒▒▒▒░░▓██████▓                                               //
//    ░░░░░░░░░░░░░░░░░░▒▒███████████████████████████████▓▓███████████████████▓▓▒▓▓▓▓▓▓░░▓█████▓                                               //
//    ░░░░░░░░░░░░░░░░░▓▒▓██████████████████████████████████████████████████▓▓▒▒▒▒▓██▓▒░░░▒█▓▒░░                                               //
//    ░░░░░░░░░░░░░▒▒▓▓█▓▓▓█████████████████████████████████████████▓█████▓▓▒▒▒▓▓▓████▓▒░░░░░░░░                                               //
//    ░░░░░░░░░░░░░▓████▓▓████████████████████████████████████████▓▒▒▓▓█▓▓▒▒▒▓▓▓████████▓█▓▓░░░░                                               //
//    ░░░░░░░░░░░░░░▒▒▓███████████████████████████████████████████▓▓▓▓███▓▓▓▓▓█████████████▓▒░░░                                               //
//    ░░░░░░░░░░░▒▒▓▓▓███████████████████████████████████████████████▓▓▓▓▓▓▓█████████████▓▓▒░░░░                                               //
//    ░░░░░░░░░░░░░▒▓███████████████████████████████████████████████████▓▓█████████████▓▓▓▓▒░░░░                                               //
//    ░░░░░░░░░░░░▓▓▒▓███████████████████████████████████████████████████████████████▓▓██▒░░░░▒▓                                               //
//    ░░░░░░░░░░░░░░▒███████████████████████████▓▒▓████████████████████████████████▓▒▓██▓▒▒░░▒▓▓                                               //
//    ░░░░░░░░░░░▒▓▓███████████▓███████████▓▓▒░░░░░░░░░▒▓▓███████████████████████▓▒▓██████▒░░░░░                                               //
//    ░░░░░░░░░░░▒▓▓▓███████▓▓▓▓██████████▓▒░░░░░░░░░░░░░░▒▓▓███████████████████▓▓█████████▒▓░░░                                               //
//    ░░░░░░░░░░░░▒▓▓▓█████▓▓▓█████████▓▓▒▒░░░░░░░░░░░░░░░░░▒▓▓▓██████████████████████████▓▒▒░░░                                               //
//    ░░░░░░░░░░░░░░▒▒██▓██████████████▓▒░░░░░░░░░░░░░░░░░░░░░▒▒▓████████████████████████▓▒▒▒▒░░                                               //
//    ░░░░░░░░░░░░░░░▒▓▒▓█████████████▓▒░░░░░░░░░░░░░░░░░░░░░░░▒▒████████████████████████████░░░                                               //
//    ░░░░░░░░░░░░░░░░░▒▓█████████████▓▒░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓███████████████████████▓█▒░░░░                                               //
//    ░░░░░░░░░░░░░░░░░░▓▓▓██████████▓▒▒▒▒▒▒▒▓▓▒▒▓██▓▒░▒▓▓▓▓▓▓▓▓▓▓██████████████████████▓▒▓▒░░░░                                               //
//    ░░░░░░░░░░░░░░░░░▒█████▓▒▒▒░░░░▒▒▒▓▓▓█▓▒▒▒▒▓███▓▓▒▓▓████▓▓▓███▒███████████████▒▓▓░▓▓░░░░░░                                               //
//    ░░░░░░░░░░░░░░░░░░▒▓░░░░░▒▒▓▓▓██▓▓▓▓▓██████████████████▓██▓███████████████████▒░░░░░░░░░░░                                               //
//    ░░░░░░░░░░░░░░░░░░▒░░░░▒█▓▓█████████████▓▓▓▓███████████▓▒▒▓███████████████████▓░░░░░░░░░░░                                               //
//    ░░░░░░░░░░░░░░░░░▒▒░░▒▓▓▒▒░░░░░░░▒████▓▓███████████████▓▒▒████████████████████▓░░░░░░░░░░░                                               //
//    ░░░░░░░░░░░░░░░░▒█░░░▓░░▒▒░░░░░░░▓███▓█████████████████▒▓▒▒▓█████████████▒▒▒▓▓▓░░░░░░░░░░░                                               //
//    ░░░░░░░░░░░░░░░▒▓▒░░▒░░░▒▒▓▓█████████████████████████▓█░░░▒▓████████████▓▓░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░░░░░░░░▒▒░░░░░░░▓██████████████████████████████░░░▒█████████████▓▒░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░░░░░░░▒░▒░░░░░░▒▓▓▒▒▓▓██████████████████████▓██▒░▒▓████████▓░░▓▒░░░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░░░░░░▒██░░░░░░░░░░░░▒░░▒████████▓▓█████████▓███▓▒▓██████▒▓▒░░░▒▓░░░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░░░░░░██▓▓░░░░░░░▒▒▓▓▓▒░░▒▓▒▒█████▓▓▓▓▓██▓▓▓█████▓█▓▓▓▓▓░░░▒░░░░░░░░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░░░░░▓██▓▒░░░░░░░▒▓▓████▓▓▓▒▒▓▓██████████████████▓▒░░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░░░░▒███▓░░░░░░░░░░░░▒▒▒▓▓▓▓▓▓█▓▓▓███████████████▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░░░░████▒░░░░░▒▓▒▒▒▒░▒▒░░▓▓▒▓▓██▓▓▓█▓▓▓▒▒▒▓▓▓▓████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░░░▒████░░░░░░▒▓░░░░░░░▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒███▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░░░████▓░░░░░▒▒▒░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░░░▒▓███▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░░▓████░░░░░▒▒▒▒░░░░░░░░░░░░▒▒░░░░▒░░░░░░░░░░░░░▓███▓▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░░████▓░░░▒░▒▒▒▓░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░█████████▓▒░░░░░░░░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░░███▒░░░░▒▓▒▓▓▓░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░▓████▒▓█▓▒███▓▒▒░░░░░░░░░░░░░░░░░░                                               //
//    ░░░░░░░░▒█▒░░░░░░░▒▓▓▓▓▒▓▓██▓░▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░▒█▓▒░░▓▓██████████▓▓▒░░░░░░░░░░░░                                               //
//    ░░░░░░░░▒░░░░░░░░▒▓███████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░▓░▓██████████████████▓▒░░░░░░░░░                                               //
//    ░░░░░░░░░░░░░░░░░▓████████████████▓▓▒▒▒▒▒▒▒░░░░░▒▒▒▒▓▓████████████████████████████▒░░░░░░░                                               //
//    ░░░░░░░░░░░░░░░░▒█████████████████████████████████████████▓█████████████████████████░░░░░░                                               //
//    ░░▒▓▓░░░░░░░░░░▒██████████████████████████████████████████▓████████████████████████▒▒░▒▒▒▒   _    _         _                   _        //
//       _    _         _                   _     ___  _          _                                                                            //
//      /_\  | |__  ___| |_  _ _  __ _  __ | |_  / __|| |_  __ _ | |_  ___                                                                     //
//     / _ \ | '_ \(_-<|  _|| '_|/ _` |/ _||  _| \__ \|  _|/ _` ||  _|/ -_)                                                                    //
//    /_/ \_\|_.__//__/ \__||_|  \__,_|\__| \__| |___/ \__|\__,_| \__|\___|                                                                    //
//                                                                                                                                             //
//                  __   __  __  _           _                                                                                                 //
//            ___  / _| |  \/  |(_) _ _   __| |                                                                                                //
//           / _ \|  _| | |\/| || || ' \ / _` |                                                                                                //
//           \___/|_|   |_|  |_||_||_||_|\__,_|                                                                                                //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TWEDITIONS is ERC1155Creator {
    constructor() ERC1155Creator("Editions by Tara Workman", "TWEDITIONS") {}
}
