// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evolutionis
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//    ╭━━━╮╱╱╱╱╱╭╮╱╱╱╭╮                //
//    ┃╭━━╯╱╱╱╱╱┃┃╱╱╭╯╰╮               //
//    ┃╰━━┳╮╭┳━━┫┃╭╮┣╮╭╋┳━━┳━╮╭┳━━╮    //
//    ┃╭━━┫╰╯┃╭╮┃┃┃┃┃┃┃┣┫╭╮┃╭╮╋┫━━┫    //
//    ┃╰━━╋╮╭┫╰╯┃╰┫╰╯┃╰┫┃╰╯┃┃┃┃┣━━┃    //
//    ╰━━━╯╰╯╰━━┻━┻━━┻━┻┻━━┻╯╰┻┻━━╯    //
//                                     //
//                                     //
/////////////////////////////////////////


contract Evolutionis is ERC1155Creator {
    constructor() ERC1155Creator("Evolutionis", "Evolutionis") {}
}
