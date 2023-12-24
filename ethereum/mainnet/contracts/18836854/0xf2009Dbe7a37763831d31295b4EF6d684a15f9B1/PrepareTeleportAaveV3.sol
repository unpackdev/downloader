//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IPoolAddressesProvider.sol";
import "./IPoolDataProvider.sol";
import "./IPool.sol";
import "./TeleportAaveV3.sol";
import "./IERC20.sol";
import "./ICreditDelegationToken.sol";

contract PrepareTeleportAaveV3 {
    TeleportAaveV3 teleportAaveV3;
    IPoolDataProvider iPoolDataProvider;
    IPool iPool;

    struct AaveUserDataOnOneAsset {
        uint256 currentATokenBalance;
        uint256 currentStableDebt;
        uint256 currentVariableDebt;
        uint256 principalStableDebt;
        uint256 scaledVariableDebt;
        uint256 stableBorrowRate;
        uint256 liquidityRate;
        uint40 stableRateLastUpdated;
        bool usageAsCollateralEnabled;
    }

    struct AaveUserDataList {
        address[] aaveReserveTokenList;
        uint256[] tokensAmountsThatUserDepositedInAave;
        bool[] areTokensCollateralThatUserDepositedInAave;
        uint256[] tokensAmountThatUserStableBorrowedFromAave;
        uint256[] tokensAmountsThatUserVariableBorrowedFromAave;
    }

    constructor(IPoolDataProvider _iPoolDataProvider, IPool _iPool, TeleportAaveV3 _teleportAaveV3) {
        iPoolDataProvider = _iPoolDataProvider;
        iPool = _iPool;
        teleportAaveV3 = _teleportAaveV3;
    }

    function getAllAaveV3PositionsToMoveViaTeleportAaveV3(address _user)
        external
        view
        returns (
            address[] memory assetsUserBorrowed,
            uint256[] memory amountsUserBorrowed,
            uint256[] memory interestRateModesForPositions,
            uint256[] memory interestRateModesForFL,
            address[] memory aTokenAssetsToMove,
            uint256[] memory aTokenAmountsToMove
        )
    {
        AaveUserDataList memory sourceWalletAaveDataList = getAaveUserDataForAllAssets(_user);
        (assetsUserBorrowed, amountsUserBorrowed, interestRateModesForPositions, interestRateModesForFL) =
            _getAssetsToBorrowFromFLToRepayAaveDebt(sourceWalletAaveDataList);

        (aTokenAssetsToMove, aTokenAmountsToMove) = _getATokenAssetToMoveToDestinationWallet(_user);

        return (
            assetsUserBorrowed,
            amountsUserBorrowed,
            interestRateModesForPositions,
            interestRateModesForFL,
            aTokenAssetsToMove,
            aTokenAmountsToMove
        );
    }

    /*
    * @notice this function returns the postion (deposit, borrow) of an user for in the Aave market for all assets
    * @param _user the address of the user 
    * @dev this function is public because it is used by the frontend to display the Aave position of an user
    * 
    */

    function getAaveUserDataForAllAssets(address _user) public view returns (AaveUserDataList memory) {
        address[] memory aaveReserveTokenList = getAaveMarketReserveTokenList();
        uint256[] memory tokensAmountsThatUserDepositedInAave = new uint256[](aaveReserveTokenList.length);
        bool[] memory areTokensCollateralThatUserDepositedInAave = new bool[](aaveReserveTokenList.length);
        uint256[] memory tokensAmountThatUserStableBorrowedFromAave = new uint256[](aaveReserveTokenList.length);
        uint256[] memory tokensAmountsThatUserVariableBorrowedFromAave = new uint256[](aaveReserveTokenList.length);

        for (uint256 i = 0; i < aaveReserveTokenList.length; i++) {
            AaveUserDataOnOneAsset memory aaveUserDataOnOneAsset =
                _getAavePositionOfUserByAsset(aaveReserveTokenList[i], _user);
            if (aaveUserDataOnOneAsset.currentATokenBalance > 0) {
                tokensAmountsThatUserDepositedInAave[i] = aaveUserDataOnOneAsset.currentATokenBalance;
                areTokensCollateralThatUserDepositedInAave[i] = aaveUserDataOnOneAsset.usageAsCollateralEnabled;
            }
            if (aaveUserDataOnOneAsset.currentStableDebt > 0) {
                tokensAmountThatUserStableBorrowedFromAave[i] = aaveUserDataOnOneAsset.currentStableDebt;
            }
            if (aaveUserDataOnOneAsset.currentVariableDebt > 0) {
                tokensAmountsThatUserVariableBorrowedFromAave[i] = aaveUserDataOnOneAsset.currentVariableDebt;
            }
        }
        return AaveUserDataList({
            aaveReserveTokenList: aaveReserveTokenList,
            tokensAmountsThatUserDepositedInAave: tokensAmountsThatUserDepositedInAave,
            areTokensCollateralThatUserDepositedInAave: areTokensCollateralThatUserDepositedInAave,
            tokensAmountThatUserStableBorrowedFromAave: tokensAmountThatUserStableBorrowedFromAave,
            tokensAmountsThatUserVariableBorrowedFromAave: tokensAmountsThatUserVariableBorrowedFromAave
        });
    }

    /*
    * @notice this function returns the postion (deposit, borrow) of an user for one asset in the Aave market
    * @param _asset the address of the asset
    * @param _user the address of the user
    * @dev this function is used by getAaveUserDataForAllAssets
    */
    function _getAavePositionOfUserByAsset(address _asset, address _user)
        private
        view
        returns (AaveUserDataOnOneAsset memory)
    {
        (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        ) = iPoolDataProvider.getUserReserveData(_asset, _user);
        return AaveUserDataOnOneAsset({
            currentATokenBalance: currentATokenBalance,
            currentStableDebt: currentStableDebt,
            currentVariableDebt: currentVariableDebt,
            principalStableDebt: principalStableDebt,
            scaledVariableDebt: scaledVariableDebt,
            stableBorrowRate: stableBorrowRate,
            liquidityRate: liquidityRate,
            stableRateLastUpdated: stableRateLastUpdated,
            usageAsCollateralEnabled: usageAsCollateralEnabled
        });
    }

    /**
     *  @notice this function prepare the array of asset to borrow from FlashLoan to repay Aave debt for an user
     *  @param _aaveUserDataList the data of the Aave position to migrate : for gas efficiency you need to feed this variable with
     *                           only the data of the Aave position you want to migrate
     */
    function _getAssetsToBorrowFromFLToRepayAaveDebt(AaveUserDataList memory _aaveUserDataList)
        private
        pure
        returns (
            address[] memory assetsUserBorrowed,
            uint256[] memory amountsUserBorrowed,
            uint256[] memory interestRateModesForPositions,
            uint256[] memory interestRateModesForFL
        )
    {
        uint256 lengthOfAssetsToBorrowArray = 0;

        for (uint256 i = 0; i < _aaveUserDataList.aaveReserveTokenList.length; i++) {
            if (_aaveUserDataList.tokensAmountsThatUserVariableBorrowedFromAave[i] > 0) {
                lengthOfAssetsToBorrowArray++;
            }
            if (_aaveUserDataList.tokensAmountThatUserStableBorrowedFromAave[i] > 0) {
                lengthOfAssetsToBorrowArray++;
            }
        }
        assetsUserBorrowed = new address[](lengthOfAssetsToBorrowArray);
        amountsUserBorrowed = new uint256[](lengthOfAssetsToBorrowArray);
        interestRateModesForPositions = new uint256[](lengthOfAssetsToBorrowArray);
        interestRateModesForFL = new uint256[](lengthOfAssetsToBorrowArray);
        uint256 indexOfAssetToBorrowForPositions = 0;

        for (uint256 i = 0; i < _aaveUserDataList.aaveReserveTokenList.length; i++) {
            if (_aaveUserDataList.tokensAmountsThatUserVariableBorrowedFromAave[i] > 0) {
                assetsUserBorrowed[indexOfAssetToBorrowForPositions] = _aaveUserDataList.aaveReserveTokenList[i];
                amountsUserBorrowed[indexOfAssetToBorrowForPositions] =
                    _aaveUserDataList.tokensAmountsThatUserVariableBorrowedFromAave[i];
                interestRateModesForPositions[indexOfAssetToBorrowForPositions] = 2; // 2: variable mode debt
                indexOfAssetToBorrowForPositions++;
            }
            if (_aaveUserDataList.tokensAmountThatUserStableBorrowedFromAave[i] > 0) {
                assetsUserBorrowed[indexOfAssetToBorrowForPositions] = _aaveUserDataList.aaveReserveTokenList[i];
                amountsUserBorrowed[indexOfAssetToBorrowForPositions] =
                    _aaveUserDataList.tokensAmountThatUserStableBorrowedFromAave[i];
                interestRateModesForPositions[indexOfAssetToBorrowForPositions] = 1; // 1: stable mode debt
                indexOfAssetToBorrowForPositions++;
            }
        }
    }

    /*
    * @notice this function prepare the array of AToken asset (represent deposited tokens) to move from the _from wallet to the _to wallet
    * @param _from the address of the wallet that has the Aave position
    * @dev this function is used by teleportAaveV3PositionsBetweenWallets to prepare the data to send to the TeleportAaveV3 contract
    */
    function _getATokenAssetToMoveToDestinationWallet(address _from)
        private
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory reserveTokensList = getAaveMarketReserveTokenList();
        uint256 lengthOfAssetToMoveArray;
        for (uint256 i = 0; i < reserveTokensList.length; i++) {
            address aToken = _getAToken(reserveTokensList[i]);
            if (IERC20(aToken).balanceOf(_from) > 0) {
                lengthOfAssetToMoveArray++;
            }
        }
        address[] memory aTokenAssetsToMove = new address[](lengthOfAssetToMoveArray);
        uint256[] memory aTokenAmountsToMove = new uint256[](lengthOfAssetToMoveArray);
        uint256 indexOfATokenToMove = 0;
        for (uint256 i = 0; i < reserveTokensList.length; i++) {
            address aToken = _getAToken(reserveTokensList[i]);

            if (IERC20(aToken).balanceOf(_from) > 0) {
                aTokenAssetsToMove[indexOfATokenToMove] = aToken;
                aTokenAmountsToMove[indexOfATokenToMove] = IERC20(aToken).balanceOf(_from);
                indexOfATokenToMove++;
            }
        }
        return (aTokenAssetsToMove, aTokenAmountsToMove);
    }

    function updateReserveDataCollateralStatus(address _tokenReserve, bool _newCollateralStatus) public {
        iPool.setUserUseReserveAsCollateral(_tokenReserve, _newCollateralStatus);
    }

    function getVariableDebtToken(address _tokenReserve) public view returns (address) {
        return iPool.getReserveData(_tokenReserve).variableDebtTokenAddress;
    }

    function getStableDebtToken(address _tokenReserve) public view returns (address) {
        return iPool.getReserveData(_tokenReserve).stableDebtTokenAddress;
    }

    function _getAaveMarketATokenList() private view returns (IPoolDataProvider.TokenData[] memory) {
        return iPoolDataProvider.getAllATokens();
    }

    function getAaveMarketReserveTokenList() public view returns (address[] memory) {
        return iPool.getReservesList();
    }

    function _getAToken(address _tokenReserve) private view returns (address) {
        return iPool.getReserveData(_tokenReserve).aTokenAddress;
    }
}
