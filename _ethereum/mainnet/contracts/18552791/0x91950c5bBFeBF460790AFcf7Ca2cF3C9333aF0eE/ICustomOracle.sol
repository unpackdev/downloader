// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICustomOracle {
    /**
     * @notice Get latest oracle price normalized to 1e18
     */
    function latestPrice() external view returns (uint256);
}
