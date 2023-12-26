// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

// ____  _______   ____________
// \   \/  /\   \ /   /  _____/
//  \     /  \   Y   /   \  ___
//  /     \   \     /\    \_\  \
// /___/\  \   \___/  \______  /2023
//       \_/XVG              \/
//
// https://github.com/vergecurrency/erc20

/// @title XVGFarm: a simplified version of MasterChef to earn XVG rewards by staking XVG/ETH LP tokens.
contract XVGFarm is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Address of the XVG/ETH LP token to stake.
    IERC20 public immutable xvgEthLp;
    /// @notice Address of the XVG token used for the rewards.
    IERC20 public immutable xvg;

    /// @notice Info about each user.
    /// `amount` Amount of xvgEthLp the user has provided.
    /// `rewardDebt` Used to calculate the correct amount of rewards. See explanation below.
    ///
    /// We do some fancy math here. Basically, any point in time, the amount of XVG
    /// entitled to a user but is pending to be distributed is:
    ///
    ///   pending rewards = (user share * accRewardsPerShare) - user.rewardDebt
    ///
    ///   Whenever a user deposits or withdraws xvgEthLp. Here's what happens:
    ///   1. `accRewardsPerShare` (and `lastRewardsBlock`) get updated.
    ///   2. User receives the pending rewards sent to his/her address.
    ///   3. User's `amount` gets updated. `totalShares` gets updated.
    ///   4. User's `rewardDebt` gets updated.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    /// @notice Accumulated XVG rewards per share.
    uint256 public accRewardsPerShare;

    /// @notice Last block number when the update action was executed.
    uint256 public lastRewardsBlock;

    /// @notice The total amount of user shares.
    uint256 public totalShares;

    /// @notice Amount and rewards about each user.
    mapping(address => UserInfo) public userInfo;

    /// @notice Amount of XVG to reward each block.
    uint256 public rewardsPerBlock;

    /// @notice Decimals of the XVG token.
    uint256 public constant ACC_PRECISION = 1e18;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Update(uint256 lastRewardsBlock, uint256 totalShares, uint256 accRewardsPerShare);
    event UpdateRewardsPerBlock(uint256 rewardsPerBlock);

    error Unauthorized();
    error InsufficientUserBalance();
    error InsufficientXvgBalance();

    constructor(IERC20 _xvgEthLp, IERC20 _xvg, address _owner) {
        xvgEthLp = _xvgEthLp;
        xvg = _xvg;

        transferOwnership(_owner);
    }

    /// @notice Deposit xvgEthLp.
    /// @param amount Amount of xvgEthLp to deposit.
    function deposit(uint256 amount) external nonReentrant {
        update();
        UserInfo storage user = userInfo[msg.sender];

        if (user.amount > 0) {
            settlePendingRewards(msg.sender);
        }

        if (amount > 0) {
            uint256 before = xvgEthLp.balanceOf(address(this));
            xvgEthLp.safeTransferFrom(msg.sender, address(this), amount);
            amount = xvgEthLp.balanceOf(address(this)) - before;
            user.amount = user.amount + amount;

            // Update total shares.
            totalShares = totalShares + amount;
        }

        user.rewardDebt = user.amount * accRewardsPerShare / ACC_PRECISION;

        emit Deposit(msg.sender, amount);
    }

    /// @notice Withdraw xvgEthLp.
    /// @param amount Amount of xvgEthLp to withdraw.
    function withdraw(uint256 amount) external nonReentrant {
        update();
        UserInfo storage user = userInfo[msg.sender];

        if (user.amount < amount) revert InsufficientUserBalance();

        settlePendingRewards(msg.sender);

        if (amount > 0) {
            user.amount = user.amount - amount;
            xvgEthLp.safeTransfer(msg.sender, amount);

            // Update total shares.
            totalShares = totalShares - amount;
        }

        user.rewardDebt = user.amount * accRewardsPerShare / ACC_PRECISION;

        emit Withdraw(msg.sender, amount);
    }

    /// @notice Withdraw without caring about the rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        totalShares = totalShares > amount ? totalShares - amount : 0;

        if (amount > 0) xvgEthLp.safeTransfer(msg.sender, amount);

        emit EmergencyWithdraw(msg.sender, amount);
    }

    /// @notice Update rewards variables.
    function update() public {
        if (block.number > lastRewardsBlock) {
            if (totalShares > 0) {
                uint256 rewards = (block.number - lastRewardsBlock) * rewardsPerBlock;
                accRewardsPerShare = accRewardsPerShare + (rewards * ACC_PRECISION / totalShares);
            }
            lastRewardsBlock = block.number;
            emit Update(lastRewardsBlock, totalShares, accRewardsPerShare);
        }
    }

    /// @notice View function for checking pending XVG rewards.
    /// @param _user Address of the user.
    function pendingRewards(address _user) external view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        uint256 _accRewardsPerShare = accRewardsPerShare;

        if (block.number > lastRewardsBlock && totalShares != 0) {
            uint256 rewards = (block.number - lastRewardsBlock) * rewardsPerBlock;
            _accRewardsPerShare = _accRewardsPerShare + (rewards * ACC_PRECISION / totalShares);
        }

        return (user.amount * _accRewardsPerShare / ACC_PRECISION) - user.rewardDebt;
    }

    /// @notice Settles, distribute the pending XVG rewards for given user.
    /// @param _user The user address for settling rewards.
    function settlePendingRewards(address _user) private {
        UserInfo memory user = userInfo[_user];
        uint256 accRewards = user.amount * accRewardsPerShare / ACC_PRECISION;
        uint256 pending = accRewards - user.rewardDebt;
        
        _safeTransfer(_user, pending);
    }

    /// @notice Sets the rewardsPerBlock to 630 XVG per block & renounces ownership.
    function startFarming() external onlyOwner {
        update();
        rewardsPerBlock = 630 * 1e18;
        emit UpdateRewardsPerBlock(rewardsPerBlock);

        renounceOwnership();
    }

    /// @notice Safe Transfer XVG.
    /// @param to The receiver address.
    /// @param amount The amount of XVG to transfer.
    function _safeTransfer(address to, uint256 amount) private {
        if (amount > 0) {
            uint256 balance = xvg.balanceOf(address(this));
            // Check whether MCV2 has enough XVG. If not, fail with an error.
            if (balance < amount) revert InsufficientXvgBalance();
            xvg.safeTransfer(to, amount);
        }
    }
}