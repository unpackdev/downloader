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

import "./State.sol";
import "./Getters.sol";

contract Setters is State, Getters {

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
        _state.balance.bonded = _state.balance.bonded + amount;
    }

    function decrementTotalBonded(uint256 amount) internal {
        _state.balance.bonded = _state.balance.bonded - amount;
    }

    function incrementUserUSDCClaims(uint256 amount) internal {
        _state.balance.userUSDCClaims = _state.balance.userUSDCClaims + amount;
    }

    function decrementUserUSDCClaims(uint256 amount) internal {
        _state.balance.userUSDCClaims = _state.balance.userUSDCClaims - amount;
    }

    /**
     * Account
     */

    function incrementBalanceOf(address account, uint256 amount) internal {
        _state.accounts[account].balance = _state.accounts[account].balance + amount;
        _state.balance.supply = _state.balance.supply + amount;

        emit Transfer(account, address(0), amount);
    }

    function decrementBalanceOf(address account, uint256 amount) internal {
        _state.accounts[account].balance = _state.accounts[account].balance - amount;
        _state.balance.supply = _state.balance.supply - amount;

        emit Transfer(address(0), account, amount);
    }

    function incrementBalanceOfStaged(address account, uint256 amount) internal {
        _state.accounts[account].staged = _state.accounts[account].staged + amount;
        _state.balance.staged = _state.balance.staged + amount;
    }

    function decrementBalanceOfStaged(address account, uint256 amount) internal {
        _state.accounts[account].staged = _state.accounts[account].staged - amount;
        _state.balance.staged = _state.balance.staged - amount;
    }

    function unfreeze(address account) internal {
        _state.accounts[account].fluidUntil = epoch() + getDAOExitLockupEpochs();
    }

    /**
     * Epoch
     */

    function incrementEpoch() internal {
        _state.epoch.current = _state.epoch.current + (1);
    }

    function snapshotTotalBonded() internal {
        _state.epochs[epoch()].bonded = totalBonded();
    }

    /**
     * Lottery
     */
    
    function setUserTicketRange(address user, uint256 epoch, uint start, uint end) internal {
        _state.epochs[epoch].userTicketRange[user].start = start;
        _state.epochs[epoch].userTicketRange[user].end = end;
    }

    function setPrizePerTicket(uint epoch, uint price) internal {
        _state.epochs[epoch].prizePerTicket = price;
    }

    function setUserPriceClaimed(uint epoch, address user, bool value) internal {
        _state.epochs[epoch].userPriceClaimed[user] = value;
    }

    function initWinningTicketsArray(uint epoch, uint winningTickets) internal {
        _state.epochs[epoch].winningTickets = new uint256[](winningTickets);
    }

    function setDrawExecuted(uint epoch, bool) internal {
        _state.epochs[epoch].drawExecuted = true;
    }

    function setWinningTicket(uint epoch, uint index, uint value) internal {
        _state.epochs[epoch].winningTickets[index] = value;
    }

    function setChainlinkRequestId(uint epoch, uint requestId) internal {
        _state.epochs[epoch].chainLinkRequestId = requestId;
        _state.chainlinkRequestIds[requestId] = epoch;
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
        _state.candidates[candidate].approve = _state.candidates[candidate].approve + amount;
    }

    function decrementApproveFor(address candidate, uint256 amount) internal {
        _state.candidates[candidate].approve = _state.candidates[candidate].approve - amount;
    }

    function incrementRejectFor(address candidate, uint256 amount) internal {
        _state.candidates[candidate].reject = _state.candidates[candidate].reject + amount;
    }

    function decrementRejectFor(address candidate, uint256 amount) internal {
        _state.candidates[candidate].reject = _state.candidates[candidate].reject - amount;
    }

    function placeLock(address account, address candidate) internal {
        uint256 currentLock = _state.accounts[account].lockedUntil;
        uint256 newLock = startFor(candidate) + (periodFor(candidate));
        if (newLock > currentLock) {
            _state.accounts[account].lockedUntil = newLock;
        }
    }

    function initialized(address candidate) internal {
        _state.candidates[candidate].initialized = true;
    }
}
