pragma solidity ^0.5.16;

import "./AggregatorV3Interface.sol";
import "./CTokenInterfaces.sol";
import "./SafeMath.sol";

contract ETHChainLinkPriceOracle {
    using SafeMath for uint256;

    uint256 constant MANTISSA_DECIMALS = 18;

    AggregatorV3Interface internal priceFeedETH_USD;
    AggregatorV3Interface internal priceFeedUSDC_USD;
    AggregatorV3Interface internal priceFeedHBAR_USD;

    constructor(
        address priceFeedETH_USD_,
        address priceFeedUSDC_USD_,
        address priceFeedHBAR_USD_
    ) public {
        priceFeedETH_USD = AggregatorV3Interface(priceFeedETH_USD_);
        priceFeedUSDC_USD = AggregatorV3Interface(priceFeedUSDC_USD_);
        priceFeedHBAR_USD = AggregatorV3Interface(priceFeedHBAR_USD_);
    }

    /**
     * @notice Get the ETH_USD price from ChainLink and convert to a mantissa value
     * @return USD price mantissa
     */
    function getETH_USDPrice() public view returns (uint256) {
        return getPriceMantissa(priceFeedETH_USD);
    }

    /**
     * @notice Get the BUSD_USD price from ChainLink and convert to a mantissa value
     * @return USD price mantissa
     */
    function getUSDC_USDPrice() public view returns (uint256) {
        return getPriceMantissa(priceFeedUSDC_USD);
    }

    /**
     * @notice Get the HBAR_USD price from ChainLink and convert to a mantissa value
     * @return USD price mantissa
     */
    function getHBAR_USDPrice() public view returns (uint256) {
        return getPriceMantissa(priceFeedHBAR_USD);
    }

    /**
     * @notice Get the price from a ChainLink price feed and convert to a mantissa value
     * @return price mantissa
     */
    function getPriceMantissa(AggregatorV3Interface priceFeed_) private view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed_.latestRoundData();
        // Get decimals of price feed
        uint256 decimals = priceFeed_.decimals();
        // Add decimal places to format an 18 decimal mantissa
        uint256 priceMantissa =
            uint256(price).mul(10**(MANTISSA_DECIMALS.sub(decimals)));

        return priceMantissa;
    }
}