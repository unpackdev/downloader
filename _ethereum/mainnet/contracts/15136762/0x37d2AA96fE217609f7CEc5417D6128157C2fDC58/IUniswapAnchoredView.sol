//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapAnchoredView  {
    /**
     * @notice Get the official price for a symbol
     * @param symbol The symbol to fetch the price of
     * @return Price denominated in USD, with 6 decimals
     */
    function price(string memory symbol) external view returns (uint256);
}
