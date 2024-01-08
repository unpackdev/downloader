// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeERC20.sol";

interface ITokenTimeLock {
    function setReleaseTime(uint256 newReleaseTime) external;
}

interface IOwnable {
    function owner() view external returns (address);
}

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    address private immutable SAFU;

    constructor(
        IERC20 token,
        address beneficiary,
        uint256 releaseTime,
        address safuInfo
    ) public {
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = releaseTime;
        SAFU = safuInfo;
    }

    /**
     * @return the token being held.
     */
    function token() external view returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() external view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() external view returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Extends locked tokens to a new locker.
     */
    function extendLock(
        address t,
        address newLocker,
        uint256 newReleaseTime
    ) external {
        require(msg.sender == IOwnable(SAFU).owner(), "TokenTimelock: invalid caller");
        IERC20 locked = IERC20(t);
        locked.safeTransfer(newLocker, locked.balanceOf(address(this)));
        ITokenTimeLock(newLocker).setReleaseTime(newReleaseTime);
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() external {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _token.safeTransfer(_beneficiary, amount);
    }
}
