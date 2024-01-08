// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "ReentrancyGuard.sol";
import "SafeCast.sol";
import "IWsSQUID.sol";
import "IVotingEscrow.sol";

contract VewsSQUIDHelper is ReentrancyGuard {

    IERC20 public immutable sSQUID;
    IWsSQUID public immutable wsSQUID;
    IVotingEscrow public immutable vewsSQUID;

    constructor(
        IERC20 _sSQUID,
        IWsSQUID _wsSQUID,
        IVotingEscrow _vewsSQUID
    ) {
        sSQUID = _sSQUID;
        wsSQUID = _wsSQUID;
        vewsSQUID = _vewsSQUID;
    }

    function createLock(uint256 sSQUIDAmount, uint256 unlockTime) external nonReentrant {
        vewsSQUID.create_lock_for(msg.sender, wrap(sSQUIDAmount), unlockTime);
    }

    function increaseAmount(uint256 sSQUIDAmount) external nonReentrant {
        vewsSQUID.deposit_for(msg.sender, wrap(sSQUIDAmount));
    }

    function withdraw() external nonReentrant {
        (int128 lockedAmount, ) = vewsSQUID.locked(msg.sender);
        vewsSQUID.withdraw_for(msg.sender);
        uint256 wsSQUIDAmount = SafeCast.toUint256(int256(lockedAmount));
        uint256 sSQUIDAmount = wsSQUID.unwrapTosSQUID(wsSQUIDAmount);
        sSQUID.transfer(msg.sender, sSQUIDAmount);
    }

    function wrap(uint256 amount) internal returns (uint256) {
        sSQUID.transferFrom(msg.sender, address(this), amount);
        sSQUID.approve(address(wsSQUID), amount);
        uint256 wrappedAmount = wsSQUID.wrapFromsSQUID(amount);
        wsSQUID.approve(address(vewsSQUID), wrappedAmount);
        return wrappedAmount;
    }
}
