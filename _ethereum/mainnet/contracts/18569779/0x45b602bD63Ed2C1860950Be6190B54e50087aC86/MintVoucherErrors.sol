// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

/**
 * @title MintVoucherErrors
 * @notice MintVoucherErrors contatins errors related to MintVoucher verification
 */
interface MintVoucherErrors {
    /**
     * @dev Revert with an error when attempting to mint with an invalid voucher.
     *      This may be due to many reasons, including, but not limited to, an
     *      attempting to mint a voucher signed by an unauthorized signer,
     *      insufficient funds sent, attempting to mint more than allocated, and
     *      attempting to mint a different buyer's voucher,
     */
    error InvalidSignature();

    /**
     * @dev Revert with an error when attempting to mint with an expired voucher.
     */
    error VoucherIsExpired();
    /**
     * @dev Revert with an error when attempting to mint a voucher that has
     *      already been filled or canceled.
     */
    error VoucherNonceTooLow();
}
