// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./PaymentSplitterUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC2771ContextUpgradeable.sol";

import "./IMMFee.sol";
import "./IMMContract.sol";

contract PaymentSplit is
    ERC2771ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PaymentSplitterUpgradeable
{
    // template type and version
    bytes32 private constant MODULE_TYPE = bytes32("PaymentSplit");
    uint256 private constant VERSION = 1;

    // Max bps in the magicmynt system
    uint128 private constant MAX_BPS = 10_000;

    // contract name
    string name;

    // Magic Mynt contract with fee related information
    IMMFee public immutable platformFee;

    constructor(address _mmFee) {
        platformFee = IMMFee(_mmFee);
    }

    function initialize(
        address owner,
        address trustedForwarder,
        string memory _name,
        address[] memory payees,
        uint256[] memory shares
    ) public initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init(trustedForwarder);
        __PaymentSplitter_init(payees, shares);
        _setOwnership(owner);

        name = _name;
    }

    /***********************************************************************
                                    CONTRACT METADATA
     *************************************************************************/

    // Returns the module type of the template.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    // Returns the version of the template.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    function platformFeeInfo() internal view returns (address, uint256) {
        (address feeRecipient, uint256 feeBps) = platformFee.getFeeInfo();
        return (feeRecipient, feeBps);
    }

    function distribute() public virtual {
        uint256 count = payeeCount();
        for (uint256 i = 0; i < count; i++) {
            _release(payable(payee(i)));
        }
    }

    function release(address payable account) public virtual override {
        uint256 payment = _release(account);
        require(payment != 0, "PaymentSplitter: account is not due payment");
    }

    function _release(address payable account) internal returns (uint256) {
        require(shares(account) > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(account)
        );

        if (payment == 0) {
            return 0;
        }

        _released[account] += payment;
        _totalReleased += payment;

        // platform fees
        uint256 fee = 0;
        (address feeRecipient, uint256 feeBps) = platformFee.getFeeInfo();
        if (feeRecipient != address(0) && feeBps > 0) {
            fee = (payment * feeBps) / MAX_BPS;
            AddressUpgradeable.sendValue(payable(feeRecipient), fee);
        }

        AddressUpgradeable.sendValue(account, payment - fee);
        emit PaymentReleased(account, payment);

        return payment;
    }

    function _setOwnership(address owner) internal onlyInitializing {
        _transferOwnership(owner);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
