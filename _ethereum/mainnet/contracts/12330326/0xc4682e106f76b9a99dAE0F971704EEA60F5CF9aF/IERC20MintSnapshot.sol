// SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.0 <0.8.0;

interface IERC20MintSnapshot {
    function getPriorMints(address account, uint blockNumber) external view returns (uint224);
}