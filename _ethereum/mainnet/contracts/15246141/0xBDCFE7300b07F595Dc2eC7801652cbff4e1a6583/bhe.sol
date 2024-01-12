
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: bluehawk editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//                 /         //
//    \\\' ,      / //       //
//     \\\//    _/ //'       //
//      \_-//' /  //<'       //
//        \ ///  >   \\\`    //
//       /,)-^>>  _\`        //
//       (/   \\ / \\\       //
//             //  //\\\     //
//            ((`            //
//                           //
//                           //
///////////////////////////////


contract bhe is ERC721Creator {
    constructor() ERC721Creator("bluehawk editions", "bhe") {}
}
