// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./CInstaDapp.sol";
import "./CCompound.sol";
import "./IInstaDapp.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./IPriceOracle.sol";

function _getCToken(address _token) view returns (address) {
    return InstaMapping(INSTA_MAPPING).cTokenMapping(_token);
}

function _wouldCompoundAccountBeLiquid(
    address _dsa,
    address _cColToken,
    uint256 _colAmt,
    address _cDebtToken,
    uint256 _debtAmt
) view returns (bool) {
    IComptroller comptroller = IComptroller(COMPTROLLER);
    IPriceOracle priceOracle = IPriceOracle(comptroller.oracle());

    (, uint256 collateralFactor, ) = comptroller.markets(_cColToken);
    (uint256 error, uint256 liquidity, uint256 shortfall) =
        comptroller.getAccountLiquidity(_dsa);

    require(error == 0, "Get Account Liquidity function failed.");

    return
        mulScalarTruncateAddUInt(
            mul_expScale(collateralFactor, _colAmt),
            priceOracle.getUnderlyingPrice(ICToken(_cColToken)),
            liquidity
        ) >
        mulScalarTruncateAddUInt(
            _debtAmt,
            priceOracle.getUnderlyingPrice(ICToken(_cDebtToken)),
            shortfall
        );
}

function _isCompoundUnderlyingLiquidity(address _debtToken, uint256 _debtAmt)
    view
    returns (bool)
{
    return ICToken(_getCToken(_debtToken)).getCash() > _debtAmt;
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
    return (_a * _b) / 1e18;
}

// Compound Math Function
