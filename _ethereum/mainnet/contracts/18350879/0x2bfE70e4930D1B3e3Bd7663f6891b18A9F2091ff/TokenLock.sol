// SPDX-License-Identifier: UNLICENSED
/*

███╗   ███╗███████╗███╗   ███╗███████╗██████╗ ██╗   ██╗██████╗ ██████╗ ██╗   ██╗
████╗ ████║██╔════╝████╗ ████║██╔════╝██╔══██╗██║   ██║██╔══██╗██╔══██╗╚██╗ ██╔╝
██╔████╔██║█████╗  ██╔████╔██║█████╗  ██████╔╝██║   ██║██║  ██║██║  ██║ ╚████╔╝ 
██║╚██╔╝██║██╔══╝  ██║╚██╔╝██║██╔══╝  ██╔══██╗██║   ██║██║  ██║██║  ██║  ╚██╔╝  
██║ ╚═╝ ██║███████╗██║ ╚═╝ ██║███████╗██████╔╝╚██████╔╝██████╔╝██████╔╝   ██║   
╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═════╝ ╚═════╝    ╚═╝   

*/

pragma solidity ^0.8.13;

import "./ERC20.sol";

contract TokenLock {
    enum LockTime {
        ThreeMonths,
        SixMonths,
        OneYear
    }

    struct Lock {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Lock[]) public locks;

    ERC20 public token;

    event Locked(address account, uint256 amount, uint256 unlockTime, uint index);
    event Withdrawn(address account, uint256 amount, uint index);

    constructor(address _token) {
        token = ERC20(_token);
    }

    function lock(uint256 _amount, LockTime lockTime) public {
        token.transferFrom(msg.sender, address(this), _amount);
        uint256 lockTimeSeconds = getLockTime(lockTime);
        locks[msg.sender].push(Lock(_amount, block.timestamp + lockTimeSeconds));
        emit Locked(msg.sender, _amount, block.timestamp + lockTimeSeconds, locks[msg.sender].length - 1);
    }

    function withdraw(uint index) public {
        Lock memory _lock = locks[msg.sender][index];
        require(_lock.amount > 0, "No lock found");
        require(_lock.unlockTime <= block.timestamp, "Lock not expired");
        delete locks[msg.sender][index];
        token.transfer(msg.sender, _lock.amount);
        emit Withdrawn(msg.sender, _lock.amount, index);
    }

    function getLockTime(LockTime lockTime) public pure returns (uint256) {
        if (lockTime == LockTime.ThreeMonths) {
            return 12 weeks;
        } else if (lockTime == LockTime.SixMonths) {
            return 24 weeks;
        }
        return 52 weeks;
    }
}
