// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

interface IStaking {
    function notifyRewardAmount(uint256 amount) external;

    function rewardsToken() external returns (address);
}

interface IStrategy {
    function mintByStaking() external returns (uint256 _fTokenMinted, uint256 _xTokenMinted);
}

contract StakingVault is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public esToken;
    address public strategy;

    event EsTokenChanged(address indexed esToken);
    event StrategyChanged(address indexed strategy);

    function initialize() public initializer {
        __Ownable_init();
    }

    function setEsToken(address _esToken) external onlyOwner {
        require(_esToken != address(0), "EsToken cannot be set to zero address");
        esToken = _esToken;
        emit EsTokenChanged(esToken);
    }

    function setStrategy(address _strategy) external onlyOwner {
        require(_strategy != address(0), "Strategy cannot be set to zero address");
        strategy = _strategy;
        emit StrategyChanged(strategy);
    }

    function setReward(address staking, uint256 amount) external onlyOwner {
        require(staking != address(0), "invalid staking address");
        require(amount > 0, "amount is zero");

        address rewardsToken = IStaking(staking).rewardsToken();
        require(rewardsToken != address(0), "rewardsToken is zero");

        if (rewardsToken != esToken) {
            // mint fToken and xToken then transfer all of the minted amount to this contract
            if (strategy != address(0)) {
                IStrategy(strategy).mintByStaking();
            }

            uint256 tokenBalance = IERC20Upgradeable(rewardsToken).balanceOf(address(this));
            require(amount <= tokenBalance, "amount exceeds the maximum balance");

            uint256 allowance = IERC20Upgradeable(rewardsToken).allowance(address(this), staking);
            if (allowance < amount) {
                IERC20Upgradeable(rewardsToken).safeApprove(staking, type(uint256).max);
            }
        }

        IStaking(staking).notifyRewardAmount(amount);
    }

    function setReward(address staking) external onlyOwner {
        require(staking != address(0), "invalid staking address");

        address rewardsToken = IStaking(staking).rewardsToken();
        require(rewardsToken != address(0), "rewardsToken is zero");
        require(rewardsToken != esToken, "rewardsToken should not be esToken");

        // mint fToken and xToken then transfer all of the minted amount to this contract
        if (strategy != address(0)) {
            IStrategy(strategy).mintByStaking();
        }

        uint256 amount = IERC20Upgradeable(rewardsToken).balanceOf(address(this));
        require(amount > 0, "amount is zero");

        uint256 allowance = IERC20Upgradeable(rewardsToken).allowance(address(this), staking);
        if (allowance < amount) {
            IERC20Upgradeable(rewardsToken).safeApprove(staking, type(uint256).max);
        }

        IStaking(staking).notifyRewardAmount(amount);
    }

    function emergencyWithdraw(IERC20Upgradeable token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "token balance is 0");

        IERC20Upgradeable(token).safeTransfer(msg.sender, balance);
    }
}
