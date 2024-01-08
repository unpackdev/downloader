// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually
 */
contract TokenVesting {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event TokensReleased(uint256 amount);

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private _start;
    uint256 private _periodsAmount;
    uint256 private _periodDuration;
    uint256 private _duration;
    uint256 private _released;

    IERC20 private _alphr;

    /**
     * @dev Creates a vesting contract that vests its balance of ALPHR ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiary_ address of the beneficiary to whom vested tokens are transferred
     * @param start_ the time (as Unix time) at which point vesting starts
     * @param periodDuration_ minimum time to passed to vest tokens
     * @param periodsAmount_ number of vesting periods
     * @param alphr_ address of ALPHR token
     */
    constructor (address beneficiary_, uint256 start_, uint256 periodDuration_, uint256 periodsAmount_, IERC20 alphr_) {
        require(beneficiary_ != address(0), "TokenVesting: beneficiary is the zero address");
        
        _beneficiary = beneficiary_;
        _start = start_;
        _alphr = alphr_;
        _periodDuration = periodDuration_;
        _periodsAmount = periodsAmount_;
        _duration = periodDuration_.mul(periodsAmount_);
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the duration of 1 vesting period
     */
    function periodDuration() public view returns (uint256) {
        return _periodDuration;
    }

    /**
     * @return total amount of vesting periods
     */
    function periodsAmount() public view returns (uint256) {
        return _periodsAmount;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the total duration of the token vesting.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @return ALPHR address
     */
    function alphr() public view returns (address) {
        return address(_alphr);
    }

    /**
     * @return ALPHR tokens already released
     */
    function released() public view returns (uint) {
        return _released;
    }

    /**
     * @return returns amount of ALPHR tokens available for release 
     */
    function releasableAmount() public view returns (uint) {
        return _releasableAmount();
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        uint256 unreleased = _releasableAmount();

        require(unreleased > 0, "TokenVesting: no tokens are due");

        _released = _released.add(unreleased);

        _alphr.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(unreleased);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     */
    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount().sub(_released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount() private view returns (uint256) {
        uint256 currentBalance = _alphr.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released);

        if (block.timestamp < _start) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start).div(_periodDuration)).div(_periodsAmount);
        }
    }
}