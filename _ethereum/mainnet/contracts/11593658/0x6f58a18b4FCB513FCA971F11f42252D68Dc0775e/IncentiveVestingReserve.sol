// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;
import "./VestingReserve.sol";
/**
 * @title VestingReserve
 * @dev A vested reserve, freeing 1% per day
 * @author Ethichub
 */
contract IncentiveVestingReserve is VestingReserve {

    address public reserveAccount;
    constructor(
        IERC20 _token,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _editAddressUntil
    ) VestingReserve(_token, _startTime, _endTime, _editAddressUntil) {}

    function initialize() external override {
      revert('IncentiveVestingReserve: Unsupported');
    }

    function initializeFor(address account, uint256 amount) external {
        require(!initialized, 'IncentiveVestingReserve: Already initialized');
        require(
            token.transferFrom(msg.sender, address(this), amount),
            'VestingReserve: Cannot transfer tokens from sender.'
        );
        reserveAccount = account;
        locked[account] = amount;

        initialized = true;
    }

    function claim(uint256 _amount) override external {
        _claim(reserveAccount, _amount);
    }

    function changeTokenOwnership(address _account, address _newAccount)
        override public
    {
        require(_account==reserveAccount, 'IncentiveVestingReserve: wrong reserve account');
        VestingReserve.changeTokenOwnership(_account, _newAccount);
        reserveAccount = _newAccount;

    }
}
