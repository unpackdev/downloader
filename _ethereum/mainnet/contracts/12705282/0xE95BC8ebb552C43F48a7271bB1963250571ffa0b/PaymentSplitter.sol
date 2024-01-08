// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./AddressUpgradeable.sol";
import "./Structs.sol";

contract PaymentSplitter is Context {
    using AddressUpgradeable for address;

    address private _owner;

    event PayeeAdded(address account, string role);

    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(uint256 amount, uint256 tokenId);

    Structs.RoyaltyReceiver[] private _royaltyReceivers;
    uint256 private _tokenId;

    uint256 private highestPrice;

    constructor(
        Structs.RoyaltyReceiver[] memory royaltyReceivers,
        uint256 tokenId
    ) payable {
        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            require(
                bytes(royaltyReceivers[i].role).length > 0,
                "role is empty"
            );
            require(
                royaltyReceivers[i].percentage > 0 ||
                royaltyReceivers[i].fixedCut > 0,
                "no royalties"
            );
            _royaltyReceivers.push(
                royaltyReceivers[i]
            );
        }
        _tokenId = tokenId;

        _owner = _msgSender();
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "PS: caller is not the owner");
        _;
    }

    function hasRoyaltyReceivers() external view onlyOwner returns (bool) {
        return _royaltyReceivers.length > 0;
    }

    function addPayee(
        Structs.RoyaltyReceiver memory royaltyReceiver
    ) external onlyOwner {
        require(royaltyReceiver.wallet != address(0),
            "addPayee: wallet is the zero address"
        );
        require(
            royaltyReceiver.percentage > 0 || royaltyReceiver.fixedCut > 0,
            "addPayee: shares are 0"
        );

        _royaltyReceivers.push(
            royaltyReceiver
        );

        emit PayeeAdded(royaltyReceiver.wallet, royaltyReceiver.role);
    }

    function _removeRoyaltyReceiver(
        address payee
    ) private {
        for (uint256 i = 0; i < _royaltyReceivers.length; i++) {
            if (_royaltyReceivers[i].wallet == payee) {
                if (i == _royaltyReceivers.length - 1) {
                    _royaltyReceivers.pop();
                } else {
                    for (uint256 j = i; j < _royaltyReceivers.length - 1; j++) {
                        _royaltyReceivers[j] = _royaltyReceivers[j + 1];
                    }
                    _royaltyReceivers.pop();
                }
            }
        }
    }

    receive() external payable {
        emit PaymentReceived(msg.value, _tokenId);
    }

    function _calculatePercentage(
        uint256 number,
        uint256 percentage
    ) private pure returns (uint256) {
        // https://ethereum.stackexchange.com/a/55702
        // https://www.investopedia.com/terms/b/basispoint.asp
        return number * percentage / 10000;
    }

    function calculatePayment(
        uint256 totalReceived,
        uint256 percentage,
        uint256 fixedCut,
        uint256 CAPPS
    ) private pure returns (uint256) {
        require(totalReceived > 0, "release amount == 0");
        require(
            percentage > 0 || fixedCut > 0 || CAPPS > 0,
            "no royalties to send"
        );

        return _calculatePercentage(totalReceived, percentage) + fixedCut + CAPPS;
    }

    function releasePayment(
        uint256 currentPaymentFunds,
        address payable paymentReceiver
    ) external onlyOwner {
        uint256 released = 0;

        if (_royaltyReceivers.length > 0) {
            uint256 CAPPS = 0;
            if (currentPaymentFunds > highestPrice && highestPrice > 0) {
                CAPPS = currentPaymentFunds - highestPrice;
            }

            for (uint256 i = 0; i < _royaltyReceivers.length; i++) {
                uint256 CAPPSShare = 0;
                if (CAPPS > 0) {
                    CAPPSShare = _calculatePercentage(
                        CAPPS,
                        _royaltyReceivers[i].CAPPS
                    );
                }

                Structs.RoyaltyReceiver memory currentRoyaltyReceiver = _royaltyReceivers[i];

                if (
                    _royaltyReceivers[i].percentage !=
                    _royaltyReceivers[i].resalePercentage
                ) {
                    _royaltyReceivers[i].percentage =
                        _royaltyReceivers[i].resalePercentage;
                    if (
                        _royaltyReceivers[i].percentage == 0 &&
                        _royaltyReceivers[i].fixedCut == 0 &&
                        _royaltyReceivers[i].CAPPS == 0
                    ) {
                        _removeRoyaltyReceiver(_royaltyReceivers[i].wallet);
                    }
                }

                if (
                    currentRoyaltyReceiver.percentage > 0 ||
                    currentRoyaltyReceiver.fixedCut > 0 ||
                    CAPPSShare > 0
                ) {
                    uint256 payment = calculatePayment(
                        currentPaymentFunds,
                        currentRoyaltyReceiver.percentage,
                        currentRoyaltyReceiver.fixedCut,
                        CAPPSShare
                    );
                    released += payment;

                    emit PaymentReleased(currentRoyaltyReceiver.wallet, payment);
                    AddressUpgradeable.sendValue(currentRoyaltyReceiver.wallet, payment);
                }
            }

            if (currentPaymentFunds > highestPrice) {
                highestPrice = currentPaymentFunds;
            }
        }

        if (currentPaymentFunds - released > 0) {
            emit PaymentReleased(paymentReceiver, currentPaymentFunds - released);
            AddressUpgradeable.sendValue(paymentReceiver, currentPaymentFunds - released);
        }
    }
}