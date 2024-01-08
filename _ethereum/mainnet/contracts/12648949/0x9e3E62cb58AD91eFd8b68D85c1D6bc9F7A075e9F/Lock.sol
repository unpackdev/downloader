//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract Lock is Ownable {
    using SafeERC20 for IERC20;

    mapping(uint256 => uint256) public lockedTokens;
    uint256[] private amounts;
    IERC20 public immutable token;
    uint256 public lockTimeInSeconds;

    constructor(address token_, uint256 _lockTime) {
        lockTimeInSeconds = _lockTime;
        token = IERC20(token_);
    }

    function amountsHistory() external view returns (uint256[] memory) {
        return amounts;
    }

    function lock(uint256 _amount) external onlyOwner returns (uint256) {
        require(_amount > 0, "Amount should more than zero");
        token.safeTransferFrom(msg.sender, address(this), _amount);
        lockedTokens[_amount] = block.timestamp;
        amounts.push(_amount);
        return _amount;
    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(lockedTokens[_amount] > 0, "There is no locking for this amount");
        require(
            lockedTokens[_amount] + lockTimeInSeconds < block.timestamp,
            "Amount still locked"
        );
        delete lockedTokens[_amount];
        token.transfer(msg.sender, _amount);
    }
}
