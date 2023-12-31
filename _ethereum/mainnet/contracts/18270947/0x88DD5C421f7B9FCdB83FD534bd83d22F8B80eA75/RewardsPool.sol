// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./SafeERC20.sol";

import "./IRewardsPoolController.sol";
import "./IERC677.sol";

/**
 * @title RewardsPool
 * @notice Handles reward distribution for a single asset
 * @dev rewards can only be positive (user balances can only increase)
 */
contract RewardsPool {
    using SafeERC20 for IERC677;

    IERC677 public immutable token;
    IRewardsPoolController public immutable controller;

    uint256 public rewardPerToken;
    uint256 public totalRewards;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public userRewards;

    event Withdraw(address indexed account, uint256 amount);
    event DistributeRewards(address indexed sender, uint256 amountStaked, uint256 amount);

    constructor(address _controller, address _token) {
        controller = IRewardsPoolController(_controller);
        token = IERC677(_token);
    }

    /**
     * @notice returns an account's total withdrawable rewards (principal balance + newly earned rewards)
     * @param _account account address
     * @return account's total unclaimed rewards
     **/
    function withdrawableRewards(address _account) public view virtual returns (uint256) {
        return
            (controller.staked(_account) * (rewardPerToken - userRewardPerTokenPaid[_account])) /
            1e18 +
            userRewards[_account];
    }

    /**
     * @notice withdraws an account's earned rewards
     **/
    function withdraw() external {
        _withdraw(msg.sender);
    }

    /**
     * @notice withdraws an account's earned rewards
     * @dev used by RewardsPoolController
     * @param _account account to withdraw for
     **/
    function withdraw(address _account) external {
        require(msg.sender == address(controller), "Controller only");
        _withdraw(_account);
    }

    /**
     * @notice ERC677 implementation that proxies reward distribution
     **/
    function onTokenTransfer(
        address,
        uint256,
        bytes calldata
    ) external {
        require(msg.sender == address(token), "Only callable by token");
        distributeRewards();
    }

    /**
     * @notice distributes new rewards that have been deposited
     **/
    function distributeRewards() public virtual {
        require(controller.totalStaked() > 0, "Cannot distribute when nothing is staked");
        uint256 toDistribute = token.balanceOf(address(this)) - totalRewards;
        totalRewards += toDistribute;
        _updateRewardPerToken(toDistribute);
        emit DistributeRewards(msg.sender, controller.totalStaked(), toDistribute);
    }

    /**
     * @notice updates an account's principal reward balance
     * @param _account account address
     **/
    function updateReward(address _account) public virtual {
        uint256 newRewards = withdrawableRewards(_account) - userRewards[_account];
        if (newRewards > 0) {
            userRewards[_account] += newRewards;
        }
        userRewardPerTokenPaid[_account] = rewardPerToken;
    }

    /**
     * @notice withdraws rewards for an account
     * @param _account account to withdraw for
     **/
    function _withdraw(address _account) internal virtual {
        uint256 toWithdraw = withdrawableRewards(_account);
        if (toWithdraw > 0) {
            updateReward(_account);
            userRewards[_account] -= toWithdraw;
            totalRewards -= toWithdraw;
            token.safeTransfer(_account, toWithdraw);
            emit Withdraw(_account, toWithdraw);
        }
    }

    /**
     * @notice updates rewardPerToken
     * @param _reward deposited reward amount
     **/
    function _updateRewardPerToken(uint256 _reward) internal {
        uint256 totalStaked = controller.totalStaked();
        require(totalStaked > 0, "Staked amount must be > 0");
        rewardPerToken += ((_reward * 1e18) / totalStaked);
    }
}
