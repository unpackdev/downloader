// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IAaveProtocolDataProvider.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ChainLinkInterface.sol";
import "./ILendingPool.sol";
import "./CTokens.sol";
import "./SAave.sol";
import "./CAave.sol";
import "./CTokens.sol";

function _getEtherPrice() view returns (uint256 ethPrice) {
    ethPrice = uint256(ChainLinkInterface(CHAINLINK_ETH_FEED).latestAnswer());
}

function _getUserData(address user)
    view
    returns (AaveUserData memory userData)
{
    (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    ) =
        ILendingPool(
            ILendingPoolAddressesProvider(LENDING_POOL_ADDRESSES_PROVIDER)
                .getLendingPool()
        )
            .getUserAccountData(user);

    userData = AaveUserData(
        totalCollateralETH,
        totalDebtETH,
        availableBorrowsETH,
        currentLiquidationThreshold,
        ltv,
        healthFactor,
        _getEtherPrice()
    );
}

function _getAssetLiquidationThreshold(address _token)
    view
    returns (uint256 liquidationThreshold)
{
    (, , liquidationThreshold, , , , , , , ) = IAaveProtocolDataProvider(
        AAVE_PROTOCOL_DATA_PROVIDER
    )
        .getReserveConfigurationData(_getTokenAddr(_token));
}

function _getTokenAddr(address _token) pure returns (address) {
    return _token == ETH ? WETH : _token;
}
