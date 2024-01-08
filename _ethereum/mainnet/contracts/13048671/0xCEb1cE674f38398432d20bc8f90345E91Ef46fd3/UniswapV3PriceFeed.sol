// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FeedRegistryInterface.sol";
import "./Denominations.sol";
import "./IMultipriceOracle.sol";
import "./IPriceFeed.sol";

contract UniswapV3PriceFeed is IPriceFeed {
    address public registry;
    address public multiPriceOracle;
    address public token;

    address public constant weth = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint public constant amountIn = 1e18;
    uint32 public constant twapPeriod = 1 days;

    /**
     * @dev Sets the values for {registry}, {multiPriceOracle}, and {token}.
     *
     * We retrieve 1-day twap from Uniswap v3.
     */
    constructor(address _registry, address _multiPriceOracle, address _token) {
        registry = _registry;
        multiPriceOracle = _multiPriceOracle;
        token = _token;
    }

    /**
     * @notice Return the token. It should be the collateral token address from IB agreement.
     * @return the token address
     */
    function getToken() external override view returns (address) {
        return token;
    }

    /**
     * @notice Return the token latest price in USD.
     * @return the price, scaled by 1e18
     */
    function getPrice() external override view returns (uint) {
        uint tokenEthPrice = IMultipriceOracle(multiPriceOracle).uniV3TwapAssetToAsset(token, amountIn, weth, twapPeriod);
        uint EthUsdPrice = getEthUsdPriceFromChainlink();
        uint price = tokenEthPrice * EthUsdPrice / 1e18;
        require(price > 0, "invalid price");

        return price;
    }

    /**
     * @notice Get ETH-USD price from ChainLink.
     * @return the price, scaled by 1e18
     */
    function getEthUsdPriceFromChainlink() internal view returns (uint) {
        ( , int price, , , ) = FeedRegistryInterface(registry).latestRoundData(Denominations.ETH, Denominations.USD);

        // Rates for usd queries are in 8 decimals. Extend the decimals to 1e18.
        return uint(price) * 10**10;
    }
}
