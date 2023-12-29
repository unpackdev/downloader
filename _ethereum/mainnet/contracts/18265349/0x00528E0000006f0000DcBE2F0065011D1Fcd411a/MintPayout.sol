// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./IMintPayout.sol";
import "./IMintContract.sol";
import "./Version.sol";
import "./MintPayoutReasons.sol";

contract MintPayout is IMintPayout, Version, Ownable {
    /// @inheritdoc IMintPayout
    uint256 public protocolFee;
    /// @inheritdoc IMintPayout
    address public constant protocolFeeRecipientAccount = address(0x4444444444444444444444444444444444444444);

    /// @inheritdoc IMintPayout
    mapping(address => uint256) public balanceOf;

    error InvalidAddress();
    error InvalidArrayLength();
    error IncorrectDepositAmount();
    error InvalidWithdrawAmount();
    error TransferFailed();

    constructor() Version(1) {
        _initializeOwner(tx.origin);
    }

    /// @inheritdoc IMintPayout
    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }

    /// @inheritdoc IMintPayout
    function setProtocolFee(uint256 _protocolFee) external onlyOwner {
        protocolFee = _protocolFee;
        emit ProtocolFeeUpdated(_protocolFee);
    }

    /// @inheritdoc IMintPayout
    function withdrawProtocolFee(address to, uint256 amount) external onlyOwner {
        _withdraw(protocolFeeRecipientAccount, to, amount);
    }

    /// @inheritdoc IMintPayout
    function mintDeposit(address mintContract, address minter, address referrer, uint256 quantity) external payable {
        if (mintContract == address(0)) revert InvalidAddress();
        if (quantity == 0) revert IncorrectDepositAmount();
        if (msg.value == 0) revert IncorrectDepositAmount();

        uint256 protocolPayout = protocolFee * quantity;
        uint256 referralPayout;
        if (referrer != address(0)) {
            referralPayout = protocolPayout / 2;
            protocolPayout = referralPayout;
        }

        if (msg.value < protocolPayout + referralPayout) revert IncorrectDepositAmount();

        uint256 creatorPayout = msg.value - protocolPayout - referralPayout;
        address creator;

        if (creatorPayout > 0) {
            creator = IMintContract(mintContract).payoutRecipient();
            if (creator == address(0)) {
                creator = protocolFeeRecipientAccount;
            }

            _deposit(msg.sender, creator, PURCHASE_AMOUNT_REASON, creatorPayout);
        }

        if (referralPayout > 0) {
            _deposit(msg.sender, referrer, MINT_REFERRAL_REASON, referralPayout);
        }

        if (protocolPayout > 0) {
            _deposit(msg.sender, protocolFeeRecipientAccount, PROTOCOL_FEE_REASON, protocolPayout);
        }

        emit MintDeposit(
            msg.sender,
            mintContract,
            minter,
            referrer,
            creator,
            creatorPayout,
            referralPayout,
            protocolPayout,
            msg.value,
            quantity,
            protocolFee
        );
    }

    /// @inheritdoc IMintPayout
    function deposit(address to, bytes4 reason) external payable {
        if (to == address(0)) revert InvalidAddress();
        _deposit(msg.sender, to, reason, msg.value);
    }

    /// @inheritdoc IMintPayout
    function depositBatch(address[] calldata recipients, uint256[] calldata amounts, bytes4[] calldata reasons)
        external
        payable
    {
        uint256 numRecipients = recipients.length;
        if (numRecipients != amounts.length || numRecipients != reasons.length) {
            revert InvalidArrayLength();
        }

        uint256 expectedTotalValue;
        for (uint256 i; i < numRecipients;) {
            expectedTotalValue += amounts[i];

            unchecked {
                ++i;
            }
        }

        if (msg.value != expectedTotalValue) revert IncorrectDepositAmount();

        address currentRecipient;
        uint256 currentAmount;
        for (uint256 i; i < numRecipients;) {
            currentRecipient = recipients[i];
            currentAmount = amounts[i];

            if (currentRecipient == address(0)) revert InvalidAddress();

            _deposit(msg.sender, currentRecipient, reasons[i], currentAmount);

            unchecked {
                ++i;
            }
        }
    }

    function _deposit(address from, address to, bytes4 reason, uint256 amount) internal {
        balanceOf[to] += amount;
        emit Deposit(from, to, reason, amount);
    }

    /// @inheritdoc IMintPayout
    function withdraw(address to, uint256 amount) external {
        _withdraw(msg.sender, to, amount);
    }

    /// @inheritdoc IMintPayout
    function withdrawAll(address to) external {
        _withdraw(msg.sender, to, balanceOf[msg.sender]);
    }

    function _withdraw(address from, address to, uint256 amount) internal {
        if (to == address(0)) revert InvalidAddress();

        if (amount == 0 || amount > balanceOf[from]) revert InvalidWithdrawAmount();

        balanceOf[from] -= amount;
        emit Withdraw(from, to, amount);

        (bool success,) = to.call{value: amount}("");
        if (!success) revert TransferFailed();
    }
}
