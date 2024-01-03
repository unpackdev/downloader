// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";

import "./IController.sol";
import "./VaultBase.sol";
/**
 * @notice A vault with rewards.
 *
 * A vault not only pools token to seek best yield, but also receive reward token,
 * i.e. ACoconut as additional yield. This removes the need to deposit and stake to
 * to earn rewards: User only needs to deposit into the vault to earn yield, and automatically
 * receives rewards in proportion to their shares in the vault.
 */
contract Vault is VaultBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    uint256 public constant DURATION = 7 days;      // Rewards are vested for a fixed duration of 7 days.
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public claimed;

    uint256[50] private __gap;

    event RewardAdded(address indexed rewardToken, uint256 rewardAmount);
    event RewardClaimed(address indexed rewardToken, address indexed user, uint256 rewardAmount);

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return MathUpgradeable.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address _account) public view returns (uint256) {
        return
            balanceOf(_account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_account]))
                .div(1e18)
                .add(rewards[_account]);
    }

    function deposit(uint256 _amount) public virtual override updateReward(msg.sender) {
        super.deposit(_amount);
    }

    function withdraw(uint256 _shares) public virtual override updateReward(msg.sender) {
        super.withdraw(_shares);
    }

    /**
     * @dev Withdraws all balance and all rewards from the vault.
     */
    function exit() external {
        // Withdraws all balance on exit.
        withdraw(uint256(-1));
        claimReward();
    }

    /**
     * @dev Claims all rewards from the vault.
     */
    function claimReward() public updateReward(msg.sender) returns (uint256) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            claimed[msg.sender] = claimed[msg.sender].add(reward);
            rewards[msg.sender] = 0;
            address rewardToken = IController(controller).rewardToken();
            IERC20Upgradeable(rewardToken).safeTransfer(msg.sender, reward);
            emit RewardClaimed(rewardToken, msg.sender, reward);
        }

        return reward;
    }

    /**
     * @dev Notifies the vault that new reward is added. All rewards will be distributed linearly in 7 days.
     * @param _reward Amount of reward token to add.
     */
    function notifyRewardAmount(uint256 _reward) public override updateReward(address(0)) {
        require(msg.sender == controller, "not controller");

        if (block.timestamp >= periodFinish) {
            rewardRate = _reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = _reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);

        emit RewardAdded(IController(controller).rewardToken(), _reward);
    }
}