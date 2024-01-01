// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./IERC20.sol";

interface IVault {
    function getPoolTokens(
        bytes32 _poolId
    ) external view returns (IERC20[] memory _tokens, uint256[] memory _balances, uint256 _lastChangeBlock);
}
