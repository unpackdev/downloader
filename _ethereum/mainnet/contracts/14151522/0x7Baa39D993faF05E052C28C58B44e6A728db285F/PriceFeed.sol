// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Router02.sol";

import "./OwnableUpgradeable.sol";

import "./IERC20Internal.sol";
import "./SafeMathUpgradeable.sol";
import "./AggregatorV3Interface.sol";

import "./IPriceFeed.sol";
import "./IUniswapV2Factory.sol";

import "./IUniswapV2Pair.sol";

contract PriceFeed is IPriceFeed, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Factory public uniswapFactory;
    mapping(address => address) public chainlinkAggregators;
    mapping(address => uint256) public internalPriceFeed;

    function __PriceFeed_init(address _uniswapRouter, address _uniswapFactory)
        external
        initializer
    {
        __Ownable_init();
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);
    }

    // Returns the amount of @param tokenA in @param amount of @param tokenB
    // @notice @param viewOnly MUST be 'false' if the output of this function is used for trading
    // access: ANY
    function howManyTokensAinB(
        address tokenA,
        address tokenB,
        address via,
        uint256 amount,
        bool viewOnly
    ) external view override returns (uint256 _amountA) {
        if (viewOnly) {
            _amountA = uniswapFeed(tokenA, tokenB, via, amount);
        } else {
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
    }

    function uniswapFeed(
        address tokenA,
        address tokenB,
        address via,
        uint256 amount
    ) public view returns (uint256) {
        if (amount < 1 * 10**6) {
            //1 mWei
            return 0;
        }

        address[] memory pairs;

        if (via == address(0)) {
            pairs = new address[](2);
            pairs[0] = tokenB;
            pairs[1] = tokenA;
        } else {
            pairs = new address[](3);
            pairs[0] = tokenB;
            pairs[1] = via;
            pairs[2] = tokenA;
        }

        uint256[] memory amounts = uniswapRouter.getAmountsOut(amount, pairs);

        return amounts[amounts.length - 1];
    }

    function getUniswapRouter() external view override returns (address) {
        return address(uniswapRouter);
    }

    // Adds XYZ/ETH aggregator address from Chainlink data feeds
    // access: OWNER
    function addChainlinkAggregator(address _token, address _aggregator) external onlyOwner {
        chainlinkAggregators[_token] = _aggregator;
    }

    // Sets the asset price XYZ/ETH internally
    // @param _price represents the amount of ETH in one XYZ
    // @notice the price MUST be in 10**18 (18 decimals)
    // access: OWNER
    function setInternalPrice(address _token, uint256 _price) external onlyOwner {
        internalPriceFeed[_token] = _price;
    }
}
