// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC20.sol";

import "./IAddressRegistry.sol";
import "./IAvalanche.sol";
import "./IPWDR.sol";
import "./ReentrancyGuard.sol";
import "./UniswapBase.sol";

contract PoolBase is UniswapBase, ReentrancyGuard {
    event ClearanceStarted(address indexed user, uint256 clearanceTime);
    event EmergencyClearing(address indexed user, address token, uint256 amount);

    uint256 internal constant SECONDS_PER_YEAR = 360 * 24 * 60 * 60; // std business yr, used to calculatee APR
    uint256 internal constant CLEARANCE_LOCK = 8 weeks;

    uint256 internal clearanceTimestamp;

    // Internal function to safely transfer tokens in case there is a rounding error
    function _safeTokenTransfer(
        address _token,
        address _to, 
        uint256 _amount
    ) 
        internal
    {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        if (_amount > tokenBalance) {
            IERC20(_token).safeTransfer(_to, tokenBalance);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    // shared function to calculate fixed apr pwdr rewards
    //  used in both avalanche and slopes
    function _calculatePendingRewards(
        uint256 _lastReward,
        uint256 _supply,
        uint256 _tokenPrice,
        uint256 _weight
    )
        internal
        view
        returns (uint256)
    {
        uint256 secondsElapsed = block.timestamp - _lastReward;

        // get PWDR uniswap price
        uint256 pwdrPrice = _getTokenPrice(pwdrAddress(), pwdrPoolAddress());

        uint256 scaledTotalLiquidityValue = _supply * _tokenPrice; // total value pooled tokens
        uint256 fixedApr = _weight * IPWDR(pwdrAddress()).currentBaseRate();
        uint256 yearlyRewards = ((fixedApr / 100) * scaledTotalLiquidityValue) / pwdrPrice; // instantaneous yearly pwdr payout
        uint256 rewardsPerSecond = yearlyRewards / SECONDS_PER_YEAR; // instantaneous pwdr rewards per second 
        return secondsElapsed * rewardsPerSecond;
    }

    // Emergency function to allow Admin withdrawal from the contract after 8 weeks
    //   in case of any unforeseen contract errors occuring. It would be irresponsible not to implement this 
    function emergencyClearance(address _token, uint256 _amount, bool _reset) 
        external
        HasPatrol("ADMIN") 
    {
        if (clearanceTimestamp == 0) {
            clearanceTimestamp = block.timestamp.add(CLEARANCE_LOCK);
            emit ClearanceStarted(msg.sender, clearanceTimestamp);
        } else {
            require(
                block.timestamp > clearanceTimestamp,
                "Must wait entire clearance period before withdrawing tokens"
            );

            if (address(this).balance > 0) {
                address(uint160(msg.sender)).transfer(address(this).balance);
            }

            IERC20(_token).safeTransfer(msg.sender, _amount);

            if (_reset) {
                clearanceTimestamp = 0;
            }

            emit EmergencyClearing(msg.sender, _token, _amount);
        }
    }
}