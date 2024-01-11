// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

interface IStakeManager {
    function balanceOf(address wallet) external view returns (uint256);

    function withdrawTo(address wallet, uint256 amount) external;
}
