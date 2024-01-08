// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IBridge.sol";
import "./IFeeV2.sol";
import "./ILimiter.sol";
import "./BridgeBaseV2.sol";

contract BridgeLockerV2 is BridgeBaseV2 {
    using SafeERC20 for IERC20;

    IERC20 public token;

    constructor(
        IERC20 token_,
        string memory name,
        IBridge prev,
        IFeeV2 fee,
        ILimiter limiter
    ) BridgeBaseV2(name, prev, fee, limiter) {
        token = token_;
    }

    function lock(uint256 amount) external payable override {
        _beforeLock(amount);
        token.safeTransferFrom(_msgSender(), address(this), amount);
        emit Locked(_msgSender(), amount);
    }

    function unlock(address account, uint256 amount, bytes32 hash) external override onlyOwner {
        _setUnlockCompleted(hash);
        token.safeTransfer(account, amount);
        emit Unlocked(account, amount);
    }

    function renounceOwnership() public override onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(owner(), balance);
        }
        _pause();
        Ownable.renounceOwnership();
    }
}
