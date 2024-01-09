/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface ElectionsPrincipal {
    function candidateOf(address account) external view returns (address);

    function votesOf(address account) external view returns (uint256);
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode
