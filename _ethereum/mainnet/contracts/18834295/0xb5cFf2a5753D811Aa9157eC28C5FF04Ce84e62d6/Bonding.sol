/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>
    Copyright 2023 Lucky8 Lottery

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

pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./Setters.sol";
import "./Permission.sol";
import "./Lottery.sol";
import "./Require.sol";
import "./Constants.sol";

contract Bonding is Lottery, Permission {
    bytes32 private constant FILE = "Bonding";

    event Deposit(address indexed account, uint256 value);
    event Withdraw(address indexed account, uint256 value);
    event Bond(address indexed account, uint256 start, uint256 value, uint256 valueUnderlying);
    event Unbond(address indexed account, uint256 start, uint256 value, uint256 valueUnderlying);

    function step() internal {
        Require.that(
            epochTime() > epoch(),
            FILE,
            "Still current epoch"
        );

        snapshotTotalBonded();
        incrementEpoch();
    }

    function deposit(uint256 value) public {
        token().transferFrom(msg.sender, address(this), value);
        incrementBalanceOfStaged(msg.sender, value);

        emit Deposit(msg.sender, value);
    }

    function withdraw(uint256 value) external onlyFrozenOrLocked(msg.sender) {
        token().transfer(msg.sender, value);
        decrementBalanceOfStaged(msg.sender, value);

        emit Withdraw(msg.sender, value);
    }

    function bond(uint256 value) public onlyFrozenOrFluid(msg.sender) {
        uint256 balance = totalBonded() == 0 ?
            value * (getInitialStakeMultiple()) :
            value * totalSupply() / totalBonded();
        incrementBalanceOf(msg.sender, balance);
        incrementTotalBonded(value);
        decrementBalanceOfStaged(msg.sender, value);

        emit Bond(msg.sender, epoch() + 1, balance, value);
    }

    function depositAndBond(uint256 value) external {
        deposit(value);
        bond(value);
    }

    function unbond(uint256 value) external onlyFrozenOrFluid(msg.sender) {
        unfreeze(msg.sender);

        uint256 staged = value * balanceOfBonded(msg.sender) / balanceOf(msg.sender);
        incrementBalanceOfStaged(msg.sender, staged);
        decrementTotalBonded(staged);
        decrementBalanceOf(msg.sender, value);

        emit Unbond(msg.sender, epoch() + 1, value, staged);
    }

    function unbondUnderlying(uint256 value) external onlyFrozenOrFluid(msg.sender) {
        unfreeze(msg.sender);

        uint256 balance = value * totalSupply() / totalBonded();
        incrementBalanceOfStaged(msg.sender, value);
        decrementTotalBonded(value);
        decrementBalanceOf(msg.sender, balance);

        emit Unbond(msg.sender, epoch() + 1, balance, value);
    }
}
