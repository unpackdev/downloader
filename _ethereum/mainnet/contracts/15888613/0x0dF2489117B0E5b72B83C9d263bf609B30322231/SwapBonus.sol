// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./SafeMath.sol";

contract SwapBonus is Ownable {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable liquidityGauge;
    address public immutable bonusToken;
    uint256 public ratePerSecond;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public lastTimestamp;

    constructor(address liquidityGauge_, address bonusToken_) public {
        liquidityGauge = liquidityGauge_;
        bonusToken = bonusToken_;
    }

    function updateBonus(
        uint256 amount,
        uint256 start,
        uint256 interval
    ) external onlyOwner {
        require(start >= block.timestamp, "Start time in the past");
        require(
            endTimestamp < block.timestamp && endTimestamp == lastTimestamp,
            "Last reward not yet expired"
        );
        ratePerSecond = amount.div(interval);
        startTimestamp = start;
        endTimestamp = start.add(interval);
        lastTimestamp = startTimestamp;
        IERC20(bonusToken).safeTransferFrom(msg.sender, address(this), ratePerSecond.mul(interval));
    }

    function getBonus() external returns (uint256) {
        require(msg.sender == liquidityGauge);
        uint256 currentTimestamp = endTimestamp.min(block.timestamp);
        uint256 reward = ratePerSecond.mul(currentTimestamp - lastTimestamp);
        lastTimestamp = currentTimestamp;
        if (reward > 0) {
            IERC20(bonusToken).safeTransfer(liquidityGauge, reward);
        }
        return reward;
    }
}
