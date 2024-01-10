/**
 * Submitted for verification at Etherscan.io on 2022-03-19;
 * Includes temporary emergency update and distribution options in case of 95%+ community support
 * See isExecutionAllowed() in the Proposals library
 */

 // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./ExtendedImplementation.sol";

contract ToonTokenImplementation is ToonTokenExtendedImplementation {
    function initialize() external virtual override implementationInitializer {
    }
}

// Copyright 2021-2022 ToonCoin.COM
// https://tooncoin.com/license
// Full source code: https://tooncoin.com/sourcecode