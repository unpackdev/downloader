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
import "./Constants.sol";
import "./ITickets.sol";

contract Getters is State {
    using Decimal for Decimal.D256;

    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * ERC20 Interface
     */

    function name() public view returns (string memory) {
        return "Lucky8 Staked Tokens";
    }

    function symbol() public view returns (string memory) {
        return "s888";
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

    function token() public view returns (IToken) {
        return _state.provider.token;
    }

    function tickets() public view returns (ITickets) {
        return _state.provider.tickets;
    }

    function usdc() public view returns (IToken) {
        return IToken(getUsdc());
    }

    function totalBonded() public view returns (uint256) {
        return _state.balance.bonded;
    }

    function totalStaged() public view returns (uint256) {
        return _state.balance.staged;
    }

    function totalUserTokenClaims() public view returns (uint256) {
        return totalBonded() + totalStaged();
    }

    function userUSDCClaims() public view returns (uint256) {
        return _state.balance.userUSDCClaims;
    }

    function totalTokenRewards() public view returns (uint256) {
        return token().balanceOf(address(this)) - totalUserTokenClaims();
    }

    function thisEpochsTokenRewards() public view returns (uint256) {
        return Decimal.D256(totalTokenRewards()).mul(getDistributionPerEpoch()).value;
    }

    function totalPrizePool() public view returns (uint256) {
        uint pool = usdc().balanceOf(address(this)) - userUSDCClaims();
        return pool / getWinningTickets() * getWinningTickets();
    }

    function thisEpochsPrizePool() public view returns (uint256) {
        return Decimal.D256(totalPrizePool()).mul(getDistributionPerEpoch()).value;
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
        return (totalBonded() * balanceOf(account)) / (totalSupply);
    }

    function statusOf(address account) public view returns (Account.Status) {
        if (_state.accounts[account].lockedUntil > epoch()) {
            return Account.Status.Locked;
        }

        return epoch() >= _state.accounts[account].fluidUntil ? Account.Status.Frozen : Account.Status.Fluid;
    }

    function fluidUntil(address account) public view returns (uint) {
        return _state.accounts[account].fluidUntil;
    }

    /**
     * Epoch
     */

    function epoch() public view returns (uint256) {
        return _state.epoch.current;
    }

    function epochTime() public view returns (uint256) {
        EpochStrategy memory strategy = getCurrentEpochStrategy();
        if (blockTimestamp() < strategy.start) {
            return 0;
        }

        return ((blockTimestamp() - strategy.start) / strategy.period) + strategy.offset;
    }

    // Overridable for testing
    function blockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    function totalBondedAt(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].bonded;
    }

    /**
     * Lottery
     */

    function winnersAt(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].winningTickets.length;
    }

    function winningTickets(uint256 epoch) public view returns (uint256[] memory) {
        return _state.epochs[epoch].winningTickets;
    }

    function chainLinkRequestId(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].chainLinkRequestId;
    }

    function prizePerTicket(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].prizePerTicket;
    }

    function chainlinkRequestId(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].prizePerTicket;
    }

    function userTicketRange(address user, uint256 epoch) public view returns (uint start, uint end) {
        return (
            _state.epochs[epoch].userTicketRange[user].start,
            _state.epochs[epoch].userTicketRange[user].end
        );
    }

    function userPrizeClaimed(uint256 epoch, address user) public view returns (bool) {
        return _state.epochs[epoch].userPrizeClaimed[user];
    }

    function epochForRequestId(uint256 requestId) public view returns (uint) {
        return _state.chainlinkRequestIds[requestId];
    }

    function drawExecuted(uint256 epoch) public view returns (bool) {
        return _state.epochs[epoch].drawExecuted;
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
        return approveFor(candidate) + (rejectFor(candidate));
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
