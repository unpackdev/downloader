// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./FAave.sol";
import "./SAave.sol";
import "./GelatoBytes.sol";
import "./DSMath.sol";
import "./IOracleAggregator.sol";
import "./CTokens.sol";
import "./Convert.sol";

function _aavePositionWillBeSafe(
    address _dsa,
    uint256 _colAmt,
    address _colToken,
    uint256 _debtAmt,
    address _oracleAggregator
) view returns (bool) {
    uint256 _colAmtInETH;
    uint256 _decimals;
    IOracleAggregator oracleAggregator = IOracleAggregator(_oracleAggregator);

    AaveUserData memory userData = _getUserData(_dsa);

    if (_colToken == ETH) _colAmtInETH = _colAmt;
    else {
        (_colAmtInETH, _decimals) = oracleAggregator.getExpectedReturnAmount(
            _colAmt,
            _colToken,
            ETH
        );

        _colAmtInETH = _convertTo18(_decimals, _colAmtInETH);
    }

    (_debtAmt, _decimals) = oracleAggregator.getExpectedReturnAmount(
        _debtAmt,
        DAI,
        ETH
    );
    _debtAmt = _convertTo18(_decimals, _debtAmt);

    //
    //                  __
    //                  \
    //                  /__ (Collateral)i in ETH x (Liquidation Threshold)i
    //  HealthFactor =  _________________________________________________
    //
    //                  Total Borrows in ETH + Total Fees in ETH
    //

    return
        wdiv(
            (
                (mul(
                    userData.currentLiquidationThreshold,
                    userData.totalCollateralETH
                ) + mul(_colAmtInETH, _getAssetLiquidationThreshold(_colToken)))
            ) / 1e4,
            userData.totalBorrowsETH + _debtAmt
        ) > 1e18;
}
