// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE LAST KUROMATSU GARDEN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//                                                               //
//     _  ___   _ ____   ___  __  __    _  _____ ____  _   _     //
//    | |/ | | | |  _ \ / _ \|  \/  |  / \|_   _/ ___|| | | |    //
//    | ' /| | | | |_) | | | | |\/| | / _ \ | | \___ \| | | |    //
//    | . \| |_| |  _ <| |_| | |  | |/ ___ \| |  ___) | |_| |    //
//    |_|\_\\___/|_| \_\\___/|_|  |_/_/   \_|_| |____/ \___/     //
//                                                               //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract KUROMATSU is ERC721Creator {
    constructor() ERC721Creator("THE LAST KUROMATSU GARDEN", "KUROMATSU") {}
}
