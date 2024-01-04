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
import "./Setters.sol";
import "./Permission.sol";
import "./Upgradeable.sol";
import "./Require.sol";
import "./Decimal.sol";
import "./Constants.sol";
import "./IPoolGov.sol";

contract Govern is Setters, Permission, Upgradeable {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant FILE = "Govern";

    event Proposal(address indexed candidate, address indexed account, uint256 indexed start, uint256 period);
    event Vote(address indexed account, address indexed candidate, Candidate.Vote vote, uint256 bonded);
    event Commit(address indexed account, address indexed candidate);

    // QSD #6
    modifier onlyPostBootstrapping() {
        Require.that(!bootstrappingAt(epoch().sub(1)), FILE, "No govern during bootstrapping");
        _;
    }

    function vote(address candidate, Candidate.Vote vote)
        external
        onlyPostBootstrapping
    {
        uint256 govStaked = IPoolGov(poolGov()).balanceOfBonded(msg.sender);

        Require.that(govStaked > 0, FILE, "Must have stake");

        if (!isNominated(candidate)) {
            Require.that(canPropose(msg.sender), FILE, "Not enough stake to propose");

            createCandidate(candidate, Constants.getGovernancePeriod());
            emit Proposal(candidate, msg.sender, epoch(), Constants.getGovernancePeriod());
        }

        uint256 candidateEndEpoch = startFor(candidate).add(periodFor(candidate));
        
        Require.that(epoch() < candidateEndEpoch, FILE, "Ended");

        Candidate.Vote recordedVote = recordedVote(msg.sender, candidate);
        if (vote == recordedVote) {
            return;
        }

        if (recordedVote == Candidate.Vote.REJECT) {
            decrementRejectFor(candidate, govStaked, "Govern: Insufficient reject");
        }
        if (recordedVote == Candidate.Vote.APPROVE) {
            decrementApproveFor(candidate, govStaked, "Govern: Insufficient approve");
        }
        if (vote == Candidate.Vote.REJECT) {
            incrementRejectFor(candidate, govStaked);
        }
        if (vote == Candidate.Vote.APPROVE) {
            incrementApproveFor(candidate, govStaked);
        }

        recordVote(msg.sender, candidate, vote);
        IPoolGov(poolGov()).placeLock(msg.sender, candidateEndEpoch);

        emit Vote(msg.sender, candidate, vote, govStaked);
    }

    function commit(address candidate) external onlyPostBootstrapping {
        Require.that(isNominated(candidate), FILE, "Not nominated");

        uint256 endsAfter = startFor(candidate).add(periodFor(candidate)).sub(1);

        Require.that(epoch() > endsAfter, FILE, "Not ended");

        Require.that(epoch() <= endsAfter.add(1).add(Constants.getGovernanceExpiration()), FILE, "Expired");

        Require.that(
            Decimal.ratio(votesFor(candidate), totalBondedAt(endsAfter)).greaterThan(Constants.getGovernanceQuorum()),
            FILE,
            "Must have quorom"
        );

        Require.that(approveFor(candidate) > rejectFor(candidate), FILE, "Not approved");

        upgradeTo(candidate);

        emit Commit(msg.sender, candidate);
    }

    function emergencyCommit(address candidate) external onlyPostBootstrapping {
        Require.that(isNominated(candidate), FILE, "Not nominated");

        Require.that(epochTime() > epoch().add(Constants.getGovernanceEmergencyDelay()), FILE, "Epoch synced");

        Require.that(
            Decimal.ratio(approveFor(candidate), IPoolGov(poolGov()).totalBonded()).greaterThan(Constants.getGovernanceSuperMajority()),
            FILE,
            "Must have super majority"
        );

        Require.that(approveFor(candidate) > rejectFor(candidate), FILE, "Not approved");

        upgradeTo(candidate);

        emit Commit(msg.sender, candidate);
    }

    function canPropose(address account) private view returns (bool) {
        uint256 govStaked = IPoolGov(poolGov()).balanceOfBonded(msg.sender);
        uint256 totalGovStaked = IPoolGov(poolGov()).totalBonded();

        if (totalGovStaked == 0) {
            return false;
        }

        Decimal.D256 memory stake = Decimal.ratio(govStaked, totalGovStaked);
        return stake.greaterThan(Constants.getGovernanceProposalThreshold());
    }
}
