// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./IERC20.sol";
import "./Ownable.sol";

contract TimeLock is Ownable {
    IERC20 public token;
    uint256 public constant VESTING_DURATION = 365 days;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalLocked;
    uint256 public totalWithdrawn;

    event Locked(address indexed locker, uint256 amount);
    event Withdrawn(address indexed withdrawer, uint256 amount);

    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
    }

    function lockTokens(uint256 amount) external onlyOwner {
        require(totalLocked == 0, "Tokens already locked");
        require(amount > 0, "Amount must be greater than 0");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        startTime = block.timestamp;
        endTime = startTime + VESTING_DURATION;
        totalLocked = amount;

        emit Locked(msg.sender, amount);
    }

    function withdrawTokens() external onlyOwner {
        require(totalLocked > 0, "No tokens locked");
        require(block.timestamp >= startTime, "Vesting period has not started yet");
        
        uint256 amountEligible = getAvailableAmount();
        uint256 amountToWithdraw = amountEligible - totalWithdrawn;

        require(amountToWithdraw > 0, "No tokens available for withdrawal");
        
        totalWithdrawn += amountToWithdraw;
        require(token.transfer(msg.sender, amountToWithdraw), "Withdrawal failed");
        
        emit Withdrawn(msg.sender, amountToWithdraw);
    }

    function getAvailableAmount() public view returns (uint256) {
        if (block.timestamp >= endTime) {
            return totalLocked;
        } else {
            uint256 timeElapsed = block.timestamp - startTime;
            return (totalLocked * timeElapsed) / VESTING_DURATION;
        }
    }
}
