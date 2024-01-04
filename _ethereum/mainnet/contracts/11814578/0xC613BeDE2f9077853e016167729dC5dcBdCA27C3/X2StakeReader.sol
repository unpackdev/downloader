// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IX2TimeDistributor.sol";
import "./IX2Farm.sol";

contract X2StakeReader {
    using SafeMath for uint256;

    uint256 constant PRECISION = 1e30;

    function getTokenInfo(
        address _farm,
        address _stakingToken,
        address _account
    ) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](4);

        amounts[0] = IERC20(_farm).totalSupply();
        amounts[1] = IERC20(_stakingToken).balanceOf(_account);
        amounts[2] = IERC20(_farm).balanceOf(_account);
        amounts[3] = IERC20(_stakingToken).allowance(_account, _farm);

        return amounts;
    }

    function getStakeInfo(
        address _xlgeFarm,
        address _uniFarm,
        address _burnVault,
        address _timeVault,
        address _xlgeWeth,
        address _xvixEth,
        address _xvix,
        address _weth,
        address _account
    ) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](16);

        amounts[0] = IERC20(_timeVault).balanceOf(_account);
        amounts[1] = IERC20(_burnVault).balanceOf(_account);
        amounts[2] = IERC20(_timeVault).totalSupply();
        amounts[3] = IERC20(_burnVault).totalSupply();
        amounts[4] = IERC20(_xlgeFarm).totalSupply();
        amounts[5] = IERC20(_uniFarm).totalSupply();
        amounts[6] = IERC20(_xvix).balanceOf(_account);
        amounts[7] = IERC20(_xlgeWeth).balanceOf(_account);
        amounts[8] = IERC20(_xlgeFarm).balanceOf(_account);
        amounts[9] = IERC20(_xlgeWeth).allowance(_account, _xlgeFarm);
        amounts[10] = IERC20(_xvixEth).balanceOf(_account);
        amounts[11] = IERC20(_uniFarm).balanceOf(_account);
        amounts[12] = IERC20(_xvixEth).allowance(_account, _uniFarm);
        amounts[13] = IERC20(_xvixEth).totalSupply();
        amounts[14] = IERC20(_weth).balanceOf(_xvixEth);
        amounts[15] = IERC20(_xvix).balanceOf(_xvixEth);

        return amounts;
    }

    function getRewards(address _farm, address _account, address _distributor) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);

        amounts[0] = IX2TimeDistributor(_distributor).ethPerInterval(_farm);

        uint256 balance = IERC20(_farm).balanceOf(_account);
        uint256 supply = IERC20(_farm).totalSupply();
        uint256 pendingRewards = IX2TimeDistributor(_distributor).getDistributionAmount(_farm);
        uint256 cumulativeRewardPerToken = IX2Farm(_farm).cumulativeRewardPerToken();
        uint256 claimableReward = IX2Farm(_farm).claimableReward(_account);
        uint256 previousCumulatedRewardPerToken = IX2Farm(_farm).previousCumulatedRewardPerToken(_account);

        if (supply > 0) {
            uint256 rewards = claimableReward.add(pendingRewards.mul(balance).div(supply));
            uint256 additionalRewards = balance.mul(cumulativeRewardPerToken.sub(previousCumulatedRewardPerToken)).div(PRECISION);
            amounts[1] = rewards.add(additionalRewards);
        }

        return amounts;
    }
}
