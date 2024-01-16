// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./PrimarySaleSplitter.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IMMFee.sol";

abstract contract PrimarySale is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PrimarySaleSplitter
{
    // Max bps in the magicmynt system
    uint128 private constant MAX_BPS = 10_000;

    // Magic Mynt contract with fee related information
    IMMFee internal platformFee;

    function __PrimarySale_init(
        address _mmFee,
        address[] memory payees,
        uint256[] memory shares
    ) internal onlyInitializing {
        platformFee = IMMFee(_mmFee);
        __PrimarySaleSplitter_init(payees, shares);
    }

    /***********************************************************************
                                    CONTRACT METADATA
     *************************************************************************/

    function platformFeeInfo() public view returns (address, uint256) {
        (address feeRecipient, uint256 feeBps) = platformFee.getFeeInfo();
        return (feeRecipient, feeBps);
    }

    function withdraw() public virtual onlyOwner nonReentrant {
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
}
