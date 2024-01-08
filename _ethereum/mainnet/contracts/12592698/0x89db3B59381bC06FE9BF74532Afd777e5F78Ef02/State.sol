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

import "./IUniswapV2Pair.sol";
import "./IDollar.sol";
import "./IOracle.sol";
import "./Decimal.sol";

contract Account {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }

    struct State {
        uint256 staged;
        uint256 balance;
        mapping(uint256 => uint256) coupons;
        mapping(address => uint256) couponAllowances; //unused since DAIQIP-3
        uint256 fluidUntil;
        uint256 lockedUntil;
    }
}

contract Bootstrapping {
    struct State {
        uint256 contributions;
    }
}

contract Epoch {
    struct Global {
        uint256 current;
        uint256 currentStart;
        uint256 currentPeriod;
        uint256 bootstrapping;
        uint256 daiAdvanceIncentive;
        bool shouldDistributeDAI;
    }

    struct Coupons {
        uint256 outstanding; //unused since DAIQIP-3
        uint256 expiration; //unused since DAIQIP-3
        uint256[] expiring; //unused since DAIQIP-3
    }

    struct State {
        uint256 bonded;
        Coupons coupons; //unused since DAIQIP-3
    }
}

contract Candidate {
    enum Vote {
        UNDECIDED,
        APPROVE,
        REJECT
    }

    struct State {
        uint256 start;
        uint256 period;
        uint256 approve;
        uint256 reject;
        mapping(address => Vote) votes;
        bool initialized;
    }
}

contract Storage {
    struct Provider {
        IDollar dollar;
        IOracle oracle;
        address pool;
    }

    struct Balance {
        uint256 supply;
        uint256 bonded;
        uint256 staged;
        uint256 redeemable;
        uint256 debt;
        uint256 coupons;
    }

    struct State {
        Epoch.Global epoch;
        Bootstrapping.State bootstrapping;
        Balance balance;
        Provider provider;

        mapping(address => Account.State) accounts;
        mapping(uint256 => Epoch.State) epochs;
        mapping(address => Candidate.State) candidates;
    }

    struct State3 {
        mapping(address => mapping(uint256 => uint256)) couponExpirationsByAccount;
        mapping(uint256 => uint256) expiringCouponsByEpoch;
    }
}

contract State {
    Storage.State _state;

    //DAIQIP-3
    Storage.State3 _state3;
}
