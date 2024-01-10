//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract OpenDAOLock {
    using SafeERC20 for IERC20;

    // mainnet 0x3b484b82567a09e2588A13D54D032153f0c0aEe0
    IERC20 public immutable sosToken;
    uint256 public immutable lockDuration;

    struct Lock {
        uint64 unlockTime;
        uint192 amount;
    }

    mapping(address => Lock) public locks;

    constructor(IERC20 _sosToken, uint256 _lockDuration) {
        sosToken = _sosToken;
        lockDuration = _lockDuration;
    }

    function lock(uint256 _amount) external {
        require(_amount > 0, "OpenDAOLock: Invalid amount");
        sosToken.safeTransferFrom(msg.sender, address(this), _amount);
        Lock memory _lock = locks[msg.sender];
        _lock.amount += uint192(_amount);
        _lock.unlockTime = uint64(block.timestamp + lockDuration);
        locks[msg.sender] = _lock;
    }

    function unlock(uint256 _amount) external {
        require(_amount > 0, "OpenDAOLock: Invalid amount");
        Lock memory _lock = locks[msg.sender];
        require(block.timestamp >= _lock.unlockTime, "OpenDAOLock: Assets locked");
        require(uint256(_lock.amount) >= _amount, "OpenDAOLock: Insufficient amount to withdraw");
        locks[msg.sender].amount -= uint192(_amount);
        sosToken.safeTransfer(msg.sender, _amount);
    }

    function locked(address _account) external view returns(uint256) {
        return locks[_account].amount;
    }

    function lockTime(address _account) external view returns(uint64 _lockTime, uint64 _now) {
        if (locks[_account].unlockTime <= uint64(lockDuration)) {
            _lockTime = 0;
        } else {
            _lockTime = locks[_account].unlockTime - uint64(lockDuration);
        }
        _now = uint64(block.timestamp);
    }

    function unlockTime(address _account) external view returns(uint64 _unlockTime, uint64 _now) {
        _unlockTime = locks[_account].unlockTime;
        _now = uint64(block.timestamp);
    }
}
