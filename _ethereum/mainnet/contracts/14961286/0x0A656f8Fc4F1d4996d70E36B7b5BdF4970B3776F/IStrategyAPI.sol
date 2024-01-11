// SPDX-License-Identifier: AGPLv3

pragma solidity 0.8.10;

interface IStrategyAPI {
    function vault() external view returns (address);

    function estimatedTotalAssets() external view returns (uint256);
}
