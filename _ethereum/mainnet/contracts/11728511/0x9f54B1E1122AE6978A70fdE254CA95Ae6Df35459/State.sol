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

import "./IERC20.sol";
import "./IDollar.sol";
import "./IDAO.sol";

contract Account {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }

    struct State {
        uint256 staged;
        uint256 claimable1;
        uint256 claimable2;
        uint256 bonded;
        uint256 phantom1;
        uint256 phantom2;
        uint256 fluidUntil;
    }
}

contract Storage {
    struct Balance {
        uint256 staged;
        uint256 claimable1;
        uint256 claimable2;
        uint256 bonded;
        uint256 phantom1;
        uint256 phantom2;
    }

    struct State {
        IDAO dao;

        IERC20 stakingToken;
        IERC20 rewardsToken1;
        IERC20 rewardsToken2;

        Balance balance;
        bool paused;

        mapping(address => Account.State) accounts;
    }
}

contract State {
    Storage.State _state;
}
