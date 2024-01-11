// SPDX-License-Identifier: AGPL-3.0-only
// ERC20 Extensions v1.1.1
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IVestedToken.sol";

struct VestingPeriod {
    uint256 cliffTimestamp;
    uint256 cliffAmount; // in myriad
    uint256 duration;
}

struct VestedBalance {
    uint256 vestingId;
    uint256 amount; // in wei
}

abstract contract VestedToken is IVestedToken, ERC20 {
    uint256 private _vestingCounter;
    mapping(uint256 => VestingPeriod) public override vestingPeriods;
    mapping(address => VestedBalance) public override vestedBalances;
    mapping(address => uint256) public vestingAdmins;
    mapping(address => bool) public recipientWhitelist;

    function lockedTokens(address account) public view virtual returns (uint256) {
        VestedBalance storage vestingBalance = vestedBalances[account];
        uint256 id = vestingBalance.vestingId;
        uint256 amount = vestingBalance.amount;
        if (id == 0) return 0;

        VestingPeriod storage vestingPeriod = vestingPeriods[id];
        uint256 cliffTimestamp = vestingPeriod.cliffTimestamp;
        uint256 duration = vestingPeriod.duration;
        if (cliffTimestamp > block.timestamp) return amount;
        if (block.timestamp >= cliffTimestamp + duration) return 0;

        uint256 cliffAmount = (amount * (10000 - vestingPeriod.cliffAmount)) / 10000;
        uint256 vestedAmount = (cliffAmount * (block.timestamp - cliffTimestamp)) / duration;
        return cliffAmount - vestedAmount;
    }

    function _setupSchedule(
        uint256 cliff,
        uint256 cliffAmount,
        uint256 duration,
        address vestingAdmin
    ) internal virtual {
        require(cliffAmount <= 10000, "MAX_CLIFF");
        uint256 vestingId = ++_vestingCounter;
        vestingPeriods[vestingId] = VestingPeriod(cliff, cliffAmount, duration);
        require(vestingAdmins[vestingAdmin] == 0, "VESTING_ADMIN_ALREADY_SET");
        vestingAdmins[vestingAdmin] = vestingId;
        emit VestingScheduleAdded(vestingId, cliff, cliffAmount, duration);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        VestedBalance storage vestingBalance = vestedBalances[to];
        uint256 id = vestingAdmins[from];
        if (id != 0) {
            // if sender is vesting admin, setup vesting balance for receiving address
            require(vestingBalance.vestingId == 0, "USER_ALREADY_VESTED");
            vestingBalance.vestingId = id;
            vestingBalance.amount = amount;
            emit TokensVested(id, to, amount);
        } else {
            if (!recipientWhitelist[to]) {
                require(balanceOf(from) >= lockedTokens(from), "TOKENS_VESTED");
            }
        }
    }
}
