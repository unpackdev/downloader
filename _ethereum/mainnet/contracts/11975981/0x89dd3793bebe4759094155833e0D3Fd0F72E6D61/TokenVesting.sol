//SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./SafeERC20.sol";
import "./IERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 */
contract TokenVesting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Address who will receive tokens
    address _beneficiary;

    // Amount of tokens released so far
    uint256 released;

    // Token address to release
    IERC20 _token;

    // List of dates(in unix timestamp) on which tokens will be released
    uint256[] timeperiods;

    // Number of tokens to be released after each dates
    uint256[] tokenAmounts;

    // Total number of periods released
    uint256 periodsReleased;

    /// @notice Release Event
    event Released(uint256 amount, uint256 periods);

    /// @notice Initialize token vesting parameters
    function initialize(
        uint256[] memory periods,
        uint256[] memory tokenAmounts_,
        address beneficiary,
        address token
    ) external returns(bool){
        require(_beneficiary == address(0), "Already Initialized!");
        for(uint256 i = 0; i < periods.length; i++) {
            timeperiods.push(periods[i]);
            tokenAmounts.push(tokenAmounts_[i]);
        }
        _beneficiary = beneficiary;
        _token = IERC20(token);

        return true;
    }

    /// @notice Release tokens to beneficiary
    /// @dev multiple periods can be released in one call
    function release() external {
        require(periodsReleased < timeperiods.length, "Nothing to release");
        uint256 amount = 0;
        for (uint256 i = periodsReleased; i < timeperiods.length; i++) {
            if (timeperiods[i] <= block.timestamp) {
                amount = amount.add(tokenAmounts[i]);
                periodsReleased = periodsReleased.add(1);
            }
            else {
                break;
            }
        }
        if(amount > 0) {
            released = released.add(amount);
            IERC20(_token).safeTransfer(_beneficiary, amount);
            emit Released(amount, periodsReleased);
        }

    }

    /// @notice Get release amount and timestamp for a given period index
    function getPeriodData(uint index) external view returns(uint amount, uint timestamp){
        amount = tokenAmounts[index];
        timestamp = timeperiods[index];
    }

    /// @notice Get release amount and timestamp for a given period index
    function getGlobalData() 
        external 
        view 
        returns(uint releasedPeriods, uint totalPeriods, uint totalReleased, address beneficiary, address token)
    {
        releasedPeriods = periodsReleased;
        totalPeriods = timeperiods.length;
        totalReleased = released;
        beneficiary = _beneficiary;
        token = address(_token);
    }

}