// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Constants {
    uint32 internal constant FULL_PERCENTAGE = 10000;

    uint32 internal constant SECONDS_PER_YEAR = 360 * 24 * 60 * 60;
    
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    bytes32 internal constant CONTRACT_ISSUE_MARKET= "IssueMarket";
    bytes32 internal constant CONTRACT_ISSUE_MARKET_PRICE_STRATEGY_MANAGER = "IMPriceStrategyManager";
    bytes32 internal constant CONTRACT_ISSUE_MARKET_WHITELIST_STRATEGY_MANAGER = "IMWhitelistStrategyManager";
	bytes32 internal constant CONTRACT_ISSUE_MARKET_UNDERWRITER_PROFIT_TOKEN = "IMUnderwriterProfitToken";
}
