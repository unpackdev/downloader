// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract TimeLockedStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice Token to lock
    IERC20 public immutable token;

    /// @notice Lock time in seconds
    uint256 public lockTime;
    /// @notice Mapping from user to when their lock ends
    mapping(address => uint256) public lockEnd;
    /// @notice Mapping from user to their locked balance
    mapping(address => uint256) public balanceOf;
    /// @notice Total supply of locked tokens
    uint256 public totalSupply;

    event Staked(address indexed user, uint256 amount, uint256 lockEnd);
    event Unstaked(address indexed user, uint256 amount);
    event LockTimeUpdated(uint256 previousLockTime, uint256 nextLockTime);

    constructor(
        IERC20 _token,
        uint256 _initialLockTime
    ) {
        token = _token;
        lockTime = _initialLockTime;
    }

    /// @notice Stakes and locks tokens. NOTE: Staking will reset a users' lock end time
    /// @param _amount Amount to stake and lock
    function stake(uint256 _amount) external {
        token.safeTransferFrom(msg.sender, address(this), _amount);
        lockEnd[msg.sender] = block.timestamp.add(lockTime);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;

        emit Staked(msg.sender, _amount, lockEnd[msg.sender]);
    }

    /// @notice Withdraws staked tokens
    /// @param _amount Amount to stake and lock
    function unstake(uint256 _amount) external {
        require(lockEnd[msg.sender] <= block.timestamp, "TLS: Unstake too early");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        token.safeTransfer(msg.sender, _amount);

        emit Unstaked(msg.sender, _amount);
    }

    /// @notice Updates lock time
    /// @param _lockTime New lock time
    function setLockTime(uint256 _lockTime) external onlyOwner {
        emit LockTimeUpdated(lockTime, _lockTime);
        lockTime = _lockTime;
    }

    /// @notice Admin-only to force unstake a user's tokens. NOTE: Lock time is not affected
    /// @param _user The user to force withdraw
    /// @param _amount The amount to force withdraw
    function forceUnstake(address _user, uint256 _amount) external onlyOwner {
        // Catch underflow in the .sub
        balanceOf[_user] = balanceOf[_user].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        token.safeTransfer(_user, _amount);

        emit Unstaked(_user, _amount);
    }
}