// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PSYBER
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//    .----.  .----..-.  .-..----. .----..----.     //
//    | {}  }{ {__   \ \/ / | {}  }| {_  | {}  }    //
//    | .--' .-._} }  }  {  | {}  }| {__ | .-. \    //
//    `-'    `----'   `--'  `----' `----'`-' `-'    //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract PSYBR is ERC721Creator {
    constructor() ERC721Creator("PSYBER", "PSYBR") {}
}
