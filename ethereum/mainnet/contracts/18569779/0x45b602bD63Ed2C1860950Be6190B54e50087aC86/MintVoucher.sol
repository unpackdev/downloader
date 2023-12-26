// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "./SafeERC20.sol";
import "./MintVoucherVerification.sol";
import "./Helper.sol";

abstract contract MintVoucherContract is MintVoucherVerification {
    using SafeERC20 for IERC20;

    /**********************************************************************************************************
    EXTERNAL
    **********************************************************************************************************/

    /**
     * @dev Cancel a voucher by providing the voucher nonce
     * @dev This will make all vouchers with an equal or lower nonce invalid
     * @param voucherNonce The nonce of the voucher that should be canceled
     */
    function cancelVoucher(uint256 voucherNonce) external {
        updateLastNonce(_msgSender(), voucherNonce);
        emit VoucherCancelled(_msgSender(), voucherNonce);
    }

    /**********************************************************************************************************
    INTERNAL
    **********************************************************************************************************/

    /**
     * @dev Mint an NFT with a valid MintVoucher and signature
     * @param voucher The MintVoucher that contains the specific mint details
     * @param signature The signature that must originate from an authorized signer
     */
    function _mintWithVoucher(MintVoucher calldata voucher, bytes calldata signature) internal virtual {
        // cannot use an expired voucher
        if (voucher.expiry < block.timestamp) {
            revert VoucherIsExpired();
        }

        verifySignature(
            voucher.netRecipient,
            voucher.initialRecipient,
            voucher.initialRecipientAmount,
            voucher.quantity,
            voucher.nonce,
            voucher.expiry,
            voucher.price,
            // 721A token id=0, auto incremented by that smart contract
            voucher.tokenId,
            voucher.currency,
            signature
        );

        // This is how we prevent replay by tracking the nonce
        updateLastNonce(_msgSender(), voucher.nonce);

        if (voucher.currency == address(0)) {
            _handleEthPayment(voucher);
        } else {
            _handleERC20Payment(voucher);
        }

        _handleMint(_msgSender(), voucher);

        emit VoucherRedeemed(signature);
    }

    /**
     * @dev Caller inside _mintWithVoucher function
     * @param to The address to send the NFT token to
     * @param voucher The MintVoucher that contains the specific mint details
     */
    function _handleMint(address to, MintVoucher calldata voucher) internal virtual;

    /**
     * @dev Handle ETH payments
     * @param voucher The MintVoucher that contains the specific mint details
     */
    function _handleEthPayment(MintVoucher calldata voucher) internal {
        if ((voucher.price * voucher.quantity) > msg.value) {
            revert CommonError.InsufficientPayment();
        }

        if (msg.value > 0) {
            // transfer funds to mutliple recipients, as needed
            if (voucher.initialRecipientAmount > msg.value) {
                revert CommonError.InvalidPaymentAmount();
            }
            if (voucher.initialRecipientAmount > 0) {
                if (voucher.initialRecipient == address(0)) {
                    revert CommonError.CannotBeZeroAddress();
                }
                Address.sendValue(payable(voucher.initialRecipient), voucher.initialRecipientAmount);
            }
            if (msg.value > voucher.initialRecipientAmount) {
                if (voucher.netRecipient == address(0)) {
                    revert CommonError.CannotBeZeroAddress();
                }
                Address.sendValue(payable(voucher.netRecipient), msg.value - voucher.initialRecipientAmount);
            }
        }
    }

    /**
     * @dev Handle an ERC20 payments
     * @param voucher The MintVoucher that contains the specific mint details
     */
    function _handleERC20Payment(MintVoucher calldata voucher) internal {
        if ((voucher.price * voucher.quantity) < 0) {
            revert CommonError.InvalidVoucher();
        }

        if (voucher.initialRecipientAmount > (voucher.price * voucher.quantity)) {
            revert CommonError.InvalidPaymentAmount();
        }
        if (voucher.initialRecipientAmount > 0) {
            if (voucher.initialRecipient == address(0)) {
                revert CommonError.CannotBeZeroAddress();
            }
            IERC20(voucher.currency).safeTransferFrom(
                _msgSender(),
                voucher.initialRecipient,
                voucher.initialRecipientAmount
            );
        }
        if ((voucher.price * voucher.quantity) > voucher.initialRecipientAmount) {
            if (voucher.netRecipient == address(0)) {
                revert CommonError.CannotBeZeroAddress();
            }
            IERC20(voucher.currency).safeTransferFrom(
                _msgSender(),
                voucher.netRecipient,
                (voucher.price * voucher.quantity) - voucher.initialRecipientAmount
            );
        }
    }
}
