// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trolley Troubles
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//        (o)__(o)()_()     .-.    W  W   W  W    wWw  wWw  wWw    (o)__(o)()_()     .-.     wWw  wWw  ___    W  W    wWw   oo_        //
//        (__  __)(O o)   c(O_O)c (O)(O) (O)(O)   (O)_ (O)  (O)    (__  __)(O o)   c(O_O)c   (O)  (O) (___)__(O)(O)   (O)_ /  _)-<     //
//          (  )   |^_\  ,'.---.`,  ||     ||     / __)( \  / )      (  )   |^_\  ,'.---.`,  / )  ( \ (O)(O)   ||     / __)\__ `.      //
//           )(    |(_))/ /|_|_|\ \ | \    | \   / (    \ \/ /        )(    |(_))/ /|_|_|\ \/ /    \ \/  _\    | \   / (      `. |     //
//          (  )   |  / | \_____/ | |  `.  |  `.(  _)    \o /        (  )   |  / | \_____/ || \____/ || |_))   |  `.(  _)     _| |     //
//           )/    )|\\ '. `---' .`(.-.__)(.-.__)\ \_   _/ /          )/    )|\\ '. `---' .`'. `--' .`| |_))  (.-.__)\ \_  ,-'   |     //
//          (     (/  \)  `-...-'   `-'    `-'    \__) (_.'          (     (/  \)  `-...-'    `-..-'  (.'-'    `-'    \__)(_..--'      //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TTS is ERC721Creator {
    constructor() ERC721Creator("Trolley Troubles", "TTS") {}
}
