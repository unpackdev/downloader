// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ILendingPool.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./IProtocolDataProvider.sol";
import "./IPriceOracle.sol";
import "./IProtectionAction.sol";
import "./CAave.sol";
import "./CProtectionAction.sol";
import "./SProtection.sol";
import "./ERC20.sol";
import "./DSMath.sol";

function _getRepayAndFlashBorrowAmt(
    RepayAndFlashBorrowData memory _rAndWAmtData,
    ILendingPool _lendingPool,
    ILendingPoolAddressesProvider _lendingPoolAddressesProvider
) view returns (RepayAndFlashBorrowResult memory) {
    ProtectionDataCompute memory protectionDataCompute;

    protectionDataCompute.onBehalfOf = _rAndWAmtData.user;
    protectionDataCompute.colToken = _rAndWAmtData.colToken;
    protectionDataCompute.debtToken = _rAndWAmtData.debtToken;
    protectionDataCompute.wantedHealthFactor = _rAndWAmtData.wantedHealthFactor;

    uint256 currenthealthFactor;
    (
        protectionDataCompute.totalCollateralETH,
        protectionDataCompute.totalBorrowsETH,
        ,
        protectionDataCompute.currentLiquidationThreshold,
        ,
        currenthealthFactor
    ) = _lendingPool.getUserAccountData(_rAndWAmtData.user);

    uint256[] memory pricesInETH;
    {
        address[] memory assets = new address[](2);
        assets[0] = _rAndWAmtData.colToken;
        assets[1] = _rAndWAmtData.debtToken;
        // index 0 is colToken to Eth price, and index 1 is debtToken to Eth price
        pricesInETH = IPriceOracle(
            _lendingPoolAddressesProvider.getPriceOracle()
        ).getAssetsPrices(assets);

        protectionDataCompute.colPrice = pricesInETH[0];
        protectionDataCompute.debtPrice = pricesInETH[1];
    }

    (
        ,
        ,
        protectionDataCompute.colLiquidationThreshold,
        ,
        ,
        ,
        ,
        ,
        ,

    ) = IProtocolDataProvider(PROTOCOL_DATA_PROVIDER)
        .getReserveConfigurationData(_rAndWAmtData.colToken);

    protectionDataCompute.protectionFeeInETH = _rAndWAmtData.protectionFeeInETH;
    protectionDataCompute.flashloanPremiumBps = _lendingPool
        .FLASHLOAN_PREMIUM_TOTAL();

    return
        _amountToPaybackAndFlashBorrow(_rAndWAmtData.id, protectionDataCompute);
}

function _amountToPaybackAndFlashBorrow(
    bytes32 _id,
    ProtectionDataCompute memory _protectionDataCompute
) view returns (RepayAndFlashBorrowResult memory) {
    uint256 intermediateValue = _wdiv(
        ((_wmul(
            _protectionDataCompute.wantedHealthFactor,
            _protectionDataCompute.totalBorrowsETH
        ) -
            (
                _qmul(
                    _protectionDataCompute.totalCollateralETH,
                    _protectionDataCompute.currentLiquidationThreshold
                )
            )) +
            _qmul(
                _protectionDataCompute.protectionFeeInETH,
                _protectionDataCompute.colLiquidationThreshold
            )),
        _protectionDataCompute.wantedHealthFactor -
            _qmul(
                _protectionDataCompute.colLiquidationThreshold,
                (TEN_THOUSAND_BPS + _protectionDataCompute.flashloanPremiumBps)
            ) *
            1e14
    );

    uint256 colTokenDecimals = ERC20(_protectionDataCompute.colToken)
        .decimals();
    uint256 debtTokenDecimals = ERC20(_protectionDataCompute.debtToken)
        .decimals();

    return
        RepayAndFlashBorrowResult(
            _id,
            _tokenToTokenPrecision(
                _wdiv(intermediateValue, _protectionDataCompute.colPrice),
                18,
                colTokenDecimals
            ),
            _tokenToTokenPrecision(
                _wdiv(intermediateValue, _protectionDataCompute.debtPrice),
                18,
                debtTokenDecimals
            ),
            "OK"
        );
}

function _tokenToTokenPrecision(
    uint256 _amount,
    uint256 _oldPrecision,
    uint256 _newPrecision
) pure returns (uint256) {
    return
        _oldPrecision > _newPrecision
            ? _amount / (10**(_oldPrecision - _newPrecision))
            : _amount * (10**(_newPrecision - _oldPrecision));
}

function _convertEthToToken(
    ILendingPoolAddressesProvider _lendingPoolAddressesProvider,
    address _token,
    uint256 _amount
) view returns (uint256) {
    address[] memory assets = new address[](1);
    assets[0] = _token;
    return
        _tokenToTokenPrecision(
            _wdiv(
                _amount,
                (
                    IPriceOracle(_lendingPoolAddressesProvider.getPriceOracle())
                        .getAssetsPrices(assets)
                )[0]
            ),
            18,
            ERC20(_token).decimals()
        );
}
