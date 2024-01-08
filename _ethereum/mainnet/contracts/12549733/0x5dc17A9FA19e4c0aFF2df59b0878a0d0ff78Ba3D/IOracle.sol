// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IOracle {
    function priceOf(address token) external view returns (uint256 priceOfToken);
    function wbtcPriceOne() external view returns (uint256 priceOfwBTC);
    function wethPriceOne() external view returns (uint256 priceOfwETH);
    function pairFor(address _factor, address _token1, address _token2) external view returns (address pairaddy);
}