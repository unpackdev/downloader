// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./ITraderBalanceVaultStorage.sol";
import "./IPausable.sol";

interface ITraderBalanceVault is ITraderBalanceVaultStorage, IPausable {
    /**
     * Types of way to open a position or order
     */
    enum OpenType {
        OPEN_BY_ORDER,
        OPEN,
        CREATE_LIMIT_ORDER
    }

    /**
     * @param trader The trader, who opens margin deal
     * @param depositReceiver the address to which the deposit is transferred when blocked.
     * This happens because the trader's deposit is involved in the position
     * @param borrowedAsset The token to lock for deal in a borrowed asset
     * @param depositAsset The token is a deposit asset
     * (it is blocked when creating a limit order
     * For others, the operations is transferred to the account of the receiver of the deposit and is swapped )
     * @param depositAmount Amount of tokens in a deposit asset
     * @param depositInBorrowedAmount Amount of tokens to lock for deal in a borrowed asset
     * @param openType Corresponds to the purpose of locking
     */
    struct LockAssetParams {
        address trader;
        address depositReceiver;
        address depositAsset;
        uint256 depositAmount;
        OpenType openType;
    }

    /**
     * @param trader The trader who opened the position
     * @param receiver The receiver of the rest of trader deposit.
     * @param asset Borrowed asset of the position being closed (the need for accrual of profit).
     * @param unlockAmount The amount of unlocked collateral for deal
     * @param returnToTrader The returned to trader amount when position was closed.
     */
    struct UnlockAssetParams {
        address trader;
        address receiver;
        address asset;
        uint256 amount;
    }

    /**
     * @param traders An array of traders for which available balance should be increased
     * @param amounts An array of amounts corresponding to traders' addresses that should be added to their available balances
     * @param asset Asset address which amount will be increased
     * @param length The amount of traders in an array
     */
    struct BatchTopUpAvailableBalanceParams {
        address[] traders;
        uint256[] amounts;
        address asset;
        uint256 length;
    }

    event Deposit(address indexed depositer, address indexed asset, uint256 amount);
    event Withdraw(address indexed withdrawer, address asset, uint256 amount);

    /**
     * @dev contract initializer
     * @param _registry The address of Registry contract
     * @param _whiteBlackList The address of WhiteBlackList contract
     */
    function initialize(address _registry, address _whiteBlackList) external;

    receive() external payable;

    /**
     * @dev Deposits trader collateral for margin deal
     * @param _asset The collateral asset for deal
     * @param _amount The amount of '_asset' to deposit
     */
    function deposit(address _asset, uint256 _amount) external payable;

    /**
     * @dev Withdraws the rest of trader's deposit after closing deal
     * @param _asset The collateral asset for withdraw
     * @param _amount The amount of '_asset' to withdraw
     */
    function withdraw(address _asset, uint256 _amount) external;

    /**
     * @dev Traders lock their collateral for the limit order.
     * @param _trader The owner of collateral
     * @param _asset The collateral asset for deal
     * @param _amount The amount of '_asset' to deposit
     */
    function increaseLockedBalance(address _trader, address _asset, uint256 _amount) external payable;

    /**
     * @dev Locks deposited trader's assets as collateral for orders.
     * Decreases the available balance when opening position.
     * Transfers deposited amount to the deposit receiver.
     * @param _params parameters necessary to lock asset
     */
    function useTraderAssets(LockAssetParams calldata _params) external;

    /**
     * @dev Unlocks trader's collateral when open position by order or update deposit.
     * @param _params parameters necessary to unlock asset
     */
    function unlockAsset(UnlockAssetParams calldata _params) external;

    /**
     * The function to increase available balance for several traders
     * @param _params A struct containing BatchTopUpAvailableBalanceParams
     */
    function batchTopUpAvailableBalance(BatchTopUpAvailableBalanceParams calldata _params) external;

    /**
     * Withdraws an asset amount from an asset holder to a receiver
     * @param _from Withdraw from address
     * @param _to Withdraw to address
     * @param _asset Address of an asset
     * @param _amount Amount of an asset
     * @param fromLocked True if withdraw from locked balance
     */
    function withdrawFrom(address _from, address _to, address _asset, uint256 _amount, bool fromLocked) external;

    /**
     * Increases available balance of a receiver in the protocol
     * @param receiver The address of an asset receiver
     * @param asset The asset address for which available balance will be increased
     * @param amount The amount of an asset
     */
    function topUpAvailableBalance(address receiver, address asset, uint256 amount) external payable;
}
