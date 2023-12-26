// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

/**
 * @dev This is the interface for the MintVoucherCapability
 */
interface MintVoucherCapability {
    event VoucherRedeemed(bytes signature);
    event VoucherCancelled(address minter, uint256 nonce);
}
