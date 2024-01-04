/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

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
import "./IDAO.sol";
import "./Decimal.sol";
import "./State.sol";
import "./Constants.sol";

contract Getters is State {
    using SafeMath for uint256;

    /**
     * Global
     */

    function dai() public view returns (address) {
        return Constants.getDaiAddress();
    }

    function dao() public view returns (IDAO) {
        return _state.dao;
    }

    function totalBonded() public view returns (uint256) {
        return _state.balance.bonded;
    }

    function totalStaged() public view returns (uint256) {
        return _state.balance.staged;
    }

    function totalClaimable1() public view returns (uint256) {
        return _state.balance.claimable1;
    }

    function totalClaimable2() public view returns (uint256) {
        return _state.balance.claimable2;
    }

    function totalPhantom1() public view returns (uint256) {
        return _state.balance.phantom1;
    }

    function totalPhantom2() public view returns (uint256) {
        return _state.balance.phantom2;
    }

    function totalRewarded1() public view returns (uint256) {
        // If staking token and rewards token are the same
        if (stakingToken() == rewardsToken1()) {
            return
                rewardsToken1().balanceOf(address(this)).sub(totalClaimable1()).sub(totalBonded()).sub(totalStaged());
        }

        return rewardsToken1().balanceOf(address(this)).sub(totalClaimable1());
    }

    function totalRewarded2() public view returns (uint256) {
        // If staking token and rewards token are the same
        if (stakingToken() == rewardsToken2()) {
            return
                rewardsToken2().balanceOf(address(this)).sub(totalClaimable2()).sub(totalBonded()).sub(totalStaged());
        }

        return rewardsToken2().balanceOf(address(this)).sub(totalClaimable2());
    }

    function paused() public view returns (bool) {
        return _state.paused;
    }

    /**
     * Account
     */

    function balanceOfStaged(address account) public view returns (uint256) {
        return _state.accounts[account].staged;
    }

    function balanceOfClaimable1(address account) public view returns (uint256) {
        return _state.accounts[account].claimable1;
    }

    function balanceOfClaimable2(address account) public view returns (uint256) {
        return _state.accounts[account].claimable2;
    }

    function balanceOfBonded(address account) public view returns (uint256) {
        return _state.accounts[account].bonded;
    }

    function balanceOfPhantom1(address account) public view returns (uint256) {
        return _state.accounts[account].phantom1;
    }

    function balanceOfPhantom2(address account) public view returns (uint256) {
        return _state.accounts[account].phantom2;
    }

    function balanceOfRewarded1(address account) public view returns (uint256) {
        uint256 totalBonded = totalBonded();
        if (totalBonded == 0) {
            return 0;
        }

        uint256 totalRewardedWithPhantom = totalRewarded1().add(totalPhantom1());
        uint256 balanceOfRewardedWithPhantom = totalRewardedWithPhantom.mul(balanceOfBonded(account)).div(totalBonded);

        uint256 balanceOfPhantom = balanceOfPhantom1(account);
        if (balanceOfRewardedWithPhantom > balanceOfPhantom) {
            return balanceOfRewardedWithPhantom.sub(balanceOfPhantom);
        }
        return 0;
    }

    function balanceOfRewarded2(address account) public view returns (uint256) {
        uint256 totalBonded = totalBonded();
        if (totalBonded == 0) {
            return 0;
        }

        uint256 totalRewardedWithPhantom = totalRewarded2().add(totalPhantom2());
        uint256 balanceOfRewardedWithPhantom = totalRewardedWithPhantom.mul(balanceOfBonded(account)).div(totalBonded);

        uint256 balanceOfPhantom = balanceOfPhantom2(account);
        if (balanceOfRewardedWithPhantom > balanceOfPhantom) {
            return balanceOfRewardedWithPhantom.sub(balanceOfPhantom);
        }
        return 0;
    }

    function statusOf(address account) public view returns (Account.Status) {
        return epoch() >= _state.accounts[account].fluidUntil ? Account.Status.Frozen : Account.Status.Fluid;
    }

    /**
     * Epoch
     */

    function epoch() internal view returns (uint256) {
        return dao().epoch();
    }

    function bootstrappingAt(uint256 epoch) internal returns (bool) {
        return dao().bootstrappingAt(epoch);
    }

    function oracleCapture() internal returns (Decimal.D256 memory) {
        return dao().oracleCaptureP();
    }

    /**
     * Staking Rewards
     */

    function stakingToken() public view returns (IERC20) {
        return _state.stakingToken;
    }

    function rewardsToken1() public view returns (IERC20) {
        return _state.rewardsToken1;
    }

    function rewardsToken2() public view returns (IERC20) {
        return _state.rewardsToken2;
    }
}
