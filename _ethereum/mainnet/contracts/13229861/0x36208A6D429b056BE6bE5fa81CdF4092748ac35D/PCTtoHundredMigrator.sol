// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.3;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./HundredVesting.sol";

contract PCTtoHundredMigrator {
    using SafeERC20 for IERC20;
    IERC20 public immutable PCT;
    IERC20 public Hundred;
    HundredVesting public immutable Vesting;
    uint256 public UserPercent = 10;
    uint256 public VestingPercent = 90;
    uint256 public PercentMax = 100;

    constructor(IERC20 pct, IERC20 hundred, address vesting) {
        PCT = pct;
        Hundred = hundred;
        Vesting = HundredVesting(vesting);
        Hundred.approve(vesting, type(uint256).max);
    }

    function _migrate(address user, uint256 amount) internal {
        require(amount != 0, "Amount should bigger than 0");

        uint256 immediateAmount = amount * UserPercent / PercentMax;
        uint256 vestingAmount = amount - immediateAmount;

        PCT.safeTransferFrom(user, address(this), amount);
        Hundred.transfer(user, immediateAmount);
        Vesting.beginVesting(user, vestingAmount);
    }

    function migrate(uint256 amount) public {
        _migrate(msg.sender, amount);
    }
    
    function migrateAll() public {
        uint256 amount = PCT.balanceOf(msg.sender);
        _migrate(msg.sender, amount);
    }
}