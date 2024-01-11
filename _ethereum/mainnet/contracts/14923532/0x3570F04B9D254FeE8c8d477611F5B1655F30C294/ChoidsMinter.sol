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

import "./CreatorERC721Minter.sol";

contract ChoidsMinter is CreatorERC721Minter {
    constructor(
        address mintable,
        address signer,
        address administrator,
        address[] memory payees,
        uint256[] memory shares
    ) CreatorERC721Minter(mintable, signer, administrator, payees, shares) {}
}
