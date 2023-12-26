// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: z3us
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//                 .oooo.                            //
//               .dP""Y88b                           //
//      oooooooo       ]8P' oooo  oooo   .oooo.o     //
//     d'""7d8P      <88b.  `888  `888  d88(  "8     //
//       .d8P'        `88b.  888   888  `"Y88b.      //
//     .d8P'  .P o.   .88P   888   888  o.  )88b     //
//    d8888888P  `8bd88P'    `V88V"V8P' 8""888P'     //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract z3us is ERC1155Creator {
    constructor() ERC1155Creator("z3us", "z3us") {}
}
