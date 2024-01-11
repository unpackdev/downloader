
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Favorite Fictional Characters
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//          ___           ___           ___         //
//         /\  \         /\  \         /\  \        //
//        /::\  \       /::\  \       /::\  \       //
//       /:/\:\  \     /:/\:\  \     /:/\:\  \      //
//      /::\~\:\  \   /::\~\:\  \   /:/  \:\  \     //
//     /:/\:\ \:\__\ /:/\:\ \:\__\ /:/__/ \:\__\    //
//     \/__\:\ \/__/ \/__\:\ \/__/ \:\  \  \/__/    //
//          \:\__\        \:\__\    \:\  \          //
//           \/__/         \/__/     \:\  \         //
//                                    \:\__\        //
//                                     \/__/        //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract FFC is ERC721Creator {
    constructor() ERC721Creator("Favorite Fictional Characters", "FFC") {}
}
