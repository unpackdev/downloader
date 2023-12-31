// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IERC20Upgradeable.sol";
import "./BaseUpgradeable.sol";
import "./BusinessAddressesUpgradeable.sol";
import "./PrimarySaleUpgradeable.sol";
import "./SafeTransfer.sol";
import "./BitMaps.sol";
import "./Constants.sol";

abstract contract GoodsPaymentUpgradeable is BaseUpgradeable, BusinessAddressesUpgradeable, PrimarySaleUpgradeable {
    error Payment_InvalidToken();
    error Payment__InsufficientBalance();

    using BitMaps for BitMaps.BitMap;

    event PaymentProcessed(address collection, uint256[] tokenIds, uint256 newItems);

    mapping(address => uint256) private _paymentAmounts;
    mapping(address => BitMaps.BitMap) private _isCollectionUsed;

    function __GoodsPayment_init(address token_, uint256 paymentAmounts_) internal onlyInitializing {
        __GoodsPayment_init_unchained(token_, paymentAmounts_);
    }

    function __GoodsPayment_init_unchained(address token_, uint256 paymentAmounts_) internal onlyInitializing {
        _paymentAmounts[token_] = paymentAmounts_;
    }

    function paymentAmount(address token_) external view returns (uint256) {
        return _paymentAmounts[token_];
    }

    function calculatePaymentAmounts(
        address paymentToken_,
        address collection_,
        uint256[] calldata tokenIds_
    ) external view returns (uint256) {
        uint256 total;
        uint256 length = tokenIds_.length;
        uint256 amount = _paymentAmounts[paymentToken_];

        require(amount != 0, "Invalid token");

        for (uint i = 0; i < length; ) {
            unchecked {
                if (!_isCollectionUsed[collection_].get(tokenIds_[i])) ++total;
                ++i;
            }
        }

        return amount * total;
    }

    function setPaymentPricePerItem(address token_, uint256 paymentAmounts_) external onlyRole(OPERATOR_ROLE) {
        _setPaymentPricePerItem(token_, paymentAmounts_);
    }

    function processPayment(address paymentToken_, address collection_, uint256[] calldata tokenIds_) external payable {
        _processPayment(paymentToken_, collection_, tokenIds_);
    }

    function _calculatePaymentAmounts(
        address paymentToken_,
        address collection_,
        uint256[] calldata tokenIds_
    ) internal returns (uint256, uint256) {
        uint256 total;
        uint256 length = tokenIds_.length;

        for (uint i = 0; i < length; ) {
            unchecked {
                if (!_isCollectionUsed[collection_].get(tokenIds_[i])) {
                    _isCollectionUsed[collection_].set(tokenIds_[i]);
                    total += 1;
                }
                ++i;
            }
        }

        return (_paymentAmounts[paymentToken_] * total, total);
    }

    function _processPayment(address paymentToken_, address collection_, uint256[] calldata tokenIds_) internal {
        uint256 value;
        address payer = _msgSender();

        // _onlyBusiness(payer);

        (uint256 totalAmount, uint256 totalItems) = _calculatePaymentAmounts(paymentToken_, collection_, tokenIds_);

        if (totalAmount == 0) revert Payment_InvalidToken();

        if (paymentToken_ == address(0)) {
            value = msg.value;
            if (value < totalAmount) revert Payment__InsufficientBalance();
            SafeTransferLib.safeTransferETH(_recipient, value);
        } else {
            value = IERC20Upgradeable(paymentToken_).allowance(payer, address(this));
            if (value < totalAmount) revert Payment__InsufficientBalance();
            SafeTransferLib.safeTransferFrom(paymentToken_, payer, _recipient, totalAmount);
        }

        emit PaymentProcessed(collection_, tokenIds_, totalItems);
    }

    function _setPaymentPricePerItem(address token_, uint256 paymentAmounts_) internal {
        _paymentAmounts[token_] = paymentAmounts_;
    }
}
