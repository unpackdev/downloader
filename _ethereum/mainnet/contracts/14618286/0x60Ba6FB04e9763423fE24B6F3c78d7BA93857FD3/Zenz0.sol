
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zenshortz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//    ┏━┓╋╋╋╋┏━┳┓╋╋╋╋┏┓┏━┓    //
//    ┣━┣━┳━┳┫━┫┗┳━┳┳┫┗╋━┃    //
//    ┃━┫┻┫┃┃┣━┃┃┃╋┃┏┫┏┫━┫    //
//    ┗━┻━┻┻━┻━┻┻┻━┻┛┗━┻━┛    //
//                            //
//                            //
////////////////////////////////


contract Zenz0 is ERC721Creator {
    constructor() ERC721Creator("Zenshortz", "Zenz0") {}
}
