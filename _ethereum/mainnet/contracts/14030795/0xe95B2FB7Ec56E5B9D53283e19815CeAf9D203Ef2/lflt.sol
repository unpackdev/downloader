
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lfl test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                         //
//                                                                                                                                         //
//                                                                                                                                         //
//     ██▓    ▄▄▄       ███▄    █ ▓█████▄   █████▒▒█████   ██▀███   ██▓    ▓█████ ▄▄▄        ██████ ▓█████      ▓█████▄▄▄█████▓ ██░ ██     //
//    ▓██▒   ▒████▄     ██ ▀█   █ ▒██▀ ██▌▓██   ▒▒██▒  ██▒▓██ ▒ ██▒▓██▒    ▓█   ▀▒████▄    ▒██    ▒ ▓█   ▀      ▓█   ▀▓  ██▒ ▓▒▓██░ ██▒    //
//    ▒██░   ▒██  ▀█▄  ▓██  ▀█ ██▒░██   █▌▒████ ░▒██░  ██▒▓██ ░▄█ ▒▒██░    ▒███  ▒██  ▀█▄  ░ ▓██▄   ▒███        ▒███  ▒ ▓██░ ▒░▒██▀▀██░    //
//    ▒██░   ░██▄▄▄▄██ ▓██▒  ▐▌██▒░▓█▄   ▌░▓█▒  ░▒██   ██░▒██▀▀█▄  ▒██░    ▒▓█  ▄░██▄▄▄▄██   ▒   ██▒▒▓█  ▄      ▒▓█  ▄░ ▓██▓ ░ ░▓█ ░██     //
//    ░██████▒▓█   ▓██▒▒██░   ▓██░░▒████▓ ░▒█░   ░ ████▓▒░░██▓ ▒██▒░██████▒░▒████▒▓█   ▓██▒▒██████▒▒░▒████▒ ██▓ ░▒████▒ ▒██▒ ░ ░▓█▒░██▓    //
//    ░ ▒░▓  ░▒▒   ▓▒█░░ ▒░   ▒ ▒  ▒▒▓  ▒  ▒ ░   ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░░ ▒░▓  ░░░ ▒░ ░▒▒   ▓▒█░▒ ▒▓▒ ▒ ░░░ ▒░ ░ ▒▓▒ ░░ ▒░ ░ ▒ ░░    ▒ ░░▒░▒    //
//    ░ ░ ▒  ░ ▒   ▒▒ ░░ ░░   ░ ▒░ ░ ▒  ▒  ░       ░ ▒ ▒░   ░▒ ░ ▒░░ ░ ▒  ░ ░ ░  ░ ▒   ▒▒ ░░ ░▒  ░ ░ ░ ░  ░ ░▒   ░ ░  ░   ░     ▒ ░▒░ ░    //
//      ░ ░    ░   ▒      ░   ░ ░  ░ ░  ░  ░ ░   ░ ░ ░ ▒    ░░   ░   ░ ░      ░    ░   ▒   ░  ░  ░     ░    ░      ░    ░       ░  ░░ ░    //
//        ░  ░     ░  ░         ░    ░               ░ ░     ░         ░  ░   ░  ░     ░  ░      ░     ░  ░  ░     ░  ░         ░  ░  ░    //
//                                 ░                                                                         ░                             //
//                                                                                                                                         //
//                                                                                                                                         //
//                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract lflt is ERC721Creator {
    constructor() ERC721Creator("lfl test", "lflt") {}
}
