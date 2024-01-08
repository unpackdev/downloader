/*
    Copyright 2020 Daiquilibrium devs, based on the works of the Dynamic Dollar Devs and the Empty Set Squad

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Decimal.sol";
import "./Constants.sol";

contract Curve {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    function calculateCouponPremium(
        uint256 totalSupply,
        uint256 totalDebt,
        uint256 amount,
        uint256 expirationPeriod
    ) internal pure returns (uint256) {
        return basePremium(totalSupply, totalDebt, amount).add(additionalPremium(expirationPeriod)).mul(amount).asUint256();
    }

    function calculateBasePremium(uint256 totalSupply, uint256 totalDebt, uint256 amount) internal pure returns (uint256) {
        return basePremium(totalSupply, totalDebt, amount).mul(amount).asUint256();
    }

    function calculateAdditionalPremium(uint256 amount, uint256 expirationPeriod) internal pure returns (uint256) {
        return additionalPremium(expirationPeriod).mul(amount).asUint256();
    }

    function basePremium(
        uint256 totalSupply,
        uint256 totalDebt,
        uint256 amount
    ) private pure returns (Decimal.D256 memory) {
        Decimal.D256 memory debtRatio = Decimal.ratio(totalDebt, totalSupply);
        Decimal.D256 memory debtRatioUpperBound = Constants.getDebtRatioCap();

        uint256 totalSupplyEnd = totalSupply.sub(amount);
        uint256 totalDebtEnd = totalDebt.sub(amount);
        Decimal.D256 memory debtRatioEnd = Decimal.ratio(totalDebtEnd, totalSupplyEnd);

        if (debtRatio.greaterThan(debtRatioUpperBound)) {
            if (debtRatioEnd.greaterThan(debtRatioUpperBound)) {
                return curve(debtRatioUpperBound);
            }

            Decimal.D256 memory premiumCurve = curveMean(debtRatioEnd, debtRatioUpperBound);
            Decimal.D256 memory premiumCurveDelta = debtRatioUpperBound.sub(debtRatioEnd);
            Decimal.D256 memory premiumFlat = curve(debtRatioUpperBound);
            Decimal.D256 memory premiumFlatDelta = debtRatio.sub(debtRatioUpperBound);
            return (premiumCurve.mul(premiumCurveDelta)).add(premiumFlat.mul(premiumFlatDelta))
                .div(premiumCurveDelta.add(premiumFlatDelta));
        }

        return curveMean(debtRatioEnd, debtRatio);
    }

    // 0.3 / (1 + P * 0.05)
    function additionalPremium(uint256 expirationPeriod) private pure returns (Decimal.D256 memory) {
        return Decimal.D256({ value: 30e16 }).div(
            Decimal.one().add(Decimal.D256({ value: 5e16 }).mul(expirationPeriod.sub(1)))
        );
    }

    // 1/(6(1-R)^2)-1/6
    function curve(Decimal.D256 memory debtRatio) private pure returns (Decimal.D256 memory) {
        return Decimal.one().div(
            Decimal.from(6).mul((Decimal.one().sub(debtRatio)).pow(2))
        ).sub(Decimal.ratio(1, 6));
    }

    // 1/(6(1-R)(1-R'))-1/6
    function curveMean(
        Decimal.D256 memory lower,
        Decimal.D256 memory upper
    ) private pure returns (Decimal.D256 memory) {
        if (lower.equals(upper)) {
            return curve(lower);
        }

        return Decimal.one().div(
            Decimal.from(6).mul(Decimal.one().sub(upper)).mul(Decimal.one().sub(lower))
        ).sub(Decimal.ratio(1, 6));
    }
}
