// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./IMapleProxied.sol";

import "./IMapleWithdrawalManagerStorage.sol";

interface IMapleWithdrawalManager is IMapleProxied, IMapleWithdrawalManagerStorage {

    /**************************************************************************************************************************************/
    /*** State Changing Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Add shares to the withdrawal manager.
     *  @param shares_ Amount of shares to add.
     *  @param owner_  Address of the owner of shares.
     */
    function addShares(uint256 shares_, address owner_) external;

    /**
     *  @dev   Process the exit of an account.
     *  @param requestedShares_ Amount of initially requested shares.
     *  @param owner_           Address of the account which will be processed for exit.
     */
    function processExit(uint256 requestedShares_, address owner_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    /**
     *  @dev   Remove shares to the withdrawal manager.
     *  @param shares_ Amount of shares to remove.
     *  @param owner_  Address of the owner of shares.
     */
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    /**
     *  @dev   Sets up a new exit configuration.
     *  @param cycleDuration_  The total duration, in seconds, of a withdrawal cycle.
     *  @param windowDuration_ The duration, in seconds, of the withdrawal window.
     */
    function setExitConfig(uint256 cycleDuration_, uint256 windowDuration_) external;

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Gets the asset address used in this withdrawal manager.
     *  @return asset_ Address of the asset.
     */
    function asset() external view returns (address asset_);

    /**
     *  @dev    Gets the configuration of a given cycle id.
     *  @param  cycleId_  The id of the cycle.
     *  @return config_ The configuration info corresponding to the cycle.
     */
    function getConfigAtId(uint256 cycleId_) external view returns (CycleConfig memory config_);

    /**
     *  @dev    Gets the configuration of the current cycle id.
     *  @return config_ The configuration info corresponding to the cycle.
     */
    function getCurrentConfig() external view returns (CycleConfig memory config_);

    /**
     *  @dev   Gets the id of the current cycle.
     *  @param cycleId_ The id of the current cycle.
     */
    function getCurrentCycleId() external view returns (uint256 cycleId_);

    /**
     *  @dev    Gets the shares and assets that are redeemable for a given user.
     *  @param  lockedShares_     The amount of shares that are locked.
     *  @param  owner_            The owner of the shares.
     *  @return redeemableShares_ The amount of shares that are redeemable based on current liquidity.
     *  @return resultingAssets_  The corresponding amount of assets that can be redeemed using the shares.
     *  @return partialLiquidity_ Boolean indicating if there is enough liquidity to facilitate a full redemption.
     */
    function getRedeemableAmounts(uint256 lockedShares_, address owner_)
        external view returns (uint256 redeemableShares_, uint256 resultingAssets_, bool partialLiquidity_);

    /**
     *  @dev    Gets the timestamp of the beginning of the withdrawal window for a given cycle.
     *  @param  cycleId_     The id of the current cycle.
     *  @return windowStart_ The timestamp of the beginning of the cycle, which is the same as the beginning of the withdrawal window.
     */
    function getWindowStart(uint256 cycleId_) external view returns (uint256 windowStart_);

    /**
     *  @dev    Gets the timestamps of the beginning and end of the withdrawal window for a given cycle.
     *  @param  cycleId_     The id of the current cycle.
     *  @return windowStart_ The timestamp of the beginning of the cycle, which is the same as the beginning of the withdrawal window.
     *  @return windowEnd_   The timestamp of the end of the withdrawal window.
     */
    function getWindowAtId(uint256 cycleId_) external view returns (uint256 windowStart_, uint256 windowEnd_);

    /**
     *  @dev    Gets the address of globals.
     *  @return globals_ The address of globals.
     */
    function globals() external view returns (address globals_);

    /**
     *  @dev    Gets the address of the governor.
     *  @return governor_ The address of the governor.
     */
    function governor() external view returns (address governor_);

    /**
     *  @dev    Checks if an account is included in an exit window.
     *  @param  owner_          The address of the share owners to check.
     *  @return isInExitWindow_ A boolean indicating whether or not the account is in an exit window.
     */
    function isInExitWindow(address owner_) external view returns (bool isInExitWindow_);

    /**
     *  @dev    Gets the total amount of funds that need to be locked to fulfill exits.
     *  @return lockedLiquidity_ The amount of locked liquidity.
     */
    function lockedLiquidity() external view returns (uint256 lockedLiquidity_);

    /**
     *  @dev    Gets the pool delegate address.
     *  @return poolDelegate_ Address of the pool delegate.
     */
    function poolDelegate() external view returns (address poolDelegate_);

    /**
     *  @dev    Gets the amount of shares that can be redeemed.
     *  @param  owner_            The address to check the redemption for.
     *  @param  shares_           The amount of requested shares to redeem.
     *  @return redeemableShares_ The amount of shares that can be redeemed.
     *  @return resultingAssets_  The amount of assets that will be returned for `redeemableShares`.
     */
    function previewRedeem(address owner_, uint256 shares_) external view returns (uint256 redeemableShares_, uint256 resultingAssets_);

    /**
     *  @dev    Gets the amount of shares that can be withdrawn.
     *  @param  owner_            The address to check the withdrawal for.
     *  @param  assets_           The amount of requested shares to withdraw.
     *  @return redeemableAssets_ The amount of assets that can be withdrawn.
     *  @return resultingShares_  The amount of shares that will be burned.
     */
    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 redeemableAssets_, uint256 resultingShares_);

}
