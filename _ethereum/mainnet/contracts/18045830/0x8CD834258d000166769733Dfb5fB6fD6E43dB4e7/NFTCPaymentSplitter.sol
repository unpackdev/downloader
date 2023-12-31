// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-contracts
import "./NFTCPaymentSplitterBase.sol";

/**
 * @title NFTCPaymentSplitter
 * @author @NiftyMike | @NFTCulture
 * @dev NFTC's Implementation of a Payment Splitter
 *
 * Underlying is based on OpenZeppelin Contracts v4.8.0 (finance/PaymentSplitter.sol)
 */
abstract contract NFTCPaymentSplitter is NFTCPaymentSplitterBase {
    /**
     * @dev Overrides release() method, so that it can only be called by owner.
     * @notice Owner: Release funds to a specific address.
     *
     * @param account Payable address that will receive funds.
     */
    function release(address payable account) public override {
        _isOwner();

        _release(account);
    }

    /**
     * @dev Triggers a transfer to caller's address of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     * @notice Sender: request payment.
     */
    function releaseToSelf() public {
        _release(payable(_msgSender()));
    }

    function _isOwner() internal view virtual;
}
