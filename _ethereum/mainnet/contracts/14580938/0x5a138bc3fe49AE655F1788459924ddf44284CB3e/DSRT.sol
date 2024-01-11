
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Deserted
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     ____  ____  ____  ____  ____  ____     //
//    (  _ \( ___)(_   )( ___)(  _ \(_  _)    //
//     )(_) ))__)  / /_  )__)  )   /  )(      //
//    (____/(____)(____)(____)(_)\_) (__)     //
//                                            //
//                                            //
////////////////////////////////////////////////


contract DSRT is ERC721Creator {
    constructor() ERC721Creator("Deserted", "DSRT") {}
}
