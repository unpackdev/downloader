
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ArtFromAbove's IslandTreasures
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    ╭━━━╮╱╭╮╭━━━╮╱╱╱╱╱╱╱╭━━━┳╮               //
//    ┃╭━╮┃╭╯╰┫╭━━╯╱╱╱╱╱╱╱┃╭━╮┃┃               //
//    ┃┃╱┃┣┻╮╭┫╰━━┳━┳━━┳╮╭┫┃╱┃┃╰━┳━━┳╮╭┳━━╮    //
//    ┃╰━╯┃╭┫┃┃╭━━┫╭┫╭╮┃╰╯┃╰━╯┃╭╮┃╭╮┃╰╯┃┃━┫    //
//    ┃╭━╮┃┃┃╰┫┃╱╱┃┃┃╰╯┃┃┃┃╭━╮┃╰╯┃╰╯┣╮╭┫┃━┫    //
//    ╰╯╱╰┻╯╰━┻╯╱╱╰╯╰━━┻┻┻┻╯╱╰┻━━┻━━╯╰╯╰━━╯    //
//    - Cynthia                                //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract AFA is ERC721Creator {
    constructor() ERC721Creator("ArtFromAbove's IslandTreasures", "AFA") {}
}
