pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

// SPDX-License-Identifier: Unlicensed
contract Timelock is Ownable {
    using SafeMath for uint256;

    uint256 public unlockAt;

    modifier unlocked {
        require(block.timestamp >= unlockAt, "Timelock: locked");
        _;
    }

    constructor (uint256 delay) public {
        unlockAt = block.timestamp.add(delay);
    }

    function withdraw(address token, uint256 amount) external onlyOwner unlocked {
        SafeERC20.safeTransfer(token, msg.sender, amount);
    }

    function setDelay(uint256 delay) external onlyOwner unlocked {
        unlockAt = block.timestamp.add(delay);
    }
}
