// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title DaoAirdrop
 * @notice Contract which manages airdrops in MetaPlayerOne.
 */
contract DaoAirdrop is Pausable {
    struct Airdrop {
        uint256 uid;
        address owner_of;
        address dao_token_address;
        address token_address;
        uint256 amount;
        uint256 max_per_user;
        uint256 start_time;
        uint256 end_time;
        uint256 droped_amount;
    }
    struct Metadata {
        string name;
        string description;
        string file_uri;
    }

    Airdrop[] private _airdrops;

    mapping(uint256 => mapping(address => uint256)) private _airdrop_limit;
    mapping(uint256 => address[]) private _white_lists;

    constructor(address owner_of_) Pausable(owner_of_) {}

    event airdropCreated(
        uint256 uid,
        address owner_of,
        address[2] addresses,
        uint256 amount,
        uint256 max_per_user,
        uint256 start_time,
        uint256 end_time,
        string file_uri,
        string description,
        string name
    );
    event whitelistCreated(uint256 uid, address[] whitelist);
    event claimed(
        uint256 airdrop_uid,
        uint256 sold_amount,
        address eth_address
    );
    event withdrawed(uint256 airdrop_uid, uint256 amount);

    function createAirdrop(
        uint256 amount,
        address dao_token_address,
        address token_address,
        uint256 max_per_user,
        uint256 start_time,
        uint256 end_time,
        Metadata memory metadata
    ) public notPaused {
        require(
            IERC20(dao_token_address).balanceOf(msg.sender) > 0,
            "No permissions"
        );
        require(
            amount > max_per_user,
            "Max. limit per wallet is greater than total amount"
        );
        uint256 newAirdropUid = _airdrops.length;
        _airdrops.push(
            Airdrop(
                newAirdropUid,
                msg.sender,
                dao_token_address,
                token_address,
                amount,
                max_per_user,
                start_time,
                end_time,
                0
            )
        );
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
        emit airdropCreated(
            newAirdropUid,
            msg.sender,
            [dao_token_address, token_address],
            amount,
            max_per_user,
            start_time,
            end_time,
            metadata.file_uri,
            metadata.description,
            metadata.name
        );
    }

    function setWhiteList(
        uint256 airdrop_uid,
        address[] memory whitelist_
    ) public {
        require(msg.sender == _airdrops[airdrop_uid].owner_of, "No permission");
        _white_lists[airdrop_uid] = whitelist_;
        emit whitelistCreated(airdrop_uid, whitelist_);
    }

    function isMember(
        uint256 airdrop_uid_,
        address eth_address
    ) public view returns (bool) {
        if (_white_lists[airdrop_uid_].length == 0) return true;
        for (uint256 i = 0; i < _white_lists[airdrop_uid_].length; i++) {
            if (
                IERC20(_white_lists[airdrop_uid_][i]).balanceOf(eth_address) > 0
            ) return true;
        }
        return false;
    }

    function claim(uint256 airdrop_uid, uint256 amount) public notPaused {
        Airdrop memory airdrop = _airdrops[airdrop_uid];
        require(
            IERC20(airdrop.dao_token_address).balanceOf(msg.sender) > 0,
            "No permissions"
        );
        bool hasMembership = isMember(airdrop_uid, msg.sender);
        if (!hasMembership) revert("You has no whitelist tokens");
        require(
            _airdrop_limit[airdrop_uid][msg.sender] + amount <=
                airdrop.max_per_user,
            "Limit per user exeeded"
        );
        require(
            airdrop.droped_amount + amount <= airdrop.amount,
            "Drop limit exeeded"
        );
        require(airdrop.start_time <= block.timestamp, "Aidrop not started");
        require(
            airdrop.end_time >= block.timestamp,
            "Aidrop has been finished"
        );
        IERC20(airdrop.token_address).transfer(
            msg.sender,
            (amount * 975) / 1000
        );
        IERC20(airdrop.token_address).transfer(_owner_of, (amount * 25) / 1000);
        _airdrops[airdrop_uid].droped_amount += amount;
        _airdrop_limit[airdrop_uid][msg.sender] += amount;
        emit claimed(airdrop_uid, amount, msg.sender);
    }

    function withdraw(uint256 airdrop_uid) public notPaused {
        Airdrop memory aidrop = _airdrops[airdrop_uid];
        require(msg.sender == aidrop.owner_of, "No permission");
        require(aidrop.end_time < block.timestamp, "Not Finished");
        uint256 amount = aidrop.amount - aidrop.droped_amount;
        _airdrops[airdrop_uid].droped_amount = aidrop.amount;
        IERC20(aidrop.token_address).transfer(msg.sender, amount);
        emit withdrawed(airdrop_uid, amount);
    }
}
