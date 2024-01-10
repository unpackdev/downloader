
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NeuroscienceNFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//           _---~~(~~-_.         //
//         _{        )   )        //
//       ,   ) -~~- ( ,-' )_      //
//      (  `-,_..`., )-- '_,)     //
//     ( ` _)  (  -~( -_ `,  }    //
//     (_-  _  ~_-~~~~`,  ,' )    //
//       `~ -^(    __;-,((()))    //
//             ~~~~ {_ -_(())     //
//                    `\  }       //
//                      { }       //
//                                //
//                                //
////////////////////////////////////


contract Neuro is ERC721Creator {
    constructor() ERC721Creator("NeuroscienceNFT", "Neuro") {}
}
