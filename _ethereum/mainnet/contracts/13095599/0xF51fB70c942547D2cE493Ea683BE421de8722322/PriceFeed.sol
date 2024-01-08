// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./AggregatorV2V3Interface.sol";

import "./IERC20.sol";

contract PriceFeed is Ownable {
    IUniswapV2Pair private lp;
    AggregatorV2V3Interface private priceFeed;
    bool private tokenOrder;

    constructor(address _lp, address _priceFeed) {
        lp = IUniswapV2Pair(_lp);
        priceFeed = AggregatorV2V3Interface(_priceFeed);
        tokenOrder = false;
    }

    function decimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    function feedTokenPrice() public view returns (uint256) {
        int256 price = priceFeed.latestAnswer();

        return uint256(price);
    }

    function getMultipliers() internal view returns (uint8 multiplier0, uint8 multiplier1) {
        uint8 decimals0 = IERC20(lp.token0()).decimals();
        uint8 decimals1 = IERC20(lp.token1()).decimals();

        if (decimals0 > decimals1) {
            multiplier1 = decimals0 - decimals1;
        } else if (decimals0 < decimals1) {
            multiplier0 = decimals1 - decimals0;
        }
    }

    function tokenPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = lp.getReserves();
        (uint112 reserveA, uint112 reserveB) = tokenOrder ? (reserve0, reserve1) : (reserve1, reserve0);
        (uint8 multiplier0, uint8 multiplier1) = getMultipliers();
        (uint8 multiplierA, uint8 multiplierB) = tokenOrder ? (multiplier0, multiplier1) : (multiplier1, multiplier0);

        return
            ((((uint256(reserveB) * 10**uint256(multiplierB) * 1 ether) / (uint256(reserveA) * 10**uint256(multiplierA))) * feedTokenPrice())) /
            1 ether;
    }

    function usdValueForToken(uint256 amount) public view returns (uint256) {
        return (amount * tokenPrice()) / 10**18;
    }

    function lpPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = lp.getReserves();
        (uint112 reserveA, uint112 reserveB) = tokenOrder ? (reserve0, reserve1) : (reserve1, reserve0);

        uint256 snpValue = uint256(reserveA) * tokenPrice();
        uint256 usdcValue = uint256(reserveB) * feedTokenPrice();

        return (snpValue + usdcValue) / lp.totalSupply();
    }

    function usdValueForLp(uint256 amount) public view returns (uint256) {
        return (amount * lpPrice()) / 10**18;
    }

    function setupLp(address _lp) external onlyOwner {
        lp = IUniswapV2Pair(_lp);
    }

    function setupPriceFeed(address _priceFeed) external onlyOwner {
        priceFeed = AggregatorV2V3Interface(_priceFeed);
    }

    function setupTokenOrder(bool order) external onlyOwner {
        tokenOrder = order;
    }
}
