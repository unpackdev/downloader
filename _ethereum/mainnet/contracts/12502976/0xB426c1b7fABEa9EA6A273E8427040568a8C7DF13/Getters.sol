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
import "./Constants.sol";

contract Getters is State {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * ERC20 Interface
     */

    function name() public view returns (string memory) {
        return "DAIQ Stake";
    }

    function symbol() public view returns (string memory) {
        return "DAIQS";
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _state.accounts[account].balance;
    }

    function totalSupply() public view returns (uint256) {
        return _state.balance.supply;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return 0;
    }

    /**
     * Global
     */

    function dollar() public view returns (IDollar) {
        return _state.provider.dollar;
    }

    function oracle() public view returns (IOracle) {
        return _state.provider.oracle;
    }

    function pool() public view returns (address) {
        return _state.provider.pool;
    }

    function dai() public view returns (IERC20) {
        return IERC20(Constants.getDAIAddress());
    }

    function totalBonded() public view returns (uint256) {
        return _state.balance.bonded;
    }

    function totalStaged() public view returns (uint256) {
        return _state.balance.staged;
    }

    function totalDebt() public view returns (uint256) {
        return _state.balance.debt;
    }

    function totalRedeemable() public view returns (uint256) {
        return _state.balance.redeemable;
    }

    function totalCoupons() public view returns (uint256) {
        return _state.balance.coupons;
    }

    function totalNet() public view returns (uint256) {
        return dollar().totalSupply().sub(totalDebt());
    }

    /**
     * Account
     */

    function balanceOfStaged(address account) public view returns (uint256) {
        return _state.accounts[account].staged;
    }

    function balanceOfBonded(address account) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            return 0;
        }
        return totalBonded().mul(balanceOf(account)).div(totalSupply);
    }

    function balanceOfCoupons(address account, uint256 _epoch) public view returns (uint256) {
        uint256 expiration = couponExpirationForAccount(account, _epoch);
        
        if (expiration > 0 && epoch() >= expiration) {
            return 0;
        }

        return _state.accounts[account].coupons[_epoch];
    }

    function couponExpirationForAccount(address account, uint256 epoch) public view returns (uint256) {
        return _state3.couponExpirationsByAccount[account][epoch];
    }

    function statusOf(address account) public view returns (Account.Status) {
        if (_state.accounts[account].lockedUntil > epoch()) {
            return Account.Status.Locked;
        }

        return epoch() >= _state.accounts[account].fluidUntil ? Account.Status.Frozen : Account.Status.Fluid;
    }

    function allowanceCoupons(address owner, address spender) public view returns (uint256) {
        return _state.accounts[owner].couponAllowances[spender];
    }

    /**
    * Epoch
    */

    function epoch() public view returns (uint256) {
        return _state.epoch.current;
    }

    function epochTime() public view returns (uint256) {
        return block.timestamp >= nextEpochStart()
            ? epoch().add(1)
            : epoch();
    }

    function timeInEpoch() public view returns (uint256) {
        return block.timestamp.sub(_state.epoch.currentStart);
    }

    function timeLeftInEpoch() public view returns (uint256) {
        if (block.timestamp > nextEpochStart()) 
            return 0;

        return nextEpochStart().sub(block.timestamp);
    }

    function currentEpochDuration() public view returns (uint256) {
        return _state.epoch.currentPeriod;
    }

    function nextEpochStart() public view returns (uint256) {
        return _state.epoch.currentStart.add(_state.epoch.currentPeriod);
    }

    function currentEpochStart() public view returns (uint256) {
        return _state.epoch.currentStart;
    }

    function expiringCoupons(uint256 epoch) public view returns (uint256) {
        return _state3.expiringCouponsByEpoch[epoch];
    }

    function totalBondedAt(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].bonded;
    }

    function bootstrappingPeriod() public view returns (uint256) {
        return 0;
    }

    function bootstrappingAt(uint256 epoch) public view returns (bool) {
        return epoch <= bootstrappingPeriod();
    }

    function daiAdvanceIncentive() public view returns (uint256) {
        return _state.epoch.daiAdvanceIncentive;
    }

    function shouldDistributeDAI() public view returns (bool) {
        return _state.epoch.shouldDistributeDAI;
    }

    /**
    * FixedSwap
    */

    function totalContributions() public view returns (uint256) {
        return _state.bootstrapping.contributions;
    }

    /**
     * Governance
     */

    function recordedVote(address account, address candidate) public view returns (Candidate.Vote) {
        return _state.candidates[candidate].votes[account];
    }

    function startFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].start;
    }

    function periodFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].period;
    }

    function approveFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].approve;
    }

    function rejectFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].reject;
    }

    function votesFor(address candidate) public view returns (uint256) {
        return approveFor(candidate).add(rejectFor(candidate));
    }

    function isNominated(address candidate) public view returns (bool) {
        return _state.candidates[candidate].start > 0;
    }

    function isInitialized(address candidate) public view returns (bool) {
        return _state.candidates[candidate].initialized;
    }

    function implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
}
