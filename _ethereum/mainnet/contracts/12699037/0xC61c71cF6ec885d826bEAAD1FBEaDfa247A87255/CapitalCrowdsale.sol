// SPDX-License-Identifier: MIT
pragma solidity ^0.5.5;

import "./AggregatorV3Interface.sol";
import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IToken.sol";

contract CapitalCrowdsale is Crowdsale, TimedCrowdsale, Ownable {
    using SafeMath  for uint256;
    using SafeERC20 for IERC20;

    uint8 private constant PRICE_DECIMALS = 8;
    uint8 private constant TOKEN_DECIMALS = 5;

    AggregatorV3Interface private _priceFeed;

    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token,
        address aggregatorAddress,
        uint256 openingTime,
        uint256 closingTime
    )
        TimedCrowdsale(openingTime, closingTime)
        Crowdsale(rate, wallet, token)
        Ownable()
        public
    {
        require(aggregatorAddress != address(0), "Crowdsale: aggregator address is the zero address");

        _priceFeed = AggregatorV3Interface(aggregatorAddress);
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        IToken(address(token())).mint(beneficiary, tokenAmount);
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 price = ethPrice();
        uint256 rate  = rate();

        uint256 pow = 18 - TOKEN_DECIMALS + (PRICE_DECIMALS * 2);

        return weiAmount.mul(price).mul(rate).div(10 ** pow);
    }

    function ethPrice() public view returns (uint256) {
        (, int256 price,,,) = _priceFeed.latestRoundData();

        require(price > 0, "Crowdsale: oracle price is equal or lower than 0");

        return uint256(price);
    }

    function extendTime(uint256 newClosingTime) public onlyOwner {
        _extendTime(newClosingTime);
    }

    function recoverToken(address tokenAddress, address to, uint256 amount) public onlyOwner {
        IERC20(tokenAddress).safeTransfer(to, amount);
    }

    function tokenAmount(uint256 weiAmount) public view returns (uint256) {
        return _getTokenAmount(weiAmount);
    }
}
