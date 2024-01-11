// SPDX-License-Identifier: MIT
// Copyright (c) 2022 unReal Accelerator, LLC
pragma solidity ^0.8.9;

///////////////////////////////////////////////////////////////////////////////
//                _             _      _                                     //
//           ___ | |__    ___  (_)  __| | ___    __  __ _   _  ____          //
//          / __|| '_ \  / _ \ | | / _` |/ __|   \ \/ /| | | ||_  /          //
//         | (__ | | | || (_) || || (_| |\__ \ _  >  < | |_| | / /           //
//          \___||_| |_| \___/ |_| \__,_||___/(_)/_/\_\ \__, |/___|          //
//                                                      |___/                //
//                                                                           //
//       An assemblage of minter created art on the Ethereum blockchain.     //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

import "./CreatorERC721Mintable.sol";

contract Choids is CreatorERC721Mintable {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI,
        string memory basePrefix,
        address administrator,
        address royaltyReceiver,
        uint96 feeBasisPoints
    )
        CreatorERC721Mintable(
            name,
            symbol,
            contractURI,
            basePrefix,
            administrator,
            royaltyReceiver,
            feeBasisPoints
        )
    {}
}
