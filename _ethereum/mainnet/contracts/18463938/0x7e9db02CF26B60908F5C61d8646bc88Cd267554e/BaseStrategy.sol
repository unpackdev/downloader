// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./SafeTransferLib.sol";

import "./IERC20.sol";
import "./OwnableRoles.sol";

import "./IStrategy.sol";
import "./IMaxApyVault.sol";
import "./Initializable.sol";

/// @title BaseStrategy
/// @author Forked and adapted from https://github.com/yearn/yearn-vaults/blob/master/contracts/BaseStrategy.sol
/// @notice `BaseStrategy` sets the base functionality to be implemented by MaxApy strategies.
/// @dev Inheriting strategies should implement functionality according to the standards defined in this
/// contract.
abstract contract BaseStrategy is Initializable, OwnableRoles {
    using SafeTransferLib for address;

    ////////////////////////////////////////////////////////////////
    ///                        CONSTANTS                         ///
    ////////////////////////////////////////////////////////////////
    uint256 public constant ADMIN_ROLE = _ROLE_0;
    uint256 public constant EMERGENCY_ADMIN_ROLE = _ROLE_1;
    uint256 public constant VAULT_ROLE = _ROLE_2;
    uint256 public constant KEEPER_ROLE = _ROLE_3;

    ////////////////////////////////////////////////////////////////
    ///                         EVENTS                           ///
    ////////////////////////////////////////////////////////////////

    /// @notice Emitted when the strategy is harvested
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

    /// @notice Emitted when the strategy's emergency exit status is updated
    event StrategyEmergencyExitUpdated(address indexed strategy, address emergencyExitStatus);

    /// @notice Emitted when the strategy's strategist is updated
    event StrategistUpdated(address indexed strategy, address newStrategist);

    /// @dev `keccak256(bytes("Harvested(uint256,uint256,uint256,uint256)"))`.
    uint256 internal constant _HARVESTED_EVENT_SIGNATURE =
        0x4c0f499ffe6befa0ca7c826b0916cf87bea98de658013e76938489368d60d509;

    /// @dev `keccak256(bytes("StrategyEmergencyExitUpdated(address,uint256)"))`.
    uint256 internal constant _STRATEGY_EMERGENCYEXIT_UPDATED_EVENT_SIGNATURE =
        0x379f62e57e9c386867f64a9d19eb934e27af596d21fe22da1e9ce6b0bd1ba664;

    /// @dev `keccak256(bytes("StrategistUpdated(address,address)"))`.
    uint256 internal constant _STRATEGY_STRATEGIST_UPDATED_EVENT_SIGNATURE =
        0xf6a8d961ba4f41874e38ad8bed56ca4bcf2356a3dd5bfa626b8a73a0da9f5c69;

    ////////////////////////////////////////////////////////////////
    ///            STRATEGY GLOBAL STATE VARIABLES               ///
    ////////////////////////////////////////////////////////////////

    /// @notice The MaxApy vault linked to this strategy
    IMaxApyVault public vault;
    /// @notice The strategy's underlying asset (`want` token)
    address public underlyingAsset;
    /// @notice Strategy state stating if vault is in emergency shutdown mode
    uint256 public emergencyExit;
    /// @notice Name of the strategy
    bytes32 public strategyName;
    /// @notice Strategist's address
    address public strategist;
    /// @notice Gap for upgradeability
    uint256[20] private __gap;

    ////////////////////////////////////////////////////////////////
    ///                       MODIFIERS                          ///
    ////////////////////////////////////////////////////////////////
    modifier checkRoles(uint256 roles) {
        _checkRoles(roles);
        _;
    }

    ////////////////////////////////////////////////////////////////
    ///                     INITIALIZATION                       ///
    ////////////////////////////////////////////////////////////////
    constructor() initializer {}

    /// @notice Initialize a new Strategy
    /// @param _vault The address of the MaxApy Vault associated to the strategy
    /// @param _keepers The addresses of the keepers to be granted the keeper role
    /// @param _strategyName the name of the strategy
    function __BaseStrategy_init(
        IMaxApyVault _vault,
        address[] calldata _keepers,
        bytes32 _strategyName,
        address _strategist
    ) internal onlyInitializing {
        assembly ("memory-safe") {
            // Ensure `_strategist` address is != from address(0)
            if eq(_strategist, 0) {
                // throw the `InvalidZeroAddress` error
                mstore(0x00, 0xf6b2911f)
                revert(0x1c, 0x04)
            }
        }

        vault = _vault;
        _grantRoles(address(_vault), VAULT_ROLE);

        // Cache underlying asset
        address _underlyingAsset = _vault.underlyingAsset();

        underlyingAsset = _underlyingAsset;

        // Approve MaxApyVault to transfer underlying
        _underlyingAsset.safeApprove(address(_vault), type(uint256).max);

        // Grant keepers with `KEEPER_ROLE`
        for (uint256 i; i < _keepers.length;) {
            _grantRoles(_keepers[i], KEEPER_ROLE);
            unchecked {
                ++i;
            }
        }

        // Set caller as admin and owner
        _initializeOwner(msg.sender);
        _grantRoles(msg.sender, ADMIN_ROLE);

        strategyName = _strategyName;

        emergencyExit = 1;

        strategist = _strategist;
    }

    ////////////////////////////////////////////////////////////////
    ///                STRATEGY CORE LOGIC                       ///
    ////////////////////////////////////////////////////////////////
    /// @notice Withdraws `amountNeeded` to `vault`.
    /// @dev This may only be called by the respective Vault.
    /// @param amountNeeded How much `underlyingAsset` to withdraw.
    /// @return loss Any realized losses
    function withdraw(uint256 amountNeeded) external checkRoles(VAULT_ROLE) returns (uint256 loss) {
        uint256 amountFreed;
        // Liquidate as much as possible to `underlyingAsset`, up to `amountNeeded`
        (amountFreed, loss) = _liquidatePosition(amountNeeded);
        // Send it directly back to vault
        underlyingAsset.safeTransfer(msg.sender, amountFreed);
        // Note: Reinvest anything leftover on next `harvest`
    }

    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting
    /// the Strategy's position.
    /// In the rare case the Strategy is in emergency shutdown, this will exit
    /// the Strategy's position.
    /// @dev When `harvest()` is called, the Strategy reports to the MaxApy Vault (via
    /// `MaxApyVault.report()`), so in some cases `harvest()` must be called in order
    /// to take in profits, to borrow newly available funds from the MaxApy Vault, or
    /// otherwise adjust its position. In other cases `harvest()` must be
    /// called to report to the MaxApy Vault on the Strategy's position, especially if
    /// any losses have occurred.
    /// @param minExpectedBalance minimum balance amount of `underlyingAsset` expected after performing any
    /// @param minOutputAfterInvestment minimum expected output after `_invest()`
    /// strategy unwinding (if applies).
    function harvest(uint256 minExpectedBalance, uint256 minOutputAfterInvestment) external checkRoles(KEEPER_ROLE) {
        uint256 profit;
        uint256 loss;
        uint256 debtPayment;
        uint256 debtOutstanding;

        address cachedVault = address(vault); // Cache `vault` address to avoid multiple SLOAD's

        assembly ("memory-safe") {
            // Store `vault`'s `debtOutstanding()` function selector:
            // `bytes4(keccak256("debtOutstanding(address)"))`
            mstore(0x00, 0xbdcf36bb)
            mstore(0x20, address()) // append the current address as parameter

            // query `vault`'s `debtOutstanding()`
            if iszero(
                staticcall(
                    gas(), // Remaining amount of gas
                    cachedVault, // Address of `vault`
                    0x1c, // byte offset in memory where calldata starts
                    0x24, // size of the calldata to copy
                    0x00, // byte offset in memory to store the return data
                    0x20 // size of the return data
                )
            ) {
                // Revert if debt outstanding query fails
                revert(0x00, 0x04)
            }

            // Store debt outstanding returned by staticcall into `debtOutstanding`
            debtOutstanding := mload(0x00)
        }

        if (emergencyExit == 2) {
            // Free up as much capital as possible
            uint256 amountFreed = _liquidateAllPositions();
            assembly {
                // avoid writing to storage in case eq(amountFreed, debtOutstanding) == 1

                if lt(amountFreed, debtOutstanding) {
                    // if (amountFreed < debtOutstanding)
                    loss := sub(debtOutstanding, amountFreed) // set loss = debtOutstanding - amountFreed
                }
                if gt(amountFreed, debtOutstanding) {
                    // if (amountFreed > debtOutstanding)
                    profit := sub(amountFreed, debtOutstanding) // set profit = amountFreed - debtOutstanding
                }

                debtPayment := sub(debtOutstanding, loss) // can not overflow due to `debtOutstanding` being > `loss` in both cases
            }
        } else {
            // Free up returns for vault to pull
            (profit, loss, debtPayment) = _prepareReturn(debtOutstanding, minExpectedBalance);
        }

        assembly ("memory-safe") {
            let m := mload(0x40) // Store free memory pointer

            // Store `vault`'s `report()` function selector:
            // `bytes4(keccak256("report(uint128,uint128,uint128)"))`
            mstore(0x00, 0x68dbf47f)
            mstore(0x20, profit) // append the `profit` argument
            mstore(0x40, loss) // append the `loss` argument
            mstore(0x60, debtPayment) // append the `debtPayment` argument

            // Report to vault
            if iszero(
                call(
                    gas(), // Remaining amount of gas
                    cachedVault, // Address of `vault`
                    0, // `msg.value`
                    0x1c, // byte offset in memory where calldata starts
                    0x64, // size of the calldata to copy
                    0x00, // byte offset in memory to store the return data
                    0x20 // size of the return data
                )
            ) {
                // If call failed, throw the error thrown in the previous `call`
                revert(0x00, 0x04)
            }

            // Store debt outstanding returned by call to `report()` into `debtOutstanding`
            debtOutstanding := mload(0x00)

            mstore(0x60, 0) // Restore the zero slot
            mstore(0x40, m) // Restore the free memory pointer
        }

        // Check if vault transferred underlying and re-invest it
        _adjustPosition(debtOutstanding, minOutputAfterInvestment);

        assembly ("memory-safe") {
            let m := mload(0x40) // Store free memory pointer

            mstore(0x00, profit)
            mstore(0x20, loss)
            mstore(0x40, debtPayment)
            mstore(0x60, debtOutstanding)

            log1(0x00, 0x80, _HARVESTED_EVENT_SIGNATURE)

            mstore(0x60, 0) // Restore the zero slot
            mstore(0x40, m) // Restore the free memory pointer
        }
    }

    ////////////////////////////////////////////////////////////////
    ///                 STRATEGY CONFIGURATION                   ///
    ////////////////////////////////////////////////////////////////

    /// @notice Sets the strategy in emergency exit mode
    /// @param _emergencyExit The new emergency exit value: 1 for unactive, 2 for active
    function setEmergencyExit(uint256 _emergencyExit) external checkRoles(ADMIN_ROLE) {
        assembly ("memory-safe") {
            sstore(emergencyExit.slot, _emergencyExit)
            // Emit the `StrategyEmergencyExitUpdated` event
            mstore(0x00, _emergencyExit)
            log2(0x00, 0x20, _STRATEGY_EMERGENCYEXIT_UPDATED_EVENT_SIGNATURE, address())
        }
    }

    /// @notice Sets the strategy's new strategist
    /// @param _newStrategist The new strategist address
    function setStrategist(address _newStrategist) external checkRoles(ADMIN_ROLE) {
        assembly ("memory-safe") {
            if iszero(_newStrategist) {
                // throw the `InvalidZeroAddress` error
                mstore(0x00, 0xf6b2911f)
                revert(0x1c, 0x04)
            }

            sstore(strategist.slot, _newStrategist)

            // Emit the `StrategistUpdated` event
            mstore(0x00, _newStrategist)
            log2(0x00, 0x20, _STRATEGY_STRATEGIST_UPDATED_EVENT_SIGNATURE, address())
        }
    }

    ////////////////////////////////////////////////////////////////
    ///                    INTERNAL FUNCTIONS                    ///
    ////////////////////////////////////////////////////////////////
    /// @notice Performs any adjustments to the core position(s) of this Strategy given
    /// what change the MaxApy Vault made in the "investable capital" available to the
    /// Strategy.
    /// @dev Note that all "free capital" (capital not invested) in the Strategy after the report
    /// was made is available for reinvestment. This number could be 0, and this scenario should be handled accordingly.
    /// @param debtOutstanding Total principal + interest of debt yet to be paid back
    /// @param minOutputAfterInvestment minimum expected output after `_invest()` (designated in receipt tokens obtained after depositing in a third-party protocol)
    function _adjustPosition(uint256 debtOutstanding, uint256 minOutputAfterInvestment) internal virtual;

    /// @notice Liquidate up to `amountNeeded` of MaxApy Vault's `underlyingAsset` of this strategy's positions,
    /// irregardless of slippage. Any excess will be re-invested with `_adjustPosition()`.
    /// @dev This function should return the amount of MaxApy Vault's `underlyingAsset` tokens made available by the
    /// liquidation. If there is a difference between `amountNeeded` and `liquidatedAmount`, `loss` indicates whether the
    /// difference is due to a realized loss, or if there is some other sitution at play
    /// (e.g. locked funds) where the amount made available is less than what is needed.
    /// NOTE: The invariant `liquidatedAmount + loss <= amountNeeded` should always be maintained
    /// @param amountNeeded amount of MaxApy Vault's `underlyingAsset` needed to be liquidated
    /// @return liquidatedAmount the actual liquidated amount
    /// @return loss difference between the expected amount needed to reach `amountNeeded` and the actual liquidated amount
    function _liquidatePosition(uint256 amountNeeded)
        internal
        virtual
        returns (uint256 liquidatedAmount, uint256 loss);

    /// @notice Liquidates everything and returns the amount that got freed.
    /// @dev This function is used during emergency exit instead of `_prepareReturn()` to
    /// liquidate all of the Strategy's positions back to the MaxApy Vault.
    function _liquidateAllPositions() internal virtual returns (uint256 amountFreed);

    /// Perform any Strategy unwinding or other calls necessary to capture the
    /// "free return" this Strategy has generated since the last time its core
    /// position(s) were adjusted. Examples include unwrapping extra rewards.
    /// This call is only used during "normal operation" of a Strategy, and
    /// should be optimized to minimize losses as much as possible.
    ///
    /// This method returns any realized profits and/or realized losses
    /// incurred, and should return the total amounts of profits/losses/debt
    /// payments (in MaxApy Vault's `underlyingAsset` tokens) for the MaxApy Vault's accounting (e.g.
    /// `underlyingAsset.balanceOf(this) >= debtPayment + profit`).
    ///
    /// `debtOutstanding` will be 0 if the Strategy is not past the configured
    /// debt limit, otherwise its value will be how far past the debt limit
    /// the Strategy is. The Strategy's debt limit is configured in the MaxApy Vault.
    ///
    /// NOTE: `debtPayment` should be less than or equal to `debtOutstanding`.
    ///       It is okay for it to be less than `debtOutstanding`, as that
    ///       should only be used as a guide for how much is left to pay back.
    ///       Payments should be made to minimize loss from slippage, debt,
    ///       withdrawal fees, etc.
    ///
    /// See `MaxApyVault.debtOutstanding()`.
    function _prepareReturn(uint256 debtOutstanding, uint256 minExpectedBalance)
        internal
        virtual
        returns (uint256 profit, uint256 loss, uint256 debtPayment);

    /// @notice Returns the current strategy's balance in underlying token
    /// @return the strategy's balance of underlying token
    function _underlyingBalance() internal view returns (uint256) {
        return underlyingAsset.balanceOf(address(this));
    }
}
