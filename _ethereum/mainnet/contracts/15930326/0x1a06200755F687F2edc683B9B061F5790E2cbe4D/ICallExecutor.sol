// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface ICallExecutor {
    function context() external view returns (address from, uint256 fromChainID, uint256 nonce);
}
