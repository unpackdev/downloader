// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Prey.sol";

/**
 * Useful for simple vesting schedules like "developers get their tokens
 * after 2 years".
 */
contract TokenTimelock {

    // ERC20 basic token contract being held
    Prey private immutable _token;

    // beneficiary of tokens after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled
    uint256 private immutable _releaseTime;
    
    //a vesting duration to release tokens 
    uint256 private immutable _releaseDuration;
    
    //record last withdraw time, through which calculate the total withdraw amount
    uint256 private lastWithdrawTime;
    //total amount of tokens to release
    uint256 private immutable _totalToken;

    constructor(
        Prey token_,
        address beneficiary_,
        uint256 releaseTime_,
        uint256 releaseDuration_,
        uint256 totalToken_
    ) {
        require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
        lastWithdrawTime = _releaseTime;
        _releaseDuration = releaseDuration_;
        _totalToken = totalToken_;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (Prey) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        uint256 releaseAmount = (block.timestamp - lastWithdrawTime) * _totalToken / _releaseDuration;
        
        require(amount >= releaseAmount, "TokenTimelock: no tokens to release");

        lastWithdrawTime = block.timestamp;
        token().transfer(beneficiary(), releaseAmount);
    }
}
