// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <council@enzyme.finance>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IAaveAToken.sol";
import "./IAaveV3Pool.sol";
import "./IAaveV3PoolAddressProvider.sol";
import "./IAaveV3ProtocolDataProvider.sol";
import {AaveV3DebtPositionLibBase1} from
    "../../../../../persistent/external-positions/aave-v3-debt/AaveV3DebtPositionLibBase1.sol";
import "./AddressArrayLib.sol";
import "./AssetHelpers.sol";
import "./AaveV3DebtPositionDataDecoder.sol";
import "./IAaveV3DebtPosition.sol";

/// @title AaveV3DebtPositionLib Contract
/// @author Enzyme Council <security@enzyme.finance>
/// @notice An External Position library contract for Aave V3 debt positions
contract AaveV3DebtPositionLib is
    AaveV3DebtPositionLibBase1,
    IAaveV3DebtPosition,
    AaveV3DebtPositionDataDecoder,
    AssetHelpers
{
    using AddressArrayLib for address[];
    using SafeERC20 for ERC20;

    uint256 private constant VARIABLE_INTEREST_RATE = 2;

    IAaveV3ProtocolDataProvider private immutable DATA_PROVIDER_CONTRACT;
    IAaveV3PoolAddressProvider private immutable LENDING_POOL_ADDRESS_PROVIDER_CONTRACT;
    uint16 private immutable REFERRAL_CODE;

    constructor(
        IAaveV3ProtocolDataProvider _dataProvider,
        IAaveV3PoolAddressProvider _lendingPoolAddressProvider,
        uint16 _referralCode
    ) {
        DATA_PROVIDER_CONTRACT = _dataProvider;
        LENDING_POOL_ADDRESS_PROVIDER_CONTRACT = _lendingPoolAddressProvider;
        REFERRAL_CODE = _referralCode;
    }

    /// @notice Initializes the external position
    /// @dev Nothing to initialize for this contract
    function init(bytes memory) external override {}

    /// @notice Receives and executes a call from the Vault
    /// @param _actionData Encoded data to execute the action
    function receiveCallFromVault(bytes memory _actionData) external override {
        (uint256 actionId, bytes memory actionArgs) = abi.decode(_actionData, (uint256, bytes));

        if (actionId == uint256(Actions.AddCollateral)) {
            __addCollateralAssets(actionArgs);
        } else if (actionId == uint256(Actions.RemoveCollateral)) {
            __removeCollateralAssets(actionArgs);
        } else if (actionId == uint256(Actions.Borrow)) {
            __borrowAssets(actionArgs);
        } else if (actionId == uint256(Actions.RepayBorrow)) {
            __repayBorrowedAssets(actionArgs);
        } else if (actionId == uint256(Actions.SetEMode)) {
            __setEMode(actionArgs);
        } else if (actionId == uint256(Actions.SetUseReserveAsCollateral)) {
            __setUseReserveAsCollateral(actionArgs);
        } else {
            revert("receiveCallFromVault: Invalid actionId");
        }
    }

    /// @dev Receives and adds aTokens as collateral
    function __addCollateralAssets(bytes memory actionArgs) private {
        (address[] memory aTokens, uint256[] memory amounts, bool fromUnderlying) =
            __decodeAddCollateralActionArgs(actionArgs);

        address lendingPoolAddress = LENDING_POOL_ADDRESS_PROVIDER_CONTRACT.getPool();

        for (uint256 i; i < aTokens.length; i++) {
            // supply aToken underlying to the lending pool
            if (fromUnderlying) {
                address underlying = IAaveAToken(aTokens[i]).UNDERLYING_ASSET_ADDRESS();

                __approveAssetMaxAsNeeded({_asset: underlying, _target: lendingPoolAddress, _neededAmount: amounts[i]});

                IAaveV3Pool(lendingPoolAddress).supply({
                    _underlying: underlying,
                    _amount: amounts[i],
                    _to: address(this),
                    _referralCode: REFERRAL_CODE
                });
            }

            if (!assetIsCollateral(aTokens[i])) {
                collateralAssets.push(aTokens[i]);
                emit CollateralAssetAdded(aTokens[i]);
            }
        }
    }

    /// @dev Borrows assets using the available collateral
    function __borrowAssets(bytes memory actionArgs) private {
        (address[] memory underlyings, uint256[] memory amounts) = __decodeBorrowActionArgs(actionArgs);

        address lendingPoolAddress = LENDING_POOL_ADDRESS_PROVIDER_CONTRACT.getPool();

        for (uint256 i; i < underlyings.length; i++) {
            IAaveV3Pool(lendingPoolAddress).borrow(
                underlyings[i], amounts[i], VARIABLE_INTEREST_RATE, REFERRAL_CODE, address(this)
            );

            ERC20(underlyings[i]).safeTransfer(msg.sender, amounts[i]);

            if (!assetIsBorrowed(underlyings[i])) {
                // Store the debt token as a flag that the token is now a borrowed asset
                (,, address debtToken) = DATA_PROVIDER_CONTRACT.getReserveTokensAddresses(underlyings[i]);
                borrowedAssetToDebtToken[underlyings[i]] = debtToken;

                borrowedAssets.push(underlyings[i]);
                emit BorrowedAssetAdded(underlyings[i]);
            }
        }
    }

    /// @dev Removes assets from collateral
    function __removeCollateralAssets(bytes memory actionArgs) private {
        (address[] memory aTokens, uint256[] memory amounts, bool toUnderlying) =
            __decodeRemoveCollateralActionArgs(actionArgs);

        IAaveV3Pool lendingPool = IAaveV3Pool(LENDING_POOL_ADDRESS_PROVIDER_CONTRACT.getPool());

        for (uint256 i; i < aTokens.length; i++) {
            require(assetIsCollateral(aTokens[i]), "__removeCollateralAssets: Invalid collateral asset");

            uint256 collateralBalance = ERC20(aTokens[i]).balanceOf(address(this));

            if (amounts[i] == type(uint256).max) {
                amounts[i] = collateralBalance;
            }

            // If the full collateral of an asset is removed, it can be removed from collateral assets
            if (amounts[i] == collateralBalance) {
                collateralAssets.removeStorageItem(aTokens[i]);
                emit CollateralAssetRemoved(aTokens[i]);
            }

            if (toUnderlying) {
                lendingPool.withdraw({
                    _underlying: IAaveAToken(aTokens[i]).UNDERLYING_ASSET_ADDRESS(),
                    _amount: amounts[i],
                    _to: msg.sender
                });
            } else {
                ERC20(aTokens[i]).safeTransfer(msg.sender, amounts[i]);
            }
        }
    }

    /// @dev Repays borrowed assets, reducing the borrow balance
    function __repayBorrowedAssets(bytes memory actionArgs) private {
        (address[] memory underlyings, uint256[] memory amounts) = __decodeRepayBorrowActionArgs(actionArgs);

        address lendingPoolAddress = LENDING_POOL_ADDRESS_PROVIDER_CONTRACT.getPool();

        for (uint256 i; i < underlyings.length; i++) {
            require(assetIsBorrowed(underlyings[i]), "__repayBorrowedAssets: Invalid borrowed asset");

            __approveAssetMaxAsNeeded(underlyings[i], lendingPoolAddress, amounts[i]);

            IAaveV3Pool(lendingPoolAddress).repay(underlyings[i], amounts[i], VARIABLE_INTEREST_RATE, address(this));

            uint256 remainingBalance = ERC20(underlyings[i]).balanceOf(address(this));

            if (remainingBalance > 0) {
                ERC20(underlyings[i]).safeTransfer(msg.sender, remainingBalance);
            }

            // Remove borrowed asset state from storage, if there is no remaining borrowed balance
            if (ERC20(getDebtTokenForBorrowedAsset(underlyings[i])).balanceOf(address(this)) == 0) {
                delete borrowedAssetToDebtToken[underlyings[i]];
                borrowedAssets.removeStorageItem(underlyings[i]);
                emit BorrowedAssetRemoved(underlyings[i]);
            }
        }
    }

    /// @dev Sets the eMode (efficiency mode) of the external position
    function __setEMode(bytes memory actionArgs) private {
        (uint8 categoryId) = __decodeSetEModeActionArgs(actionArgs);

        address lendingPoolAddress = LENDING_POOL_ADDRESS_PROVIDER_CONTRACT.getPool();

        IAaveV3Pool(lendingPoolAddress).setUserEMode(categoryId);
    }

    /// @dev Enables/disables a reserve as a collateral asset,
    /// and because of that we can enter to the isolation mode if we would enable for example USDT as collateral
    function __setUseReserveAsCollateral(bytes memory actionArgs) private {
        (address underlying, bool useAsCollateral) = __decodeSetUseReserveAsCollateralActionArgs(actionArgs);

        address lendingPoolAddress = LENDING_POOL_ADDRESS_PROVIDER_CONTRACT.getPool();

        IAaveV3Pool(lendingPoolAddress).setUserUseReserveAsCollateral({
            _asset: underlying,
            _useAsCollateral: useAsCollateral
        });
    }

    ////////////////////
    // POSITION VALUE //
    ////////////////////

    /// @notice Retrieves the debt assets (negative value) of the external position
    /// @return assets_ Debt assets
    /// @return amounts_ Debt asset amounts
    function getDebtAssets() external view override returns (address[] memory assets_, uint256[] memory amounts_) {
        assets_ = borrowedAssets;
        amounts_ = new uint256[](assets_.length);

        for (uint256 i; i < assets_.length; i++) {
            amounts_[i] = ERC20(getDebtTokenForBorrowedAsset(assets_[i])).balanceOf(address(this));
        }

        return (assets_, amounts_);
    }

    /// @notice Retrieves the managed assets (positive value) of the external position
    /// @return assets_ Managed assets
    /// @return amounts_ Managed asset amounts
    function getManagedAssets() external view override returns (address[] memory assets_, uint256[] memory amounts_) {
        assets_ = collateralAssets;
        amounts_ = new uint256[](collateralAssets.length);

        for (uint256 i; i < assets_.length; i++) {
            amounts_[i] = ERC20(assets_[i]).balanceOf(address(this));
        }

        return (assets_, amounts_);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @dev Checks whether an asset is borrowed
    /// @return isBorrowed_ True if the asset is part of the borrowed assets of the external position
    function assetIsBorrowed(address _asset) public view returns (bool isBorrowed_) {
        return getDebtTokenForBorrowedAsset(_asset) != address(0);
    }

    /// @notice Checks whether an asset is collateral
    /// @return isCollateral_ True if the asset is part of the collateral assets of the external position
    function assetIsCollateral(address _asset) public view returns (bool isCollateral_) {
        return collateralAssets.contains(_asset);
    }

    /// @notice Gets the debt token associated with a specified asset that has been borrowed
    /// @param _borrowedAsset The asset that has been borrowed
    /// @return debtToken_ The associated debt token
    /// @dev Returns empty if _borrowedAsset is not a valid borrowed asset
    function getDebtTokenForBorrowedAsset(address _borrowedAsset) public view override returns (address debtToken_) {
        return borrowedAssetToDebtToken[_borrowedAsset];
    }
}
