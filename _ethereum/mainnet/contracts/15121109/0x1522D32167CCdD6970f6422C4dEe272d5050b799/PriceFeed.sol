// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IERC20Internal.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AggregatorV3Interface.sol";

import "./IPriceFeed.sol";

contract PriceFeed is IPriceFeed, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public constant MIN_DELAY_LIMIT = 1 days;
    uint256 public constant MAX_PRICE_DEVIATION_LIMIT = 50;

    mapping(address => address) public chainlinkAggregators;
    mapping(address => uint256) public internalPriceFeed;
    uint256 private _nextUpdate;
    uint256 private _minDelay;
    uint256 private _maxPriceDeviation;

    event AddChainLinkAggregator(address token, address aggregator);
    event SetInternalPrice(address token, uint256 price);

    function __PriceFeed_init(uint256 _minimumDelay, uint256 _maxDeviation) external initializer {
        __Ownable_init();
        require(_minimumDelay >= MIN_DELAY_LIMIT, "PriceFeed: PF7");
        _minDelay = _minimumDelay;
        require(_maxDeviation <= MAX_PRICE_DEVIATION_LIMIT, "PriceFeed: PF8");
        _maxPriceDeviation = _maxDeviation;
        _nextUpdate = block.timestamp;
    }

    // Returns the amount of @param tokenA in @param amount of @param tokenB
    // access: ANY
    function howManyTokensAinB(
        address tokenA,
        address tokenB,
        uint256 amount
    ) external view override returns (uint256 _amountA) {
        uint256 _priceA;
        if (chainlinkAggregators[tokenA] != address(0)) {
            (, int256 _price, , , ) = AggregatorV3Interface(chainlinkAggregators[tokenA])
                .latestRoundData();
            _priceA = uint256(_price);
        } else if (internalPriceFeed[tokenA] != 0) {
            _priceA = internalPriceFeed[tokenA];
        }
        require(_priceA > 0, "PriceFeed: PF1");

        uint256 _priceB;
        if (chainlinkAggregators[tokenB] != address(0)) {
            (, int256 _price, , , ) = AggregatorV3Interface(chainlinkAggregators[tokenB])
                .latestRoundData();
            _priceB = uint256(_price);
        } else if (internalPriceFeed[tokenB] != 0) {
            _priceB = internalPriceFeed[tokenB];
        }
        require(_priceB > 0, "PriceFeed: PF2");
        _amountA = _priceB.mul(amount).div(_priceA);

        uint256 _decimalsA = IERC20Internal(tokenA).decimals();
        uint256 _decimalsB = IERC20Internal(tokenB).decimals();
        if (_decimalsA > _decimalsB) {
            _amountA = _amountA.mul(10**(_decimalsA - _decimalsB));
        } else if (_decimalsB > _decimalsA) {
            _amountA = _amountA.div(10**(_decimalsB - _decimalsA));
        }
    }

    // Adds XYZ/ETH aggregator address from Chainlink data feeds
    // @dev Note if an aggregator is set it can't be changed anymore
    // access: OWNER
    function addChainlinkAggregator(address _token, address _aggregator) external onlyOwner {
        require(chainlinkAggregators[_token] == address(0), "PriceFeed: PF3");
        require(_aggregator != address(0), "PriceFeed: PF4");
        chainlinkAggregators[_token] = _aggregator;
        emit AddChainLinkAggregator(_token, _aggregator);
    }

    // Sets the asset prices XYZ/ETH internally
    // @param _prices represents the amount of ETH in one XYZ
    // @notice the price MUST be in 10**18 (18 decimals)
    // access: OWNER
    function setInternalPrice(address[] calldata _tokens, uint256[] calldata _prices)
        external
        onlyOwner
    {
        require(_nextUpdate <= block.timestamp, "PriceFeed: PF5");
        require(_tokens.length == _prices.length, "PriceFeed: PF9");
        for (uint256 i; i < _tokens.length; i++) {
            address _token = _tokens[i];
            uint256 _price = _prices[i];
            uint256 _prevPrice = internalPriceFeed[_token];
            if (_prevPrice > 0) {
                uint256 _deviation;
                if (_prevPrice >= _price) {
                    _deviation = _prevPrice.sub(_price).mul(100).div(_prevPrice);
                } else {
                    _deviation = _price.sub(_prevPrice).mul(100).div(_prevPrice);
                }
                require(_deviation <= _maxPriceDeviation, "PriceFeed: PF6");
            }
            internalPriceFeed[_token] = _price;
            emit SetInternalPrice(_token, _price);
        }
        _nextUpdate = _minDelay.add(block.timestamp);
    }

    function getMinDelay() public view returns (uint256) {
        return _minDelay;
    }
}
