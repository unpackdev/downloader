/*
    Copyright 2020 VTD team, based on the works of Dynamic Dollar Devs and Empty Set Squad

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
import "./Comptroller.sol";
import "./Decimal.sol";
import "./Constants.sol";

contract Regulator is Comptroller {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    event SupplyIncrease(uint256 indexed epoch, uint256 price, uint256 momentumPrice, uint256 newRedeemable, uint256 lessDebt, uint256 newBonded);
    event SupplyDecrease(uint256 indexed epoch, uint256 price, uint256 momentumPrice, uint256 newDebt);
    event SupplyNeutral(uint256 indexed epoch);
    event EpochTimeVariable(uint256 epochPeriod);

    function step() internal {
        Decimal.D256 memory price = oracleCapture();
        setEpochPrice(price);

        Decimal.D256 memory newMomentum = getPriceMomentum().mul(Constants.getPriceMomentumBeta()).add(price.mul(Decimal.one().sub(Constants.getPriceMomentumBeta())));
        if (price.greaterThan(newMomentum)) {
            setDebtToZero();
            growSupply(price, newMomentum);
            setPriceMomentum(newMomentum);
            return;
        }

        if (price.lessThan(newMomentum)) {
            shrinkSupply(price, newMomentum);
            setPriceMomentum(newMomentum);
            return;
        }

        emit SupplyNeutral(epoch());
    }

    function shrinkSupply(Decimal.D256 memory price, Decimal.D256 memory baseline) private {
        Decimal.D256 memory delta = debtLimit(baseline.sub(price).div(calcSupplyChangeFactor()));
        uint256 newDebt = delta.mul(totalNet()).asUint256();
        increaseDebt(newDebt);
        shrinkEpoch(delta);

        emit SupplyDecrease(epoch(), price.value, baseline.value, newDebt);
        return;
    }

    function growSupply(Decimal.D256 memory price, Decimal.D256 memory baseline) private {
        Decimal.D256 memory delta = limit(price.sub(baseline).div(calcSupplyChangeFactor()));
        uint256 newSupply = delta.mul(totalNet()).asUint256();
        (uint256 newRedeemable, uint256 lessDebt, uint256 newBonded) = increaseSupply(newSupply);
        growEpoch(delta);

        emit SupplyIncrease(epoch(), price.value, baseline.value, newRedeemable, lessDebt, newBonded);
    }

    function growEpoch(Decimal.D256 memory delta) private {
        uint256 newAdjustmentAmount = Constants.getEpochGrowthBeta().mul(epochAdjustmentAmount()).add(delta.mul(epochGrowthConstant())).asUint256();
        setEpochAdjustmentAmount(newAdjustmentAmount);
    }

    function shrinkEpoch(Decimal.D256 memory delta) private {
        uint256 newAdjustmentAmount = Decimal.one().sub(delta).mul(epochAdjustmentAmount()).asUint256();
        setEpochAdjustmentAmount(newAdjustmentAmount);
    }

    function limit(Decimal.D256 memory delta) private view returns (Decimal.D256 memory) {
        Decimal.D256 memory supplyChangeLimit = Constants.getSupplyChangeLimit();

        return delta.greaterThan(supplyChangeLimit) ? supplyChangeLimit : delta;
    }

    function debtLimit(Decimal.D256 memory delta) private view returns (Decimal.D256 memory) {
        Decimal.D256 memory supplyChangeLimit = Constants.getDebtChangeLimit();

        return delta.greaterThan(supplyChangeLimit) ? supplyChangeLimit : delta;
    }

    function oracleCapture() private returns (Decimal.D256 memory) {
        (Decimal.D256 memory price, bool valid) = peggingSystemStep();

        if (bootstrappingAt(epoch().sub(1))) {
            return Constants.getBootstrappingPrice();
        }
        if (!valid) {
            return Decimal.one();
        }

        return price;
    }
}
