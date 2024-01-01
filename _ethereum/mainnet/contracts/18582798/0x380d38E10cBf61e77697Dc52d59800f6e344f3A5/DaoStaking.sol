// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title DaoStaking
 * @notice Contract which manages daos' projects in MetaPlayerOne.
 */
contract DaoStaking is Pausable {
    struct Bank {
        uint256 uid;
        address dao_token_address;
        address token_address;
        address owner_of;
        uint256 amount;
        uint256 min_amount;
        uint256 max_amount;
        uint256 reserved;
        uint256 end_time;
    }
    struct Staking {
        uint256 uid;
        uint256 period_uid;
        address owner_of;
        uint256 amount_staked;
        uint256 amount_to_claim;
        uint256 start_time;
        bool resolved;
    }
    struct Period {
        uint256 uid;
        uint256 bank_uid;
        uint256 time;
        uint256 reward_percentage;
    }
    struct Metadata {
        string wallpaper_uri;
        string description;
        string title;
    }

    Bank[] private _banks;

    mapping(uint256 => Period[]) private _periods;
    mapping(uint256 => address[]) private _whitelists;
    mapping(uint256 => Staking[]) private _stakings;

    event bankCreated(
        uint256 uid,
        Metadata metadata,
        address[2] addresses,
        address owner_of,
        uint256 amount,
        uint256 min_amount,
        uint256 max_amount,
        uint256 start_time,
        uint256 end_time
    );
    event periodCreated(uint256 bank_uid, Period[] periods);
    event whitelistCreated(uint256 bank_uid, address[] whitelist);
    event stakingCreated(
        uint256 uid,
        uint256 bank_uid,
        uint256 period_uid,
        uint256 amount,
        uint256 amount_to_claim,
        uint256 start_time,
        address owner_of
    );
    event stakingResolved(uint256 uid, uint256 bank_uid, uint256 period_uid);
    event withdrawed(uint256 bank_uid);

    constructor(address owner_of_) Pausable(owner_of_) {}

    function createBank(
        Metadata memory metadata,
        address dao_token_address,
        address token_address,
        uint256 amount,
        uint256 min_amount,
        uint256 max_amount,
        uint256 start_time,
        uint256 end_time
    ) public notPaused {
        IERC20 token = IERC20(token_address);
        require(
            IERC20(dao_token_address).balanceOf(msg.sender) > 0,
            "No permission"
        );
        require(token.balanceOf(msg.sender) >= amount, "Not enough tokens");
        require(min_amount <= max_amount, "Min is greater than max");
        require(amount >= max_amount, "Max is greater than total");
        uint256 newBankUid = _banks.length;
        _banks.push(
            Bank(
                newBankUid,
                dao_token_address,
                token_address,
                msg.sender,
                amount,
                min_amount,
                max_amount,
                0,
                end_time
            )
        );
        token.transferFrom(msg.sender, address(this), amount);
        address[2] memory addresses = [dao_token_address, token_address];
        emit bankCreated(
            newBankUid,
            metadata,
            addresses,
            msg.sender,
            amount,
            min_amount,
            max_amount,
            start_time,
            end_time
        );
    }

    function setPeriods(
        uint256 bank_uid_,
        uint256[] memory times_,
        uint256[] memory periods_
    ) public {
        require(times_.length == periods_.length, "Invalid inputs");
        require(_periods[bank_uid_].length == 0, "You can't update periods");
        require(_banks[bank_uid_].owner_of == msg.sender, "Permission denied");
        for (uint256 i = 0; i < periods_.length; i++) {
            _periods[bank_uid_].push(
                Period(i, bank_uid_, times_[i], periods_[i])
            );
        }
        emit periodCreated(bank_uid_, _periods[bank_uid_]);
    }

    function setWhitelist(
        uint256 bank_uid_,
        address[] memory whitelist_
    ) public {
        Bank memory bank = _banks[bank_uid_];
        require(bank.owner_of == msg.sender, "Permission denied");
        _whitelists[bank_uid_] = whitelist_;
        emit whitelistCreated(bank_uid_, whitelist_);
    }

    function hasPermissions(
        uint256 bank_uid_,
        address user_address
    ) public view returns (bool) {
        Bank memory bank = _banks[bank_uid_];
        if (IERC20(bank.dao_token_address).balanceOf(user_address) == 0)
            return false;
        uint256 whitelist_length = _whitelists[bank_uid_].length;
        if (whitelist_length == 0) return true;
        for (uint256 i = 0; i < whitelist_length; i++) {
            if (IERC20(_whitelists[bank_uid_][i]).balanceOf(user_address) > 0)
                return true;
        }
        return false;
    }

    function stake(
        uint256 bank_uid_,
        uint256 period_uid_,
        uint256 amount_
    ) public notPaused {
        Bank memory bank = _banks[bank_uid_];
        Period memory period = _periods[bank_uid_][period_uid_];
        if (!hasPermissions(bank_uid_, msg.sender)) revert("No access");
        require(
            IERC20(bank.token_address).balanceOf(msg.sender) >= amount_,
            "Contract balance too low"
        );
        uint256 amount_to_claim = amount_ +
            (period.reward_percentage * amount_) /
            100;
        require(
            bank.reserved + amount_to_claim <= bank.amount,
            "Limit exeeded"
        );
        require(bank.min_amount <= amount_, "Amount too low");
        require(bank.max_amount >= amount_, "Amount too high");
        _banks[bank_uid_].reserved += amount_to_claim;
        IERC20(bank.token_address).transferFrom(
            msg.sender,
            address(this),
            amount_
        );
        uint256 newStakingUid = _stakings[period_uid_].length;
        _stakings[period_uid_].push(
            Staking(
                newStakingUid,
                period_uid_,
                msg.sender,
                amount_,
                amount_to_claim,
                block.timestamp,
                false
            )
        );
        emit stakingCreated(
            newStakingUid,
            bank_uid_,
            period_uid_,
            amount_,
            amount_to_claim,
            block.timestamp,
            msg.sender
        );
    }

    function claim(
        uint256 bank_uid_,
        uint256 period_uid_,
        uint256 staking_uid_
    ) public notPaused {
        if (!hasPermissions(bank_uid_, msg.sender)) revert("No access");
        Staking memory staking = _stakings[period_uid_][staking_uid_];
        Period memory period = _periods[bank_uid_][period_uid_];
        Bank memory bank = _banks[bank_uid_];
        require(staking.owner_of == msg.sender, "Not an owner");
        require(
            block.timestamp > staking.start_time + period.time,
            "Not finished"
        );
        require(!staking.resolved, "Already resolved");
        IERC20(bank.token_address).transfer(
            staking.owner_of,
            (staking.amount_to_claim * 975) / 1000
        );
        IERC20(bank.token_address).transfer(
            _owner_of,
            (staking.amount_to_claim * 25) / 1000
        );
        _stakings[period_uid_][staking_uid_].resolved = true;
        emit stakingResolved(staking_uid_, bank_uid_, period_uid_);
    }

    function withdraw(uint256 bank_uid) public notPaused {
        Bank memory bank = _banks[bank_uid];
        require(bank.owner_of == msg.sender, "Permission denied");
        require(bank.end_time < block.timestamp, "Not finished");
        uint256 amount = bank.amount - bank.reserved;
        _banks[bank_uid].reserved = bank.amount;
        IERC20(bank.token_address).transfer(msg.sender, amount);
        emit withdrawed(bank_uid);
    }
}
