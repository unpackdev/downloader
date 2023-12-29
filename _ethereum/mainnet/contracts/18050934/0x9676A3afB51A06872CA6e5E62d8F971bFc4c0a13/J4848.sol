// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Redeem Token
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//         ____.____   ____ _____    ______       //
//        |    |\   \ /   //  |  |  /  __  \      //
//        |    | \   Y   //   |  |_ >      <      //
//    /\__|    |  \     //    ^   //   --   \     //
//    \________|   \___/ \____   | \______  /     //
//                            |__|        \/      //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract J4848 is ERC1155Creator {
    constructor() ERC1155Creator("Redeem Token", "J4848") {}
}
