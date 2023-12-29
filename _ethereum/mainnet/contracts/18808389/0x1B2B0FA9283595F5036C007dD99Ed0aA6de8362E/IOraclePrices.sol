// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IOraclePrices {
    function prices(string memory grain) external view returns (uint256);
    
    function getXTokenPrice(address xToken) external view returns (uint256);

    function usdc() external view returns (address);
}