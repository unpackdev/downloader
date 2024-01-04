// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IX2Market.sol";
import "./IX2ETHFactory.sol";
import "./IX2PriceFeed.sol";
import "./IX2Token.sol";
import "./IX2RewardDistributor.sol";
import "./IERC20.sol";

contract X2Reader {
    using SafeMath for uint256;
    uint256 constant PRECISION = 1e20;

    function getMarkets(address _factory, uint256 _start) public view returns (uint256[] memory, address[] memory) {
        uint256 length = IX2ETHFactory(_factory).marketsLength();
        uint256[] memory leverages = new uint256[](length - _start);
        address[] memory priceFeeds = new address[](length - _start);
        for (uint256 i = _start; i < length; i++) {
            address market = IX2ETHFactory(_factory).markets(i);
            uint256 multiplierBasisPoints = IX2Market(market).multiplierBasisPoints();
            address priceFeed = IX2Market(market).priceFeed();
            leverages[i - _start] = multiplierBasisPoints;
            priceFeeds[i - _start] = priceFeed;
        }

        return (leverages, priceFeeds);
    }

    function getFees(address[] memory _markets) public view returns (uint256) {
        uint256 totalFees = 0;
        for (uint256 i = 0; i < _markets.length; i++) {
            address market = _markets[i];
            totalFees = totalFees.add(IX2Market(market).feeReserve());
        }

        return totalFees;
    }

    function distributeFees(address[] memory _markets) public returns (uint256) {
        for (uint256 i = 0; i < _markets.length; i++) {
            address market = _markets[i];
            IX2Market(market).distributeFees();
        }
    }

    function getAppFees(address[] memory _markets, address app) public view returns (uint256) {
        uint256 totalFees = 0;
        for (uint256 i = 0; i < _markets.length; i++) {
            address market = _markets[i];
            totalFees = totalFees.add(IX2Market(market).appFees(app));
        }

        return totalFees;
    }

    function distributeAppFees(address[] memory _markets, address app) public returns (uint256) {
        for (uint256 i = 0; i < _markets.length; i++) {
            address market = _markets[i];
            IX2Market(market).distributeAppFees(app);
        }
    }

    function getMarketInfo(address _market) public view returns (uint256[] memory) {
        address bullToken = IX2Market(_market).bullToken();
        address bearToken = IX2Market(_market).bearToken();
        (uint256 bullFunding, uint256 bearFunding) = IX2Market(_market).getFunding();

        uint256[] memory amounts = new uint256[](5);

        amounts[0] = IX2Market(_market).latestPrice();
        amounts[1] = IERC20(bullToken).totalSupply();
        amounts[2] = IERC20(bearToken).totalSupply();
        amounts[3] = bullFunding;
        amounts[4] = bearFunding;

        return amounts;
    }

    function getRewards(address _token, address _account) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](6);
        address distributor = IX2Token(_token).distributor();
        if (distributor == address(0)) {
            return amounts;
        }

        amounts[0] = IX2RewardDistributor(distributor).tokensPerInterval(_token);

        uint256 rewards = IX2Token(_token).getReward(_account);
        uint256 pendingRewards = IX2RewardDistributor(distributor).getDistributionAmount(_token);
        uint256 balance = IX2Token(_token)._balanceOf(_account);
        uint256 cumulativeRewardPerToken = IX2Token(_token).cumulativeRewardPerToken();

        uint256 supply = IX2Token(_token)._totalSupply();
        if (supply > 0) {
            amounts[1] = rewards.add(pendingRewards.mul(balance).div(supply));
        }
        amounts[2] = IERC20(_token).totalSupply();

        amounts[3] = balance;
        amounts[4] = cumulativeRewardPerToken;
        amounts[5] = PRECISION;

        return amounts;
    }

    function getBalanceInfo(address _market, address _account) public view returns (uint256[] memory) {
        address bullToken = IX2Market(_market).bullToken();
        address bearToken = IX2Market(_market).bearToken();

        uint256[] memory amounts = new uint256[](9);

        amounts[0] = _account.balance;
        amounts[1] = IERC20(bullToken).balanceOf(_account);
        amounts[2] = IERC20(bearToken).balanceOf(_account);
        amounts[3] = IX2Token(bullToken).lastBoughtAt(_account);
        amounts[4] = IX2Token(bearToken).lastBoughtAt(_account);
        amounts[5] = IX2Token(bullToken).getPendingProfit(_account);
        amounts[6] = IX2Token(bearToken).getPendingProfit(_account);
        amounts[7] = IX2Token(bullToken).costOf(_account);
        amounts[8] = IX2Token(bearToken).costOf(_account);

        return amounts;
    }
}
