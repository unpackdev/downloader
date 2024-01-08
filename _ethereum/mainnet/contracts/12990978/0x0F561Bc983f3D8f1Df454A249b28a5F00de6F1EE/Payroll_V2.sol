// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.

///@author Zapper
///@notice This contract splits shares among a group of recipients on a payroll. Payment schedules can be created
/// using paymentPeriods and timelock. E.g. For a bimonthly salary of 4,000 USDC, paymentPeriods = 2, timelock = 1209600

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract Payroll_V2 is Ownable {
    using SafeERC20 for IERC20;

    struct Payroll {
        // Payroll ID
        uint256 id;
        // ERC20 token used for payment for this payroll
        IERC20 paymentToken;
        // Recurring number of periods over which shares are distributed
        uint256 paymentPeriods;
        // Number of seconds to lock payment for subsequent to a distribution
        uint256 timelock;
        // Timestamp of most recent payment
        uint256 lastPayment;
        // Quantity of tokens owed to each recipient
        mapping(address => uint256) shares;
        // Quantity of tokens paid to each recipient
        mapping(address => uint256) released;
        // Total quantity of tokens owed to all recipients
        uint256 totalShares;
        // Total quantity of tokens paid to all recipients
        uint256 totalReleased;
        // Recipients on the payroll
        address[] recipients;
    }

    //Payroll managers
    mapping(address => bool) public managers;

    // Payroll ID => Payroll
    mapping(uint256 => Payroll) private payrolls;

    // Number of payrolls that exist
    uint256 public numPayrolls;

    // Pause and unpause payments
    bool public paused;

    // Only valid managers may manage this contract
    modifier onlyManagers {
        require(managers[msg.sender], "Unapproved manager");
        _;
    }

    // Only the owner may pause this contract
    modifier Pausable {
        require(paused == false, "Paused");
        _;
    }

    // Check for valid payrolls
    modifier validPayroll(uint256 payrollID) {
        require(payrollID < numPayrolls, "Invalid payroll");
        _;
    }

    event NewPayroll(
        uint256 payrollID,
        address paymentToken,
        uint256 paymentPeriods,
        uint256 timelock
    );
    event Payment(address recipient, uint256 shares, uint256 payrollID);
    event AddRecipient(address recipient, uint256 shares, uint256 payrollID);
    event RemoveRecipient(address recipient, uint256 payrollID);
    event UpdateRecipient(address recipient, uint256 shares, uint256 payrollID);
    event UpdatePaymentToken(address token, uint256 payrollID);
    event UpdatePaymentPeriod(uint256 paymentPeriod, uint256 payrollID);
    event UpdateTimelock(uint256 timelock, uint256 payrollID);

    /**
    @notice Initializes a new empty payroll
    @param paymentToken The ERC20 token with which to make payments
    @param paymentPeriods The number of payment periods to distribute the shares owed to each recipient by
    @param timelock The number of seconds to lock payments for subsequent to a distribution
    @return payrollID - The ID of the newly created payroll
    */
    function createPayroll(
        IERC20 paymentToken,
        uint256 paymentPeriods,
        uint256 timelock
    ) external onlyManagers returns (uint256) {
        require(paymentPeriods > 0, "Payment periods must be greater than 0");

        Payroll storage payroll = payrolls[numPayrolls];
        payroll.id = numPayrolls;
        payroll.paymentToken = paymentToken;
        payroll.paymentPeriods = paymentPeriods;
        payroll.timelock = timelock;

        emit NewPayroll(
            numPayrolls++,
            address(paymentToken),
            paymentPeriods,
            timelock
        );

        return numPayrolls;
    }

    /**
    @notice Adds a new recipient to a payroll given its ID
    @param payrollID The ID of the payroll
    @param recipient The new recipient's address
    @param shares The quantitiy of tokens owed to the recipient per epoch
    */
    function addRecipient(
        uint256 payrollID,
        address recipient,
        uint256 shares
    ) public onlyManagers validPayroll(payrollID) {
        Payroll storage payroll = payrolls[payrollID];

        require(
            payroll.shares[recipient] == 0,
            "Recipient exists, use updateRecipient instead"
        );
        require(shares > 0, "Amount cannot be 0!");

        payroll.recipients.push(recipient);
        payroll.shares[recipient] = shares;
        payroll.totalShares += shares;

        emit AddRecipient(recipient, shares, payrollID);
    }

    /**
    @notice Adds several new recipients to the payroll
    @param payrollID The ID of the payroll 
    @param recipients An arary of new recipient addresses
    @param shares An array of the quantitiy of tokens owed to each recipient per payment period
    */
    function addRecipients(
        uint256 payrollID,
        address[] calldata recipients,
        uint256[] calldata shares
    ) external onlyManagers validPayroll(payrollID) {
        require(
            recipients.length == shares.length,
            "Length of recipients does not match length of shares!"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            addRecipient(payrollID, recipients[i], shares[i]);
        }
    }

    /**
    @notice Removes a recipient from a payroll given its ID
    @param payrollID The ID of the payroll
    @param recipient The address of the recipient being removed
    */
    function removeRecipient(uint256 payrollID, address recipient)
        external
        onlyManagers
        validPayroll(payrollID)
    {
        Payroll storage payroll = payrolls[payrollID];

        require(payroll.shares[recipient] > 0, "Recipient does not exist");

        payroll.totalShares -= payroll.shares[recipient];
        payroll.shares[recipient] = 0;

        uint256 i;
        for (; i < payroll.recipients.length; i++) {
            if (payroll.recipients[i] == recipient) {
                break;
            }
        }

        payroll.recipients[i] = payroll.recipients[
            payroll.recipients.length - 1
        ];
        payroll.recipients.pop();

        emit RemoveRecipient(recipient, payrollID);
    }

    /**
    
    @notice Updates recipient's owed shares
    @param payrollID The ID of the payroll
    @param recipient The recipient's address
    @param shares The quantitiy of tokens owed to the recipient per payment period
    */
    function updateRecipient(
        uint256 payrollID,
        address recipient,
        uint256 shares
    ) public onlyManagers validPayroll(payrollID) {
        require(shares > 0, "Amount cannot be 0, use removeRecipient instead");

        Payroll storage payroll = payrolls[payrollID];

        require(payroll.shares[recipient] > 0, "Recipient does not exist");

        payroll.totalShares -= payroll.shares[recipient];
        payroll.totalShares += shares;

        payroll.shares[recipient] = shares;

        emit UpdateRecipient(recipient, shares, payrollID);
    }

    /**
    @notice Updates several recipients' owed shares
    @param payrollID The ID of the payroll
    @param recipients An arary of recipient addresses
    @param shares An array of the quantitiy of tokens owed to each recipient per epoch
    */
    function updateRecipients(
        uint256 payrollID,
        address[] calldata recipients,
        uint256[] calldata shares
    ) external onlyManagers validPayroll(payrollID) {
        require(
            recipients.length == shares.length,
            "Number of recipients does not match amounts!"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            updateRecipient(payrollID, recipients[i], shares[i]);
        }
    }

    /** 
    @notice Updates the payment token
    @param payrollID The ID of the payroll
    @param paymentToken The new ERC20 token with which to make payments
    */
    function updatePaymentToken(uint256 payrollID, IERC20 paymentToken)
        external
        onlyManagers
        validPayroll(payrollID)
    {
        payrolls[payrollID].paymentToken = paymentToken;

        emit UpdatePaymentToken(address(paymentToken), payrollID);
    }

    /** 
    @notice Updates the number of payment periods
    @param payrollID The ID of the payroll to add the recipients to
    @param paymentPeriod The new number of payment periods
    */
    function updatePaymentPeriods(uint256 payrollID, uint256 paymentPeriod)
        external
        onlyManagers
        validPayroll(payrollID)
    {
        payrolls[payrollID].paymentPeriods = paymentPeriod;

        emit UpdatePaymentPeriod(paymentPeriod, payrollID);
    }

    /** 
    @notice Updates the epoch (i.e. the number of days to divide payment period by)
    @param payrollID The ID of the payroll
    @param timelock The number of seconds to lock payment for following a distribution
    */
    function updateTimelock(uint256 payrollID, uint256 timelock)
        external
        onlyManagers
        validPayroll(payrollID)
    {
        payrolls[payrollID].timelock = timelock;

        emit UpdateTimelock(timelock, payrollID);
    }

    /** 
    @notice Gets the current timelock in seconds
    @param payrollID The ID of the payroll
    */
    function getTimelock(uint256 payrollID) external view returns (uint256) {
        return payrolls[payrollID].timelock;
    }

    /** 
    @notice Gets the payment token for a payroll
    @param payrollID The ID of the payroll
    */
    function getPaymentToken(uint256 payrollID)
        external
        view
        returns (address)
    {
        return address(payrolls[payrollID].paymentToken);
    }

    /** 
    @notice Returns the quantity of tokens owed to a recipient per pay period
    @param payrollID The ID of the payroll
    @param recipient The address of the recipient
    */
    function getRecipientShares(uint256 payrollID, address recipient)
        public
        view
        returns (uint256)
    {
        Payroll storage payroll = payrolls[payrollID];
        return payroll.shares[recipient] / payroll.paymentPeriods;
    }

    /** 
    @notice Returns the total quantity of tokens paid to the recipient
    @param payrollID The ID of the payroll
    @param recipient The address of the recipient
    */
    function getRecipientReleased(uint256 payrollID, address recipient)
        public
        view
        returns (uint256)
    {
        return payrolls[payrollID].released[recipient];
    }

    /** 
    @notice Returns the quantity of tokens owed to all recipients per pay period
    @param payrollID The ID of the payroll
    */
    function getTotalShares(uint256 payrollID) public view returns (uint256) {
        return
            payrolls[payrollID].totalShares /
            payrolls[payrollID].paymentPeriods;
    }

    /** 
    @notice Returns the quantity of tokens paid to all recipients
    @param payrollID The ID of the payroll
    */
    function getTotalReleased(uint256 payrollID) public view returns (uint256) {
        return payrolls[payrollID].totalReleased;
    }

    /** 
    @notice Returns the number of recipients on the payroll
    @param payrollID The ID of the payroll
    */
    function getNumRecipients(uint256 payrollID)
        external
        view
        returns (uint256)
    {
        return payrolls[payrollID].recipients.length;
    }

    /** 
    @notice Returns the timestamp of the next payment
    @param payrollID The ID of the payroll
    */
    function getNextPayment(uint256 payrollID) public view returns (uint256) {
        Payroll storage payroll = payrolls[payrollID];
        if (payroll.lastPayment == 0) return 0;
        return payroll.lastPayment + payroll.timelock;
    }

    /** 
    @notice Returns the timestamp of the last payment
    @param payrollID The ID of the payroll
    */
    function getLastPayment(uint256 payrollID) public view returns (uint256) {
        return payrolls[payrollID].lastPayment;
    }

    /** 
    @notice Pulls the total quantity of tokens owed to all recipients for the pay period
     and pays each recipient their share
    @dev This contract must have approval to transfer the payment token from the msg.sender
    @param payrollID The ID of the payroll
    */
    function pullPayment(uint256 payrollID)
        external
        Pausable
        onlyManagers
        validPayroll(payrollID)
        returns (uint256)
    {
        require(
            block.timestamp >= getNextPayment(payrollID),
            "Payment was recently made"
        );

        Payroll storage payroll = payrolls[payrollID];

        require(payroll.totalShares > 0, "No Payees");

        uint256 totalPaid;

        for (uint256 i = 0; i < payroll.recipients.length; i++) {
            address recipient = payroll.recipients[i];
            uint256 recipientShares = payroll.shares[recipient];
            uint256 recipientOwed = recipientShares / payroll.paymentPeriods;

            payroll.paymentToken.safeTransferFrom(
                msg.sender,
                recipient,
                recipientOwed
            );
            payroll.released[recipient] += recipientOwed;

            totalPaid += recipientOwed;

            emit Payment(recipient, recipientOwed, payrollID);
        }
        payroll.totalReleased += totalPaid;
        payroll.lastPayment = block.timestamp;

        return totalPaid;
    }

    /** 
    @notice Pushes the total quantity of tokens required for the pay period and pays each recipient their share
    @dev ensure timelock is appropriately set to prevent overpayment
    @dev This contract must possess the required quantity of tokens to pay all recipients on the payroll
    @param payrollID The ID of the payroll
    */
    function pushPayment(uint256 payrollID)
        external
        Pausable
        validPayroll(payrollID)
        returns (uint256)
    {
        uint256 totalOwed = getTotalShares(payrollID);

        Payroll storage payroll = payrolls[payrollID];

        require(payroll.totalShares > 0, "No Payees");

        require(
            payroll.paymentToken.balanceOf(address(this)) >= totalOwed,
            "Insufficient balance for payment"
        );

        require(
            block.timestamp >= getNextPayment(payrollID),
            "Payment was recently made"
        );

        uint256 totalPaid;

        for (uint256 i = 0; i < payroll.recipients.length; i++) {
            address recipient = payroll.recipients[i];
            uint256 recipientShares = payroll.shares[recipient];
            uint256 recipientOwed = recipientShares / payroll.paymentPeriods;

            payroll.paymentToken.safeTransfer(recipient, recipientOwed);
            payroll.released[recipient] += recipientOwed;

            emit Payment(recipient, recipientOwed, payrollID);
        }
        payroll.totalReleased += totalPaid;

        payroll.lastPayment = block.timestamp;

        return totalPaid;
    }

    /** 
    @notice Withdraws tokens from this contract
    @param _token The token to remove (0 address if ETH)
    */
    function withdrawTokens(address _token) external onlyManagers {
        if (_token == address(0)) {
            (bool success, ) =
                msg.sender.call{ value: address(this).balance }("");
            require(success, "Error sending ETH");
        } else {
            IERC20 token = IERC20(_token);
            token.safeTransfer(msg.sender, token.balanceOf(address(this)));
        }
    }

    /** 
    @notice Updates the payroll's managers
    @param manager The address of the manager
    @param enabled Set false to revoke permission or true to grant permission
    */
    function updateManagers(address manager, bool enabled) external onlyOwner {
        managers[manager] = enabled;
    }

    /** 
    @notice Pause or unpause payments
    */
    function toggleContractActive() external onlyOwner {
        paused = !paused;
    }
}
