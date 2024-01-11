// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface ILiquidator {

    /**
     * @dev   Auctioneer was set.
     * @param auctioneer_ Address of the auctioneer.
     */
    event AuctioneerSet(address auctioneer_);

    /**
     * @dev   Funds were withdrawn from the liquidator.
     * @param token_       Address of the token that was withdrawn.
     * @param destination_ Address of where tokens were sent.
     * @param amount_      Amount of tokens that were sent.
     */
    event FundsPulled(address token_, address destination_, uint256 amount_);

    /**
     * @dev   Portion of collateral was liquidated.
     * @param swapAmount_     Amount of collateralAsset that was liquidated.
     * @param returnedAmount_ Amount of fundsAsset that was returned.
     */
    event PortionLiquidated(uint256 swapAmount_, uint256 returnedAmount_);

    /**
     * @dev Getter function that returns `collateralAsset`.
     */
    function collateralAsset() external view returns (address collateralAsset_);

    /**
     * @dev Getter function that returns `destination` - address that liquidated funds are sent to.
     */
    function destination() external view returns (address destination_);

    /**
     * @dev Getter function that returns `auctioneer`.
     */
    function auctioneer() external view returns (address auctioneer_);

    /**
     * @dev Getter function that returns `fundsAsset`.
     */
    function fundsAsset() external view returns (address fundsAsset_);

    /**
     * @dev Getter function that returns `globals`.
     */
    function globals() external view returns (address);

    /**
     * @dev Getter function that returns `owner`.
     */
    function owner() external view returns (address owner_);

    /**
     * @dev   Set the auctioneer contract address, which is used to pull the `getExpectedAmount`.
     *        Can only be set by `owner`.
     * @param auctioneer_ The auctioneer contract address.
     */
    function setAuctioneer(address auctioneer_) external;

    /**
     * @dev   Pulls a specified amount of ERC-20 tokens from the contract.
     *        Can only be called by `owner`.
     * @param token_       The ERC-20 token contract address.
     * @param destination_ The destination of the transfer.
     * @param amount_      The amount to transfer.
     */
    function pullFunds(address token_, address destination_, uint256 amount_) external;

    /**
     * @dev    Returns the expected amount to be returned from a flash loan given a certain amount of `collateralAsset`.
     * @param  swapAmount_     Amount of `collateralAsset` to be flash-borrowed.
     * @return expectedAmount_ Amount of `fundsAsset` that must be returned in the same transaction.
     */
    function getExpectedAmount(uint256 swapAmount_) external returns (uint256 expectedAmount_);

    /**
     * @dev   Flash loan function that:
     *        1. Transfers a specified amount of `collateralAsset` to `msg.sender`.
     *        2. Performs an arbitrary call to `msg.sender`, to trigger logic necessary to get `fundsAsset` (e.g., AMM swap).
     *        3. Performs a `transferFrom`, taking the corresponding amount of `fundsAsset` from the user.
     *        If the required amount of `fundsAsset` is not returned in step 3, the entire transaction reverts.
     * @param swapAmount_      Amount of `collateralAsset` that is to be borrowed in the flash loan.
     * @param maxReturnAmount_ Max amount of `fundsAsset` that can be returned to the liquidator contract.
     * @param data_            ABI-encoded arguments to be used in the low-level call to perform step 2.
     */
    function liquidatePortion(uint256 swapAmount_, uint256 maxReturnAmount_, bytes calldata data_) external;

}
