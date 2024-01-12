// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./FeedRegistryInterface.sol";
import "./ChainlinkPriceProvider.sol";
import "./OracleHelpers.sol";

/**
 * @title ChainLink's price provider that uses price feed (only available on Mainnet currently)
 * @dev This contract is more expensive (+ ~1.3k) than others contracts (that don't use feed)
 * because they get decimals during aggregator addition
 */
contract ChainlinkFeedPriceProvider is ChainlinkPriceProvider {
    using SafeCast for int256;
    using OracleHelpers for uint256;

    address public constant USD = address(840); // Chainlink follows https://en.wikipedia.org/wiki/ISO_4217
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    FeedRegistryInterface public constant PRICE_FEED =
        FeedRegistryInterface(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf);
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    /// @inheritdoc IPriceProvider
    function getPriceInUsd(address token_) public view override returns (uint256, uint256) {
        // Chainlink price feed use ETH and BTC as token address
        if (token_ == WETH) {
            token_ = ETH;
        } else if (token_ == WBTC) {
            token_ = BTC;
        }

        (, int256 _price, , uint256 _lastUpdatedAt, ) = PRICE_FEED.latestRoundData(token_, USD);
        return (_price.toUint256().scaleDecimal(PRICE_FEED.decimals(token_, USD), USD_DECIMALS), _lastUpdatedAt);
    }
}
