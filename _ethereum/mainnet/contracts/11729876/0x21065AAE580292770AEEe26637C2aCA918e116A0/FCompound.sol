// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./SCompound.sol";
import "./CInstaDapp.sol";
import "./CCompound.sol";
import "./IInstaDapp.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./IPriceOracle.sol";
import "./DSMath.sol";

function _getCToken(address _token) view returns (address) {
    return InstaMapping(INSTA_MAPPING).cTokenMapping(_token);
}

function _wouldCompoundAccountBeLiquid(
    address _dsa,
    uint256 _colAmt,
    address _cTokenModify,
    uint256 _debtAmt
) view returns (bool) {
    AccountLiquidityLocalVars memory vars;

    IComptroller comptroller = IComptroller(COMPTROLLER);

    ICToken[] memory assets = comptroller.getAssetsIn(_dsa);
    for (uint256 i = 0; i < assets.length; i++) {
        ICToken asset = assets[i];
        // Read the balances and exchange rate from the cToken
        vars = _getAssetLiquidity(vars, _dsa, asset);

        // Calculate effects of interacting with cTokenModify
        if (address(asset) == _cTokenModify) {
            vars.sumCollateral = mulScalarTruncateAddUInt(
                vars.tokensToDenom,
                _colAmt,
                vars.sumCollateral
            );

            // borrow effect
            // sumBorrowPlusEffects += oraclePrice * debtAmt
            vars.sumBorrowPlusEffects = mulScalarTruncateAddUInt(
                vars.oraclePrice,
                _debtAmt,
                vars.sumBorrowPlusEffects
            );
        }
    }

    if (assets.length == 0) {
        vars = _getAssetLiquidity(vars, _dsa, ICToken(_cTokenModify));

        vars.sumCollateral = mulScalarTruncateAddUInt(
            vars.tokensToDenom,
            _colAmt,
            vars.sumCollateral
        );

        vars.sumBorrowPlusEffects = mulScalarTruncateAddUInt(
            vars.oraclePrice,
            _debtAmt,
            vars.sumBorrowPlusEffects
        );
    }

    return vars.sumCollateral > vars.sumBorrowPlusEffects;
}

function _getAssetLiquidity(
    AccountLiquidityLocalVars memory vars,
    address _dsa,
    ICToken _asset
) view returns (AccountLiquidityLocalVars memory) {
    uint256 oErr;
    IComptroller comptroller = IComptroller(COMPTROLLER);

    // Read the balances and exchange rate from the cToken
    (oErr, vars.cTokenBalance, vars.borrowBalance, vars.exchangeRate) = ICToken(
        _asset
    )
        .getAccountSnapshot(_dsa);
    require(oErr == 0, "_getAssetLiquidity: semi-opaque error code");
    (, vars.collateralFactor, ) = (comptroller.markets(address(_asset)));
    vars.oraclePrice = IPriceOracle(IComptroller(COMPTROLLER).oracle())
        .getUnderlyingPrice(_asset);
    require(vars.oraclePrice != 0, "");

    vars.tokensToDenom = mul_expScale(
        mul_expScale(vars.collateralFactor, vars.exchangeRate),
        vars.oraclePrice
    );

    vars.sumCollateral = mulScalarTruncateAddUInt(
        vars.tokensToDenom,
        vars.cTokenBalance,
        vars.sumCollateral
    );

    vars.sumBorrowPlusEffects = mulScalarTruncateAddUInt(
        vars.oraclePrice,
        vars.borrowBalance,
        vars.sumBorrowPlusEffects
    );
    return vars;
}

// Compound Math Function

function mulScalarTruncateAddUInt(
    uint256 _a,
    uint256 _b,
    uint256 _addend
) pure returns (uint256) {
    return mul_expScale(_a, _b) + _addend;
}

function mul_expScale(uint256 _a, uint256 _b) pure returns (uint256) {
    return mul(_a, _b) / 1e18;
}

// Compound Math Function
