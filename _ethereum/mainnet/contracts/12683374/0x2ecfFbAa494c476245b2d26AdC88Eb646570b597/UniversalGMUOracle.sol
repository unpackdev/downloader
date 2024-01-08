// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IUniswapPairOracle.sol";
import "./AggregatorV3Interface.sol";
import "./IOracle.sol";

// an oracle that takes a raw chainlink or uniswap oracle and spits out the GMU price
contract UniversalGMUOracle is Ownable, IOracle {
    using SafeMath for uint256;

    IUniswapPairOracle public uniswapOracle;
    AggregatorV3Interface public chainlinkFeed;
    IOracle public GMUOracle;

    address public base;
    address public quote;

    uint256 public oraclePriceFeedDecimals = 8;
    uint256 public ethGMUPriceFeedDecimals = 8;

    uint256 private immutable _TOKEN_MISSING_DECIMALS;
    uint256 private constant _PRICE_PRECISION = 1e6;

    constructor(
        address base_,
        address quote_,
        IUniswapPairOracle uniswapOracle_,
        AggregatorV3Interface chainlinkFeed_,
        IOracle GMUOracle_
    ) {
        base = base_;
        quote = quote_;
        GMUOracle = GMUOracle_;
        chainlinkFeed = chainlinkFeed_;
        uniswapOracle = uniswapOracle_;

        ethGMUPriceFeedDecimals = GMUOracle.getDecimalPercision();
        oraclePriceFeedDecimals = address(chainlinkFeed) != address(0)
            ? chainlinkFeed.decimals()
            : 0;

        _TOKEN_MISSING_DECIMALS = uint256(18).sub(IERC20(base).decimals());
    }

    function setchainlinkFeed(AggregatorV3Interface oracle_) public onlyOwner {
        chainlinkFeed = oracle_;
        oraclePriceFeedDecimals = address(chainlinkFeed) != address(0)
            ? chainlinkFeed.decimals()
            : 0;
    }

    function getGMUPrice() public view returns (uint256) {
        return GMUOracle.getPrice();
    }

    function getPairPrice() public view returns (uint256) {
        return
            uniswapOracle.consult(
                quote,
                _PRICE_PRECISION * (10**_TOKEN_MISSING_DECIMALS)
            );
    }

    function getChainlinkPrice() public view returns (uint256) {
        (, int256 price, , , ) = chainlinkFeed.latestRoundData();
        return uint256(price);
    }

    function getRawPrice() public view returns (uint256, uint256) {
        // If we have chainlink oracle for base set return that price.
        // NOTE: this chainlink is subject to Aggregator being in BASE/USD and USD/GMU(Simple oracle).
        if (address(chainlinkFeed) != address(0)) return (getChainlinkPrice(), 10 ** oraclePriceFeedDecimals);

        // Else return price from uni pair.
        return (getPairPrice(), _PRICE_PRECISION);
    }

    function getPrice() public view override returns (uint256) {
        (uint256 price, uint256 precision) = getRawPrice();

        return (
            price
                .mul(getGMUPrice())
                .mul(_PRICE_PRECISION)
                .div(10**GMUOracle.getDecimalPercision())
                .div(precision)
        );
    }

    function getDecimalPercision() public pure override returns (uint256) {
        return _PRICE_PRECISION;
    }
}
