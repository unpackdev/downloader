// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

// Based on https://github.com/smartcontractkit/LinkToken/blob/master/contracts/v0.6/token/ERC677.sol

import "./IERC20Upgradeable.sol";

interface IERC677Upgradeable is IERC20Upgradeable {
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}
