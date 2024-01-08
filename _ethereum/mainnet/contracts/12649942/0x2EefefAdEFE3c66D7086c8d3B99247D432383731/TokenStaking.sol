// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Roles.sol";

abstract contract TokenStaking {
    using SafeERC20 for IERC20;

    struct StakeAccount {
        uint256 stakeAmount;
        uint256 stakeWeight;
        uint256 cumulativeStart;
        uint256 lockEnd;
    }
    IERC20 public immutable stakeToken;
    /// Margenswap (MFI) token address
    IERC20 public immutable MFI;
    Roles roles;

    mapping(address => StakeAccount) public stakeAccounts;

    uint256 public cumulativeReward;
    uint256 public lastCumulativeUpdateBlock;
    uint256 public totalCurrentWeights;
    uint256 public totalCurrentRewardPerBlock;

    constructor(
        address _MFI,
        address _stakeToken,
        address _roles
    ) {
        MFI = IERC20(_MFI);
        stakeToken = IERC20(_stakeToken);
        roles = Roles(_roles);
    }

    // TODO: function to load up with MFI

    function setTotalRewardPerBlock(uint256 rewardPerBlock) external {
        require(msg.sender == roles.owner(), "Not authorized");
        totalCurrentRewardPerBlock = rewardPerBlock;
    }

    function stake(uint256 amount, uint256 duration) external {
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        StakeAccount storage account = stakeAccounts[msg.sender];
        uint256 extantAmount = account.stakeAmount;

        if (extantAmount > 0) {
            _withdrawReward(msg.sender, account);
        }

        account.stakeAmount = extantAmount + amount;
        uint256 w =
            duration >= 90 days
                ? 3
                : (duration >= 30 days ? 2 : (duration >= 1 weeks ? 1 : 0));
        account.stakeWeight += w * amount;
        totalCurrentWeights += w * amount;
        account.cumulativeStart = updateCumulativeReward();

        account.lockEnd = max(block.timestamp + duration, account.lockEnd);
    }

    function withdrawStake(uint256 amount) external {
        StakeAccount storage account = stakeAccounts[msg.sender];
        require(block.timestamp >= account.lockEnd, "Stake is still locked");
        _withdrawReward(msg.sender, account);
        uint256 weightDiff =
            (amount * account.stakeWeight) / account.stakeAmount;
        account.stakeWeight -= weightDiff;
        totalCurrentWeights -= weightDiff;
        account.stakeAmount -= amount;
        account.cumulativeStart = updateCumulativeReward();
    }

    function viewUpdatedCumulativeReward() public view returns (uint256) {
        return
            cumulativeReward +
            (block.number - lastCumulativeUpdateBlock) *
            totalCurrentRewardPerBlock;
    }

    function updateCumulativeReward() public returns (uint256) {
        if (block.number > lastCumulativeUpdateBlock) {
            cumulativeReward = viewUpdatedCumulativeReward();
            lastCumulativeUpdateBlock = block.number;
        }
        return cumulativeReward;
    }

    function _viewRewardAmount(StakeAccount storage account)
        internal
        view
        returns (uint256)
    {
        uint256 totalReward = viewUpdatedCumulativeReward();
        return
            ((totalReward - account.cumulativeStart) * account.stakeWeight) /
            (totalCurrentWeights + 1);
    }

    function viewRewardAmount(address account) external view returns (uint256) {
        return _viewRewardAmount(stakeAccounts[account]);
    }

    function _withdrawReward(address recipient, StakeAccount storage account)
        internal
    {
        require(account.cumulativeStart > 0, "Account not active");
        uint256 reward =
            min(_viewRewardAmount(account), MFI.balanceOf(address(this)));

        MFI.safeTransfer(recipient, reward);
    }

    function withdrawReward() external {
        StakeAccount storage account = stakeAccounts[msg.sender];
        _withdrawReward(msg.sender, account);
        account.cumulativeStart = cumulativeReward;
    }

    /// @dev minimum
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return b;
        } else {
            return a;
        }
    }

    /// @dev maximum
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }
}
