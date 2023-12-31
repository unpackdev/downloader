// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ODP Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    ▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓███████████▓▓▓▓▓█████████████▓▓▓███▓▓████▓█▓▓▓█████▓▓▓▓▓███▓▓█▓▓▓▓▓    //
//    ▓▓▓██▓▓▓▓▓▓▓██▓▓████▓▓▓▓▓▓█▓▓▓█▓▓▓▓▓█▓▓██▓█████▓▓▓▓█▓▓▓▓▓▓▓████▓█████▓▓██▓▓▓▓▓███▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓█▓▓▓▓███▓▓▓▓█████████▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓█▓▓▓▓▓▓██▓▒▓    //
//    ▓▓▓▓█▓▒▓▓▓▓▓▓█▓█████████▓▓▓▓▓▓█▓███▓▓████████▓▓█▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓█▓▓▓▓█▓████▓▓▓▓▓▓▓█▓█▓▓▓▓    //
//    ██▓██▓▓█▓▓▓▓████████████████▓▓████████████████▓▓▓▓████▓▓██▓████▓██▓▓▓▓▓▓███▓▓▓▓█▓▓▓▓▓▓▓▓▓▓    //
//    █▓▓██▓▓▓▓▓████████████▓█████▒▒▒▓▓▓▓█████████████▓████████████▓▓▓█▓▓▓▓▓▓▓████▓██████▓▓▓▓█▓▓    //
//    █▓▓█▓▓████▓████████████▓▓▒▒▒▒▓▓▓█████████████████████████████████▓▓▓▓▓████████▓█▓▓█▓▓▓█▓█▓    //
//    ███▓▓▓▓█████▓██▓███▓▓▒▒░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒█████▓▒██▓▓▓██▓▒▓██████▓▓▓▓█▓▓▓▓▓▓████▓▓▓▓▓▓▓    //
//    ██▓▓▒█████████▓▓▓▒░░░░░░▒░░░░░░░░░░░░░░░░░░░░▒▒▓▓██▓▓██▓▒▒▓█▓▓█████▓▓▒▓▓███████▓██▓██▓▓▓▓█    //
//    ███▓████████▓▒▒▒░░░░▒▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒░░░░░░▒▓▓▒▒▒▓█▓▓▒▒▓███▓▓██████▓█▓▒▓▓█████████▓▓    //
//    ██████████▓▒▒░░░░▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒░░░░░▒▒▒▓███▓▓███▓▓█████▒▒█▓▓▓▓███████▓▒▒▓    //
//    ████████▓▒▒▒▒▒▒▒▒▒▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒░░░▒░░░▒▒▒▒▓▒▒▒▒▒▒░░░░░░░▒▓▓▓▓▓▓█████████████████████▒▓██    //
//    ██████▓▒▒▒▒▒▒▓▒░░░▒▓▓▓▒▒░░░░░░░░░░░░░░░░░▒░░▒▒▒▓▓▓▓▒▒░░░░░▒░▒▓██▓▓██████▓███▓▓████████████    //
//    █████▓▒▒░▒▒▒▓▒▒░░▒▓▓▓▓▓▓▒▒░░░▒░░░▒▒▒░░░░░░░░░░░░░▒▒▓▓▓▒░░░░░░░▒▓▓▓██████▓▒▓█▓▓████████████    //
//    ███▓▒▒▒░▒▒▓▒▒░░░░▒▓▓▒▒▒▓▓▓▓▒▒░░░░░░░░░▒░░░▒░░░░░░░░▒▓▓▓▓▓▒░░░░░▓███▓▒▒▓███▓▓██████████████    //
//    █▓▒░░░▒▒▒▓▒░░░▒▒▓▓▓▓▓░░░▒▓▓▓▓▓▒░░░▒░░░░░░░░░░░░░░░░░░▒▒▓▓▓▒░░░░▓██▒░▒▓▓██▓▒███▓▒▓█████████    //
//    ▒░░▒▒▒▒▓▒░░░▒▒▓▓▒▓▓▒▒░░░░░▒▒▓▓▓▒▒░░▒░░░░░░▒▒▒░░░░▒▒▒░░░▒▓▓▓▒▒░░░▒▓█▓▓▓███████▓▓▓▓█████████    //
//    ░░░░▒▒▓▒▒▒▒▒░░▒▒▒▓▒░░░░░░▒░▒▒▒▓▓▒░░░░░░░░░▒▒▓▓▒▓▒▓▓▓▓▒▒░░▒▒▓▓▒▒░░░▒██████████▓▓███████████    //
//    ░░▒▒▓▓▓▓▓▓▒▒▒▒▒▓▓▒░░░░░▒░▒░░░▒▒▓▓▒░░░░░░░░▓▓▓▒▒▒▒▒▒▓▓▓▓▓▒░▒▓▓▓▓░░░▓▓██████████████████████    //
//    ▒▒▒▓▓▓▓▓▓▒░▒▒▓▒▒░░░░░░░▒░░░░░░▒▒▓▓▓▒░░░░░▒▓▓▓▒░░░▒▒▒░░▒▓█░░▒▓▓▒▓░░░░▒▒▓▓██████████████████    //
//    ▒▒▓▓▓▓▒▒▒░▒▓▓▓▒▒░░░░░░░░░░▒▒▒▒▒▓▓▓▓▓▒░░░░░▒▒▓▒▒░▓▓▓▓▓▓▒▒▓▒░░░░▒▓▒░░▒░░░░░▓████████████████    //
//    ▒▒▒▓▒▒▒░░▒▓▓▓▓▓▓▒░▒▒░▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░▒▓▒▒░▒▓▓▓▓▓▓▓▓▒▒░░░▒▓▓▒░░░░░░░▒████████████████    //
//    ░░▒▒░░░░░▒▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▒░░▒▓▓▒▒▒▓▓▒▒░░░▒▓▒░░░▓▓▓▓▓▒▒▓▓▒░░▒▒▓▓▒▒▒░░░░▓████████████████    //
//    ░░░░░░░░░▒▒▒░░░░░░░░▒░░░░░▒▓▒▒▒▓▓▓░░░▒▓▓▓▒░░▒▒▒░░░▒▒▒▒▒░░░▓▒▒░▒▒▓▓▓░░░░░░▒████████████████    //
//    ░░░░░░░░░░░░░▒▒▒▒▒░░░▒░░░░░▒▓▓▒▓▓▒░░░░░▓▓▓▒░░▒▒▒░░░▒▒░▒▒▒▓▓▓▒░▒▒▓▓▓▒░░░░░▒████████████████    //
//    ░░░░░░░░░░░░░▒▓▓▓▓▓▒▒▓▒░░░░▒▓▓▓▓▒░░░░░░▒▓▓▓▒░░▓▓▓▒▓▓▒▒▒▒▒▒▒▒░░░░▒▓▓▒░░░░▒▓███████████████▒    //
//    ░░░░▒▒░░░░░░░▓▓▒░▒▓▓▓▓▓▓▒░░▒▓▓▓▓▒░░░░░░░░▓▓█▒░░▒▒░░░░░░░░░░░░░░▒▓▓▓▓▒▒░░▓████████▓▓▓████▓▒    //
//    ░░░▒▓▓▓▒▒░░░▒▒▓▒░░░▒▓▓▓▓▓▒░▒▓▓▓▒▒░░░░░▒▒░▒▓▓█▒░▒▒░░░░░░░░░░░░░░▒▓▓▓▓░░░▒▓▓▓▓▓█████▓▓▒█████    //
//    ▒▒░░▒▓▓▓▓▓▒▒▒▓▓▒░░▒▓▓▓▓▓▓▒░░▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▒▒░░░░░░░░░░░░░░░░▒▓▓▓░░░░▒▒░░░▒█████████████    //
//    ▓▓▒▒▒▓▓▓▒▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓░░░░░▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▒░░░░░░░░░░▒░░░▒▓▓▒▒░░░▒▒░░░▒█████████████    //
//    ▓▓▓▓▓▓▓▒░░░▒▓▓▓▓▓▓▓▓▓▒▒▒▒░░░░░░░░░▒▒▒▒░▒░░▒▓▓▓▓▓▒░░░░░░░░░░░░▒▒▓▓▒▒░░░░░░░░░░▒▒░░░░▒▒▓▓▒▒▒    //
//    ▓▓▓▓▓▓▓▒░░░░░▒▓▓▓▓▓▓▓▓▓▒▒░░░░░░░░▒▓▓▓▒▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░▒░▒▒▓▓▓▓▒▒▒▒▒▒▒▒░▒░░░░░░░░░░░░░░    //
//    ░▓▓▒▒▓▓▓▒░░░░▒▓▓▓▓▒▓▓▓▓██▓▒░░░░░▒▒▓▓▒░░▒▒▒▓▓▓▓▒▓▒░░░░░░░░▒▒▒░▒▒▓▓▓▓▒▒▓▓▒░░▒░░░░░░▓▓▒▒▒▒▒▒▒    //
//    ░▓▓▒░░▒▓▓▒░░░░▒▓▓▒░░▒▓▓▓▓██▓░░░▒▓▓▒▒░░░░▒▓▓▓▓▒▒▒░░░░░░░░░░░░▒▒▓▓▓▓▓▓▓▓▓▒░░░░░░▒▒▓▓▓▓▓▓▓▓▓▓    //
//    ░▒▓▒░░░▒▒▓▓░░░▒▒░░░░░░▒▒▓▓▓▓▒░▒▓▓▒░░▒▒▓▓▓▓▓▒▒▒▒▒░░░░▒░░░▒▒░░▒▓▓▓▓▓▒▒▒▒▒░░░▒░░▒▓▓▓▓▓▓▓▓▓▒▒▒    //
//    ░░▒▓▒░░░░▒▒▒▒░░░░░░░▒░░░▒▒▒▓▓▓▓▓▓▒▓▒▒▒▓▒▒░░░░░░░░░░░░░░░░▒░▒▓▓▓▓▒▒▒░░░░▒▒▒░▒▒▓▓▒▒░▒▓▓▒▒░░░    //
//    ▒░░▓▓▓▒░░░░▒▓▓▒░░░░░░░░▒▒░▒▓▓▓▓▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▒▒▒░░░░░░▒▓▒▓▓▓▒░░░▒▓▓▒▒▒▒▒▓    //
//    █▒░░▒▓▓▓▓▒▒░▒▓▒▒▒▒▒▒▓▓▓▓▓▓▓▒▒▒▒░░░░░░░▒░░░░░░░░░░▒░░░░░░▒▓▓▓▓░░▒▓▓▒▒▒▒░░▒▓▓░░░░▒▓▓▓▒▓▓▓▓▓▓    //
//    ██▓░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▓▓▓▓▒▒░░░▒▒▓▓▓▓▓▓▓█▓░▒▓▓▓▒▒░░░░░▒▒▒▒    //
//    ███▓▒░░░▒▓▓▓▓▓▓▒▒░░░░░░▒▒▒░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓▓▒▒▒▒░░░░░░▒▓████▓▓▓▓▒▒▒▒░░░░░░░░░░░░    //
//    ██████▒░░░▒▒▓▓▓▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▒▒░░░░░░░▒▒▓███▓▓░▒▒░░░░░░░░░░░░░░░▒▒▒░    //
//    ████████▒░░░░░▒▓▓▓▓▓▓▒▒░░░░░░░▒░░░░░░░░▒▒▓▒▒▒▓▒▒▒▒░░░░░░▒▓▓▒▓███▒▒▒░░▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒░▒▒▓▓▒    //
//    ▓████████▓▒░░░░▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▓▒▒░▒▒▓▒▓▓▓▓▓▓▒░░▒▒▒▒▒▓▓██▓▒▓████████████████████████▒▒▒▒▒▒    //
//    ████████████▓██▓▓▒░░▒▒▒▓▓▒▒▒▒▓▒▓▓▒▒▒▒▒▒▒▒▒▒░░▒▒▒██████████████████████▓▓████████████████▓▒    //
//    ████████████████████████▓▓▓████████████████████████████▓▓▒▒▓██████████▓▓████▓▓▓█████████▒▒    //
//    ███████████████████████████████████████████████████████▓▓▓▓███████████████████████████████    //
//    ██████████████████████████████████████████████████████████████████████████████████████████    //
//    ██████████████████████████████████████████████████████████████████████████████████████████    //
//    ███████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████████    //
//    ███████████████████████████████████▓▓▓▓████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓▓▓▓▓▓███████    //
//    ███████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████▓▓▓▓▓▓▓    //
//    ████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████▓▓▓▓▓▓    //
//    ████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓█████▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ███████████████████████████████████████████████████████████▓▓▓▓███████████████████████████    //
//    ██████████████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓█████████████████████    //
//    ██████████████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓███████████████████████    //
//    ████████████████████████████████████████████████████████████▓▓▓███████████████████████████    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract ODPx is ERC1155Creator {
    constructor() ERC1155Creator("ODP Editions", "ODPx") {}
}
