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

import "./IUniswapV2Pair.sol";
import "./IToken.sol";
import "./ITickets.sol";
import "./Decimal.sol";
import "./Constants.sol";

contract Account {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }

    struct State {
        uint256 staged;
        uint256 balance;
        uint256 fluidUntil;
        uint256 lockedUntil;
    }
}

contract Epoch {
    struct Global {
        uint256 current;
    }

    struct TicketRage {
        uint256 start;
        uint256 end;
    }

    struct State {
        uint256 bonded;

        uint256 prizePerTicket;
        uint256[] winningTickets;
        
        mapping(address => TicketRage) userTicketRange;
        mapping(address => bool) userPriceClaimed;

        uint chainLinkRequestId;
        bool drawExecuted;
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
        IToken token;
        ITickets tickets;
    }

    struct Balance {
        uint256 supply;
        uint256 bonded;
        uint256 staged;
        uint256 userUSDCClaims;
    }

    struct State {
        Epoch.Global epoch;
        Balance balance;
        Provider provider;

        mapping(address => Account.State) accounts;
        mapping(uint256 => Epoch.State) epochs;
        mapping(uint256 => uint256) chainlinkRequestIds; // req id to epoch mapping
        mapping(address => Candidate.State) candidates;
    }
}

contract State is Constants {
    Storage.State _state;
}
