// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Pausable.sol";

contract DaoAllocation is Pausable {
    struct Allocation {
        uint256 uid;
        address owner_of;
        address dao_token_address;
        address token_address;
        uint256 amount;
        uint256 min_purchase;
        uint256 max_purchase;
        uint256 sold_amount;
        uint256 price;
        uint256 start_time;
        uint256 end_time;
        bool is_private;
    }
    struct Metadata {
        string name;
        string description;
        string file_uri;
    }

    Allocation[] private _allocations;
    mapping(uint256 => address[]) private _white_lists;
    mapping(uint256 => mapping(address => uint256)) private _prices;
    mapping(uint256 => mapping(address => uint256)) private _airdrop_limit;

    constructor(address owner_of_) Pausable(owner_of_) {}

    event allocationCreated(
        uint256 uid,
        address[3] addresses,
        uint256 amount,
        uint256 price,
        uint256 min_purchase,
        uint256 max_purchase,
        uint256 sold_amount,
        Metadata metadata,
        uint256 start_time,
        uint256 end_time,
        bool is_private
    );
    event whitelistCreated(uint256 uid, address[] whitelist, uint256[] prices);
    event claimed(
        uint256 allocation_uid,
        uint256 sold_amount,
        address eth_address,
        uint256 price
    );
    event withdrawed(uint256 allocation_uid, uint256 amount);

    function createAllocation(
        uint256 amount,
        address dao_token_address,
        address token_address,
        uint256 min_purchase,
        uint256 max_purchase,
        uint256 price,
        uint256 start_time,
        uint256 end_time,
        bool is_private,
        Metadata memory metadata
    ) public notPaused {
        require(
            IERC20(dao_token_address).balanceOf(msg.sender) > 0,
            "No permissions"
        );
        require(
            amount >= min_purchase,
            "Min. purchase is greater than total amount"
        );
        require(
            amount >= max_purchase,
            "Max. purchase is greater than total amount"
        );
        uint256 newAllocationUid = _allocations.length;
        _allocations.push(
            Allocation(
                newAllocationUid,
                msg.sender,
                dao_token_address,
                token_address,
                amount,
                min_purchase,
                max_purchase,
                0,
                price,
                start_time,
                end_time,
                is_private
            )
        );
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
        emit allocationCreated(
            newAllocationUid,
            [msg.sender, dao_token_address, token_address],
            amount,
            price,
            min_purchase,
            max_purchase,
            0,
            metadata,
            start_time,
            end_time,
            is_private
        );
    }

    function setWhiteList(
        uint256 allocation_uid_,
        address[] memory whitelist_,
        uint256[] memory price_
    ) public {
        require(
            _allocations[allocation_uid_].owner_of == msg.sender,
            "No permissions"
        );
        require(whitelist_.length == price_.length, "Not valid inputs");
        _white_lists[allocation_uid_] = whitelist_;
        for (uint256 i = 0; i < whitelist_.length; i++) {
            _prices[allocation_uid_][whitelist_[i]] = price_[i];
        }
        emit whitelistCreated(allocation_uid_, whitelist_, price_);
    }

    function getPrice(
        uint256 allocation_uid,
        address eth_address
    ) public view returns (uint256) {
        uint256 min_price = _allocations[allocation_uid].price;
        for (uint256 i = 0; i < _white_lists[allocation_uid].length; i++) {
            if (
                IERC20(_white_lists[allocation_uid][i]).balanceOf(eth_address) >
                0 &&
                min_price >
                _prices[allocation_uid][_white_lists[allocation_uid][i]]
            )
                min_price = _prices[allocation_uid][
                    _white_lists[allocation_uid][i]
                ];
        }
        return min_price;
    }

    function claim(
        uint256 allocation_uid,
        uint256 amount
    ) public payable notPaused {
        Allocation memory allocation = _allocations[allocation_uid];
        if (allocation.is_private) {
            require(
                IERC20(allocation.dao_token_address).balanceOf(msg.sender) > 0,
                "No permissions"
            );
        }
        require(
            _airdrop_limit[allocation_uid][msg.sender] + amount <=
                allocation.max_purchase,
            "Limit per user exeeded"
        );
        require(
            _airdrop_limit[allocation_uid][msg.sender] + amount >=
                allocation.min_purchase,
            "Not enough tokens for buy"
        );
        require(
            allocation.start_time <= block.timestamp,
            "Allocation not started"
        );
        require(
            allocation.end_time >= block.timestamp,
            "Allocation has been finished"
        );
        require(
            allocation.sold_amount + amount <= allocation.amount,
            "Limit exeeded"
        );
        uint256 price = getPrice(allocation_uid, msg.sender);
        require(
            msg.value >= amount * price / 1 ether,
            "Not enough funds send"
        );
        IERC20(allocation.token_address).transfer(
            msg.sender,
            (amount * 975) / 1000
        );
        IERC20(allocation.token_address).transfer(
            _owner_of,
            (amount * 25) / 1000
        );
        _allocations[allocation_uid].sold_amount += amount;
        _airdrop_limit[allocation_uid][msg.sender] += amount;
        payable(allocation.owner_of).transfer(msg.value);
        emit claimed(allocation_uid, amount, msg.sender, price);
    }

    function withdraw(uint256 allocation_uid) public notPaused {
        Allocation memory allocation = _allocations[allocation_uid];
        require(msg.sender == allocation.owner_of, "No permission");
        require(allocation.end_time < block.timestamp, "Not Finished");
        uint256 amount = allocation.amount - allocation.sold_amount;
        _allocations[allocation_uid].sold_amount = allocation.amount;
        IERC20(allocation.token_address).transfer(msg.sender, amount);
        emit withdrawed(allocation_uid, amount);
    }
}
