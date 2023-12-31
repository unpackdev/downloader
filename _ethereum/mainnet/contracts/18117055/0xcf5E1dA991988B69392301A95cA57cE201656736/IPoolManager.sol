// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @title IPoolManager
 * @notice Interface for the PoolManager contract
 */
interface IPoolManager {
    /**
     * @notice Initializes the permitter contract with some initial state.
     * @param dittoPool_ the address of the DittoPool that this manager is managing.
     * @param data_ any data necessary for initializing the permitter.
     */
    function initialize(address dittoPool_, bytes memory data_) external;

    /**
     * @notice Returns whether or not the contract has been initialized.
     * @return initialized Whether or not the contract has been initialized.
     */
    function initialized() external view returns (bool);

    /**
     * @notice Change the base price charged to buy an NFT from the pair
     * @param newBasePrice_ New base price: now NFTs purchased at this price, sold at `newBasePrice_ + Delta`
     */
    function changeBasePrice(uint128 newBasePrice_) external;

    /**
     * @notice Change the delta parameter associated with the bonding curve
     * @dev see the bonding curve documentation on bonding curves for additional information
     * Each bonding curve uses delta differently, but in general it is used as an input
     * to determine the next price on the bonding curve
     * @param newDelta_ New delta parameter
     */
    function changeDelta(uint128 newDelta_) external;

    /**
     * @notice Change the pool lp fee, set by owner, paid to LPers only when they are the counterparty in a trade
     * @param newFeeLp_ New fee, in wei / 1e18, charged by the pool for trades with it (i.e. 1% = 0.01e18)
     */
    function changeLpFee(uint96 newFeeLp_) external;

    /**
     * @notice Change the pool admin fee, set by owner, paid to admin (or whoever they want)
     * @param newFeeAdmin_ New fee, in wei / 1e18, charged by the pool for trades with it (i.e. 1% = 0.01e18)
     */
    function changeAdminFee(uint96 newFeeAdmin_) external;

    /**
     * @notice Change who the pool admin fee for this pool is sent to.
     * @param newAdminFeeRecipient_ New address to send admin fees to.
     */
    function changeAdminFeeRecipient(address newAdminFeeRecipient_) external;

    /**
     * @notice Change the owner of the underlying DittoPool, functions independently of PoolManager
     *   ownership transfer.
     * @param newOwner_ The new owner of the underlying DittoPool
     */
    function transferPoolOwnership(address newOwner_) external;
}
