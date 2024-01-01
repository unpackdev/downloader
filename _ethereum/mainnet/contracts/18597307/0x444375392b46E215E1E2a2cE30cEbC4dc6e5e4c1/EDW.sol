// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Early Digital Works (2021-2022)
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    _______________   ________  ____     //
//    \_____  \   _  \  \_____  \/_   |    //
//     /  ____/  /_\  \  /  ____/ |   |    //
//    /       \  \_/   \/       \ |   |    //
//    \_______ \_____  /\_______ \|___|    //
//            \/     \/         \/         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract EDW is ERC721Creator {
    constructor() ERC721Creator("Early Digital Works (2021-2022)", "EDW") {}
}
