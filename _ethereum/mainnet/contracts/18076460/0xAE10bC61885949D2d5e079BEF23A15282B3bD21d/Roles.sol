// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IRoles.sol";
import "./Errors.sol";

contract Roles is IRoles {
    mapping (address => bool) internal addressToAdmin;
    address public manager;

    constructor() {
        manager = msg.sender;
    }

    modifier isManager(address account) {
        require(account == manager, errors.NOT_AUTHORIZED);
        _;
    }

    modifier isAdmin(address account) {
        require(addressToAdmin[account] || account == manager, errors.NOT_AUTHORIZED);
        _;
    }

    function setAdmin(
        address account,
        bool admin
    )
        external
        override
        isManager(msg.sender)
    {
        require(account != address(0), errors.ZERO_ADDRESS);
        addressToAdmin[account] = admin;
        emit UpdatedAdmin(account, admin);
    }

    function renounceAdmin()
        external
        override
        isAdmin(msg.sender)
    {
        require(msg.sender != manager, errors.INVALID_ADDRESS);
        addressToAdmin[msg.sender] = false;
        emit UpdatedAdmin(msg.sender, false);
    }

    function updateManager(
        address account
    )
        external
        override
        isManager(msg.sender)
    {
        require(account != address(0), errors.ZERO_ADDRESS);
        manager = account;
        emit UpdatedContractManager(account);
    }

    function isAccountAdmin(
        address account
    )
        external
        view
        returns(bool)
    {
        return addressToAdmin[account];
    }
}
