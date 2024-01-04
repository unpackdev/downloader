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
import "./IERC20.sol";
import "./Require.sol";
import "./Decimal.sol";
import "./Constants.sol";
import "./Permission.sol";
import "./Setters.sol";

contract PoolBonding is Setters, Permission {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant FILE = "Pool";

    constructor(
        IDAO _dao,
        IERC20 _stakingToken,
        IERC20 _rewardsToken1,
        IERC20 _rewardsToken2
    ) public {
        _state.dao = _dao;
        _state.stakingToken = _stakingToken;
        _state.rewardsToken1 = _rewardsToken1;
        _state.rewardsToken2 = _rewardsToken2;
    }

    event Deposit(address indexed account, uint256 value);
    event Withdraw(address indexed account, uint256 value);
    event Claim(address indexed account, address token, uint256 value);
    event Bond(address indexed account, uint256 start, uint256 value);
    event Unbond(address indexed account, uint256 start, uint256 value, uint256 newClaimable1, uint256 newClaimable2);

    function deposit(uint256 value) external onlyFrozen(msg.sender) notPaused {
        stakingToken().transferFrom(msg.sender, address(this), value);
        incrementBalanceOfStaged(msg.sender, value);

        emit Deposit(msg.sender, value);
    }

    function withdraw(uint256 value) external onlyFrozen(msg.sender) validBalance {
        stakingToken().transfer(msg.sender, value);
        decrementBalanceOfStaged(msg.sender, value, "Pool: insufficient staged balance");

        emit Withdraw(msg.sender, value);
    }

    function bond(uint256 value) public validBalance {
        // QSD #B
        // Logic kicks in post bootstrapping epoch - 2
        // -2 to give 1 extra epoch time for ppl to bond
        if (epoch() > 2) {
            if (!bootstrappingAt(epoch().sub(2))) {
                Decimal.D256 memory price = oracleCapture();
                
                Require.that(price.lessThan(Decimal.one()), FILE, "Cannot bond when price >1");
            }
        }

        _bond(value);
    }

    function _bond(uint256 value) internal notPaused {
        unfreeze(msg.sender);

        uint256 totalRewardedWithPhantom1 = totalRewarded1().add(totalPhantom1());
        uint256 newPhantom1 =
            totalBonded() == 0
                ? totalRewarded1() == 0 ? Constants.getInitialStakeMultiple().mul(value) : 0
                : totalRewardedWithPhantom1.mul(value).div(totalBonded());

        uint256 totalRewardedWithPhantom2 = totalRewarded2().add(totalPhantom2());
        uint256 newPhantom2 =
            totalBonded() == 0
                ? totalRewarded2() == 0 ? Constants.getInitialStakeMultiple().mul(value) : 0
                : totalRewardedWithPhantom2.mul(value).div(totalBonded());

        incrementBalanceOfBonded(msg.sender, value);
        incrementBalanceOfPhantom1(msg.sender, newPhantom1);
        incrementBalanceOfPhantom2(msg.sender, newPhantom2);
        decrementBalanceOfStaged(msg.sender, value, "Pool: insufficient staged balance");

        emit Bond(msg.sender, epoch().add(1), value);
    }

    // QSD #C.b
    function unbond(uint256 value) public validBalance {
        unfreeze(msg.sender);

        uint256 balanceOfBonded = balanceOfBonded(msg.sender);
        Require.that(balanceOfBonded > 0, FILE, "insufficient bonded balance");

        uint256 newClaimable1 = balanceOfRewarded1(msg.sender).mul(value).div(balanceOfBonded);
        uint256 newClaimable2 = balanceOfRewarded2(msg.sender).mul(value).div(balanceOfBonded);

        uint256 lessPhantom1 = balanceOfPhantom1(msg.sender).mul(value).div(balanceOfBonded);
        uint256 lessPhantom2 = balanceOfPhantom2(msg.sender).mul(value).div(balanceOfBonded);

        incrementBalanceOfStaged(msg.sender, value);
        incrementBalanceOfClaimable1(msg.sender, newClaimable1);
        incrementBalanceOfClaimable2(msg.sender, newClaimable2);
        decrementBalanceOfBonded(msg.sender, value, "Pool: insufficient bonded balance");
        decrementBalanceOfPhantom1(msg.sender, lessPhantom1, "Pool: insufficient phantom1 balance");
        decrementBalanceOfPhantom2(msg.sender, lessPhantom2, "Pool: insufficient phantom2 balance");

        emit Unbond(msg.sender, epoch().add(1), value, newClaimable1, newClaimable2);
    }

    // Function to allow users to move rewards to claimable
    // while twap is < 1
    function pokeRewards() external {
        uint256 balanceOfBonded = balanceOfBonded(msg.sender);

        unbond(balanceOfBonded);
        _bond(balanceOfBonded);
    }

    function claimAll() external {
        claim1(balanceOfClaimable1(msg.sender));
        claim2(balanceOfClaimable2(msg.sender));
    }

    function claim1(uint256 value) public onlyFrozen(msg.sender) validBalance {
        rewardsToken1().transfer(msg.sender, value);
        decrementBalanceOfClaimable1(msg.sender, value, "Pool: insufficient claimable balance");

        emit Claim(msg.sender, address(rewardsToken1()), value);
    }

    function claim2(uint256 value) public onlyFrozen(msg.sender) validBalance {
        rewardsToken2().transfer(msg.sender, value);
        decrementBalanceOfClaimable2(msg.sender, value, "Pool: insufficient claimable balance");

        emit Claim(msg.sender, address(rewardsToken2()), value);
    }

    function emergencyWithdraw(address token, uint256 value) external onlyDao {
        IERC20(token).transfer(address(dao()), value);
    }

    function emergencyPause() external onlyDao {
        pause();
    }
}
