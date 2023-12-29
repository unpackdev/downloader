// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;
import "./VestingReserve.sol";

/**
 * @title VestingReserve
 * @dev A vested reserve, freeing 1% per day
 * @author Ethichub
 */
abstract contract ManagedVestingReserve is VestingReserve {
    constructor(
        IERC20 _token,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _editAddressUntil
    ) VestingReserve(_token, _startTime, _endTime, _editAddressUntil) {}

    function claim(uint256 _amount) external override {
        revert('ManagedVestingReserve: Unsupported method');
    }
}
