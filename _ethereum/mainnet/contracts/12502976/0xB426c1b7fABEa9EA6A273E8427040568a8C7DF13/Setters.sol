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
import "./State.sol";
import "./Getters.sol";

contract Setters is State, Getters {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * ERC20 Interface
     */

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return false;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return false;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        return false;
    }

    /**
     * Global
     */

    function incrementTotalBonded(uint256 amount) internal {
        _state.balance.bonded = _state.balance.bonded.add(amount);
    }

    function decrementTotalBonded(uint256 amount, string memory reason) internal {
        _state.balance.bonded = _state.balance.bonded.sub(amount, reason);
    }

    function incrementTotalDebt(uint256 amount) internal {
        _state.balance.debt = _state.balance.debt.add(amount);
    }

    function decrementTotalDebt(uint256 amount, string memory reason) internal {
        _state.balance.debt = _state.balance.debt.sub(amount, reason);
    }

    function setDebtToZero() internal {
        _state.balance.debt = 0;
    }

    function incrementTotalRedeemable(uint256 amount) internal {
        _state.balance.redeemable = _state.balance.redeemable.add(amount);
    }

    function decrementTotalRedeemable(uint256 amount, string memory reason) internal {
        _state.balance.redeemable = _state.balance.redeemable.sub(amount, reason);
    }

    /**
     * Account
     */

    function incrementBalanceOf(address account, uint256 amount) internal {
        _state.accounts[account].balance = _state.accounts[account].balance.add(amount);
        _state.balance.supply = _state.balance.supply.add(amount);

        emit Transfer(address(0), account, amount);
    }

    function decrementBalanceOf(address account, uint256 amount, string memory reason) internal {
        _state.accounts[account].balance = _state.accounts[account].balance.sub(amount, reason);
        _state.balance.supply = _state.balance.supply.sub(amount, reason);

        emit Transfer(account, address(0), amount);
    }

    function incrementBalanceOfStaged(address account, uint256 amount) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.add(amount);
        _state.balance.staged = _state.balance.staged.add(amount);
    }

    function decrementBalanceOfStaged(address account, uint256 amount, string memory reason) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.sub(amount, reason);
        _state.balance.staged = _state.balance.staged.sub(amount, reason);
    }

    function incrementBalanceOfCoupons(address account, uint256 epoch, uint256 amount, uint256 expiration) internal {
        _state.accounts[account].coupons[epoch] = _state.accounts[account].coupons[epoch].add(amount); //Adds coupons to user's balance
        _state.balance.coupons = _state.balance.coupons.add(amount); //increments total outstanding coupons
        _state3.couponExpirationsByAccount[account][epoch] = expiration; //sets the expiration epoch for the user's coupons
        _state3.expiringCouponsByEpoch[expiration] = _state3.expiringCouponsByEpoch[expiration].add(amount); //Increments the number of expiring coupons in epoch
    }

    function decrementBalanceOfCoupons(address account, uint256 epoch, uint256 amount, string memory reason) internal {
        _state.accounts[account].coupons[epoch] = _state.accounts[account].coupons[epoch].sub(amount, reason);
        uint256 expiration = _state3.couponExpirationsByAccount[account][epoch];
        _state3.expiringCouponsByEpoch[expiration] = _state3.expiringCouponsByEpoch[expiration].sub(amount, reason);
        _state.balance.coupons = _state.balance.coupons.sub(amount, reason);
    }

    function unfreeze(address account) internal {
        _state.accounts[account].fluidUntil = epoch().add(Constants.getDAOExitLockupEpochs());
    }

    function updateAllowanceCoupons(address owner, address spender, uint256 amount) internal {
        _state.accounts[owner].couponAllowances[spender] = amount;
    }

    function decrementAllowanceCoupons(address owner, address spender, uint256 amount, string memory reason) internal {
        _state.accounts[owner].couponAllowances[spender] =
            _state.accounts[owner].couponAllowances[spender].sub(amount, reason);
    }

    /**
     * Epoch
     */

    function setDAIAdvanceIncentive(uint256 value) internal {
        _state.epoch.daiAdvanceIncentive = value;
    }

    function shouldDistributeDAI(bool should) internal {
        _state.epoch.shouldDistributeDAI = should;
    }

    function setBootstrappingPeriod(uint256 epochs) internal {
        _state.epoch.bootstrapping = epochs;
    }

    function initializeEpochs() internal {
        _state.epoch.currentStart = block.timestamp;
        _state.epoch.currentPeriod = Constants.getEpochStrategy().offset;
    }

    function incrementEpoch() internal {
        _state.epoch.current = _state.epoch.current.add(1);
        _state.epoch.currentStart = _state.epoch.currentStart.add(_state.epoch.currentPeriod);
    }

    function adjustPeriod(Decimal.D256 memory price) internal {
        Decimal.D256 memory normalizedPrice;
        if (price.greaterThan(Decimal.one())) 
            normalizedPrice = Decimal.one().div(price);
        else
            normalizedPrice = price;
        
        Constants.EpochStrategy memory epochStrategy = Constants.getEpochStrategy();
        
        _state.epoch.currentPeriod = normalizedPrice
            .mul(epochStrategy.maxPeriod.sub(epochStrategy.minPeriod))
            .add(epochStrategy.minPeriod)
            .asUint256();
    }

    function snapshotTotalBonded() internal {
        _state.epochs[epoch()].bonded = totalSupply();
    }

    function expireCoupons(uint256 epoch) internal {
        _state.balance.coupons = _state.balance.coupons.sub( _state3.expiringCouponsByEpoch[epoch]);
        _state3.expiringCouponsByEpoch[epoch] = 0;
    }

    /**
    * FixedSwap
    */

    function incrementContributions(uint256 amount) internal {
        _state.bootstrapping.contributions = _state.bootstrapping.contributions.add(amount);
    }

    function decrementContributions(uint256 amount) internal {
        _state.bootstrapping.contributions = _state.bootstrapping.contributions.sub(amount);
    }

    /**
     * Governance
     */

    function createCandidate(address candidate, uint256 period) internal {
        _state.candidates[candidate].start = epoch();
        _state.candidates[candidate].period = period;
    }

    function recordVote(address account, address candidate, Candidate.Vote vote) internal {
        _state.candidates[candidate].votes[account] = vote;
    }

    function incrementApproveFor(address candidate, uint256 amount) internal {
        _state.candidates[candidate].approve = _state.candidates[candidate].approve.add(amount);
    }

    function decrementApproveFor(address candidate, uint256 amount, string memory reason) internal {
        _state.candidates[candidate].approve = _state.candidates[candidate].approve.sub(amount, reason);
    }

    function incrementRejectFor(address candidate, uint256 amount) internal {
        _state.candidates[candidate].reject = _state.candidates[candidate].reject.add(amount);
    }

    function decrementRejectFor(address candidate, uint256 amount, string memory reason) internal {
        _state.candidates[candidate].reject = _state.candidates[candidate].reject.sub(amount, reason);
    }

    function placeLock(address account, address candidate) internal {
        uint256 currentLock = _state.accounts[account].lockedUntil;
        uint256 newLock = startFor(candidate).add(periodFor(candidate));
        if (newLock > currentLock) {
            _state.accounts[account].lockedUntil = newLock;
        }
    }

    function initialized(address candidate) internal {
        _state.candidates[candidate].initialized = true;
    }
}
