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
import "./Curve.sol";
import "./Comptroller.sol";
import "./Constants.sol";

contract Market is Comptroller, Curve {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Market";

    event CouponExpiration(uint256 indexed epoch, uint256 couponsExpired, uint256 lessRedeemable, uint256 lessDebt, uint256 newBonded);
    event CouponPurchase(address indexed account, uint256 indexed epoch, uint256 dollarAmount, uint256 couponAmount);
    event CouponRedemption(address indexed account, uint256 indexed epoch, uint256 couponAmount);
    event CouponBurn(address indexed account, uint256 indexed epoch, uint256 couponAmount);
    event CouponTransfer(address indexed from, address indexed to, uint256 indexed epoch, uint256 value);
    event CouponApproval(address indexed owner, address indexed spender, uint256 value);

    function step() internal {
        expireCouponsForEpoch(epoch());
    }

    function expireCouponsForEpoch(uint256 epoch) private {
        uint256 expiredAmount = expiringCoupons(epoch);
        (uint256 lessRedeemable, uint256 lessDebt, uint256 newBonded) = (0, 0, 0);

        expireCoupons(epoch);

        uint256 totalRedeemable = totalRedeemable();
        uint256 totalCoupons = totalCoupons();
        if (totalRedeemable > totalCoupons) {
            lessRedeemable = totalRedeemable.sub(totalCoupons);
            burnRedeemable(lessRedeemable);
            (, lessDebt, newBonded) = increaseSupply(lessRedeemable);
        }

        emit CouponExpiration(epoch, expiredAmount, lessRedeemable, lessDebt, newBonded);
    }

    function baseCouponPremium(uint256 amount) public view returns (uint256) {
        return calculateBasePremium(dollar().totalSupply(), totalDebt(), amount);
    }

    function additionalCouponPremium(uint256 amount, uint256 expirationPeriod) public pure returns (uint256) {
        return calculateAdditionalPremium(amount, expirationPeriod > 2 ? expirationPeriod - 2 : 1);
    }

    function couponPremium(uint256 amount, uint256 expirationPeriod) public view returns (uint256) {
        return calculateCouponPremium(dollar().totalSupply(), totalDebt(), amount, expirationPeriod > 2 ? expirationPeriod - 2 : 1);
    }

    function couponRedemptionPenalty(uint256 couponEpoch, uint256 couponAmount, uint256 expirationPeriod) public view returns (uint256) {
        uint timeIntoEpoch = timeInEpoch();
        uint couponAge = epoch() - couponEpoch;

        uint couponEpochDecay = currentEpochDuration().div(2) * (expirationPeriod - couponAge) / expirationPeriod;

        if(timeIntoEpoch > couponEpochDecay) {
            return 0;
        }

        Decimal.D256 memory couponEpochInitialPenalty = Constants.getInitialCouponRedemptionPenalty().div(Decimal.D256({value: expirationPeriod })).mul(Decimal.D256({value: expirationPeriod - couponAge}));
        Decimal.D256 memory couponEpochDecayedPenalty = couponEpochInitialPenalty.div(Decimal.D256({value: couponEpochDecay})).mul(Decimal.D256({value: couponEpochDecay - timeIntoEpoch}));

        return Decimal.D256({value: couponAmount}).mul(couponEpochDecayedPenalty).value;
    }

    //updates coupons to DAIQIP-3
    function updateCoupons(uint256 _epoch, uint256 expirationPeriod) external {
        uint256 balance = balanceOfCoupons(msg.sender, _epoch);

        Require.that(
            balance > 0,
            FILE,
            "No coupons"
        );

        Require.that(
            couponExpirationForAccount(msg.sender, _epoch) == 0,
            FILE,
            "Coupons already updated"
        );

        uint256 expiration = _epoch.add(expirationPeriod);

        Require.that(
            epoch() < expiration && expirationPeriod <= 100000,
            FILE,
            "Invalid expiration"
        );

        uint256 bonus = balance.div(100);
        uint256 newBalance = balance.add(bonus);
        
        _state.accounts[msg.sender].coupons[_epoch] = newBalance;
        _state.balance.coupons = _state.balance.coupons.add(bonus);
        _state3.couponExpirationsByAccount[msg.sender][_epoch] = expiration;
        _state3.expiringCouponsByEpoch[expiration] = _state3.expiringCouponsByEpoch[expiration].add(newBalance);
    }

    function purchaseCoupons(uint256 dollarAmount, uint256 expirationPeriod) external returns (uint256) {
        Require.that(
            dollarAmount > 0,
            FILE,
            "Must purchase non-zero amount"
        );

        Require.that(
            totalDebt() >= dollarAmount,
            FILE,
            "Not enough debt"
        );

        Require.that(
            expirationPeriod > 2 && expirationPeriod <= 100000,
            FILE,
            "Invalid expiration period"
        );

        Require.that(
            balanceOfCoupons(msg.sender, epoch()) == 0 || couponExpirationForAccount(msg.sender, epoch()) > 0,
            FILE,
            "Coupons not updated"
        );

        Require.that(
            couponExpirationForAccount(msg.sender, epoch()) == 0 || couponExpirationForAccount(msg.sender, epoch()) == epoch().add(expirationPeriod),
            FILE,
            "Cannot set different expiration"
        );

        uint256 epoch = epoch();
        uint256 couponAmount = dollarAmount.add(couponPremium(dollarAmount, expirationPeriod));
        burnFromAccount(msg.sender, dollarAmount);
        incrementBalanceOfCoupons(msg.sender, epoch, couponAmount, epoch.add(expirationPeriod));

        emit CouponPurchase(msg.sender, epoch, dollarAmount, couponAmount);

        return couponAmount;
    }

    function redeemCoupons(uint256 couponEpoch, uint256 couponAmount) external {
        require(epoch().sub(couponEpoch) >= 2, "Market: Too early to redeem");
        require(balanceOfCoupons(msg.sender, couponEpoch) > couponAmount, "Market: Insufficient coupon balance");
        require(couponExpirationForAccount(msg.sender, couponEpoch) > 0, "Market: Coupons not updated");

        decrementBalanceOfCoupons(msg.sender, couponEpoch, couponAmount, "Market: Insufficient coupon balance");

        uint burnAmount = couponRedemptionPenalty(couponEpoch, couponAmount, couponExpirationForAccount(msg.sender, couponEpoch).sub(couponEpoch));
        uint256 redeemAmount = couponAmount - burnAmount;
        
        redeemToAccount(msg.sender, redeemAmount);

        if(burnAmount > 0){
            emit CouponBurn(msg.sender, couponEpoch, burnAmount);
        }

        emit CouponRedemption(msg.sender, couponEpoch, redeemAmount);
    }

    function redeemCoupons(uint256 couponEpoch, uint256 couponAmount, uint256 minOutput) external {
        require(epoch().sub(couponEpoch) >= 2, "Market: Too early to redeem");
        require(balanceOfCoupons(msg.sender, couponEpoch) >= couponAmount, "Market: Insufficient coupon balance");
        require(couponExpirationForAccount(msg.sender, couponEpoch) > 0, "Market: Coupons not updated");

        decrementBalanceOfCoupons(msg.sender, couponEpoch, couponAmount, "Market: Insufficient coupon balance");
        
        uint burnAmount = couponRedemptionPenalty(couponEpoch, couponAmount, couponExpirationForAccount(msg.sender, couponEpoch).sub(couponEpoch));
        uint256 redeemAmount = couponAmount - burnAmount;

        Require.that(
            redeemAmount >= minOutput,
            FILE,
            "Insufficient output amount"
        );
        
        redeemToAccount(msg.sender, redeemAmount);

        if(burnAmount > 0){
            emit CouponBurn(msg.sender, couponEpoch, burnAmount);
        }

        emit CouponRedemption(msg.sender, couponEpoch, redeemAmount);
    }
}
