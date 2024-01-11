// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract Treasury is Ownable, AccessControl {
    using SafeERC20 for IERC20;

    uint256 public vestingPeriod = 4 weeks;
    IERC20 public treasuryToken;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event VestingPeriodSet(uint256 _newPeriod, uint256 _oldPeriod);

    constructor(IERC20 _treasuryToken) {
        require(
            address(_treasuryToken) != address(0),
            "invalid treasury token"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, owner());

        treasuryToken = _treasuryToken;
    }

    function setTreasuryManager(address _manager) public onlyOwner {
        grantRole(MANAGER_ROLE, _manager);
    }

    function setVestingPeriod(uint256 _period) public onlyRole(MANAGER_ROLE) {
        require(_period > 1 days, "invalid vesting period");

        emit VestingPeriodSet(_period, vestingPeriod);

        vestingPeriod = _period;
    }

    function withdrawEmergency(address _to, uint256 _amount)
        public
        onlyRole(MANAGER_ROLE)
    {
        uint256 balance = treasuryToken.balanceOf(address(this));
        require(_amount <= balance, "not able to withdraw");

        treasuryToken.safeTransfer(_to, _amount);
    }
}
