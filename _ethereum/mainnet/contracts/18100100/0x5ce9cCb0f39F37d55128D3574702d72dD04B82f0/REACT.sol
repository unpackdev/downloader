// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The WAGMI Reactor
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                _____              //
//               /     \             //
//              /       \            //
//        !----<    ?    >----!      //
//       /      \       /      \     //
//      /        \_____/        \    //
//      \    W   /     \   A    /    //
//       \      /       \      /     //
//        >----<    o    >----<      //
//       /      \       /      \     //
//      /        \_____/        \    //
//      \    G   /     \   M    /    //
//       \      /       \      /     //
//        V----<    I    >----V      //
//              \       /            //
//               \_____/             //
//                  V                //
//      vvvisit: oncyber.io/react    //
//                                   //
//                                   //
///////////////////////////////////////


contract REACT is ERC721Creator {
    constructor() ERC721Creator("The WAGMI Reactor", "REACT") {}
}
