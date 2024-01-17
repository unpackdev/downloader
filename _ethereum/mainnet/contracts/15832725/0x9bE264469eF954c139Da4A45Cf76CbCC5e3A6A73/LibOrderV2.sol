// SPDX-License-Identifier: ISC

/* solium-disable */

pragma solidity 0.7.5;

//Taken from 0x exchange
library LibOrderV2 {
    /**
     * @dev Order type
     * @param makerAddress Address that created the order.
     * @param takerAddress Address that is allowed to fill the order.
     *                     If set to 0, any address is allowed to fill the order.
     * @param feeRecipientAddress Address that will recieve fees when order is filled.
     * @param senderAddress Address that is allowed to call Exchange contract methods that affect this order.
     *                      If set to 0, any address is allowed to call these methods.
     * @param makerAssetAmount Amount of makerAsset being offered by maker. Must be greater than 0.
     * @param takerAssetAmount Amount of takerAsset being bid on by maker. Must be greater than 0.
     * @param makerFee Amount of ZRX paid to feeRecipient by maker when order is filled.
     *                 If set to 0, no transfer of ZRX from maker to feeRecipient will be attempted
     * @param takerFee Amount of ZRX paid to feeRecipient by taker when order is filled.
     *                 If set to 0, no transfer of ZRX from taker to feeRecipient will be attempted.
     * @param expirationTimeSeconds Timestamp in seconds at which order expires.
     * @param salt Arbitrary number to facilitate uniqueness of the order's hash.
     * @param makerAssetData Encoded data that can be decoded by a specified proxy contract
     *                       when transferring makerAsset.
     *                       The last byte references the id of this proxy.
     * @param takerAssetData Encoded data that can be decoded by a specified proxy contract
     *                       when transferring takerAsset.
     *                       The last byte references the id of this proxy.
     */
    struct Order {
        address makerAddress;
        address takerAddress;
        address feeRecipientAddress;
        address senderAddress;
        uint256 makerAssetAmount;
        uint256 takerAssetAmount;
        uint256 makerFee;
        uint256 takerFee;
        uint256 expirationTimeSeconds;
        uint256 salt;
        bytes makerAssetData;
        bytes takerAssetData;
    }

    struct FillResults {
        uint256 makerAssetFilledAmount; // Total amount of makerAsset(s) filled.
        uint256 takerAssetFilledAmount; // Total amount of takerAsset(s) filled.
        uint256 makerFeePaid; // Total amount of ZRX paid by maker(s) to feeRecipient(s).
        uint256 takerFeePaid; // Total amount of ZRX paid by taker to feeRecipients(s).
    }
}
