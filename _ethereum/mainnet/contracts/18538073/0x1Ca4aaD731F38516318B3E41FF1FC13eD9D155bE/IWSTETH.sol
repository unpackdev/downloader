// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWSTETH {
    function decimals() external view returns (uint8);

    /**
     * @notice Get amount of stETH for a one wstETH
     * @return Amount of stETH for 1 wstETH
     */
    function stEthPerToken() external view returns (uint256);
}
