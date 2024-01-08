// "SPDX-License-Identifier: GNU General Public License v3.0"

pragma solidity 0.7.6;

import "./AggregatorV3Interface.sol";
import "./SafeMath.sol";
import "./IRepricer.sol";
import "./Const.sol";
import "./Num.sol";
import "./NumExtra.sol";

//import "./console.sol";

contract x5Repricer is IRepricer,  Const, Num, NumExtra {
    int public constant NEGATIVE_INFINITY = type(int256).min;

    function isRepricer() external override pure returns(bool) {
        return true;
    }

    function symbol() external override pure returns (string memory) {
        return "x5Repricer";
    }

    function reprice(
        uint pMin,
        int volatility,
        IVault _vault,
        uint[2] memory primary,
        uint[2] memory complement,
        int _liveUnderlingValue
    )
    external view override returns(
        uint newPrimaryLeverage, uint newComplementLeverage, int estPricePrimary, int estPriceComplement
    ) {

        require(address(_vault) != address(0), "Zero oracle");

        (estPricePrimary, estPriceComplement) = calcEstPrice(
            calcDenomination(_vault),
            calcUnv(
                _liveUnderlingValue,
                getCurrentUnderlingValue(_vault)
            ),
            calcTtm(_vault.settleTime()),
            int(pMin),
            volatility
        );
        uint estPrice = uint(estPriceComplement * iBONE / estPricePrimary);

        uint leveragesMultiplied = mul(primary[1], complement[1]);

        newPrimaryLeverage = uint(sqrt(
                int(div(
                    mul(leveragesMultiplied, mul(complement[0], estPrice)),
                    primary[0]
                )))
        );
        newComplementLeverage = div(leveragesMultiplied, newPrimaryLeverage);
    }

    function getCurrentUnderlingValue(IVault _vault)
    internal view returns(int currentUnderlingValue) {
        uint currentTimestamp;
        (,currentUnderlingValue,,currentTimestamp,) = AggregatorV3Interface(_vault.oracles(0)).latestRoundData();
        require(currentTimestamp > 0, "EMPTY_ORACLE_LATEST_ROUND");
    }

    function calcTtm(uint _settledTimestamp)
    internal view returns(int) {
        return (int(_settledTimestamp) - int(block.timestamp)) * iBONE / 31536000; // 365 * 24 * 3600
    }

    function calcUnv(int _liveUnderlingValue, int _currentUnderlingValue)
    internal pure returns(int) {
        return 5 * iBONE + 5 * ((_currentUnderlingValue - _liveUnderlingValue) * iBONE / _liveUnderlingValue);
    }

    function calcDenomination(IVault _vault) internal view returns (int denomination) {
        denomination = int(
            _vault.derivativeSpecification().primaryNominalValue() +
            _vault.derivativeSpecification().complementNominalValue()
        );
    }

    function calcEstPricePrimary(
        int _unvPrim,
        int _ttm,
        int _volatility
    ) internal pure returns(int256) {
        int volatilityBySqrtTtm = _volatility * sqrt(_ttm) / iBONE;
        int multiplier = (iBONE * iBONE) / volatilityBySqrtTtm;
        int volatilityByTtm = (_volatility * _volatility) * _ttm / (iBONE * iBONE * 2);

        int d1 = multiplier  * (ln(_unvPrim/4) + volatilityByTtm) / iBONE;
        int option4 = ncdf(d1) * _unvPrim / iBONE - ncdf(d1 - volatilityBySqrtTtm) * 4;

        d1 = multiplier  * (ln(_unvPrim/6) +  volatilityByTtm) / iBONE;
        int option6 = ncdf(d1) * _unvPrim / iBONE - ncdf(d1 - volatilityBySqrtTtm) * 6;

        return option4 - option6;
    }

    function calcEstPrice(
        int _denomination,
        int _unvPrim,
        int _ttm,
        int _pMin,
        int _volatility
    )
    internal pure returns(int estPricePrimary, int estPriceComplement)
    {
        estPricePrimary = calcEstPricePrimary(_unvPrim, _ttm, _volatility);

        if(estPricePrimary < _pMin) {
            estPricePrimary = _pMin;
        }

        int denominationTimesBone = _denomination * iBONE;
        if(estPricePrimary > denominationTimesBone - _pMin) {
            estPricePrimary = denominationTimesBone - _pMin;
        }

        estPriceComplement = denominationTimesBone - estPricePrimary;
    }
}
