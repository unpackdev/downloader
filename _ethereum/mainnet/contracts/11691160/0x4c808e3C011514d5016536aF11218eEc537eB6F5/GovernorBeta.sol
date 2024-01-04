// File: contracts/utils/EvmUtil.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.13;

library EvmUtil {

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

}

// File: contracts/governance/dmg/IDMGToken.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.13;

interface IDMGToken {

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint64 fromBlock;
        uint128 votes;
    }

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    // *************************
    // ***** Functions
    // *************************

    function getPriorVotes(address account, uint blockNumber) external view returns (uint128);

    function getCurrentVotes(address account) external view returns (uint128);

    function delegates(address delegator) external view returns (address);

    function burn(uint amount) external returns (bool);

    function approveBySig(
        address spender,
        uint rawAmount,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

}

// File: contracts/governance/governors/ITimelockInterface.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 *
 * Copyright 2020 Compound Labs, Inc.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
 * following conditions are met:
 * 1.   Redistributions of source code must retain the above copyright notice, this list of conditions and the following
 *      disclaimer.
 * 2.   Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
 *      following disclaimer in the documentation and/or other materials provided with the distribution.
 * 3.   Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote
 *      products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;

interface ITimelockInterface {

    function delay() external view returns (uint);

    function GRACE_PERIOD() external view returns (uint);

    function acceptAdmin() external;

    function queuedTransactions(bytes32 hash) external view returns (bool);

    function queueTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) external;

    function executeTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) external payable returns (bytes memory);
}

// File: contracts/governance/governors/GovernorAlphaData.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 *
 * Copyright 2020 Compound Labs, Inc.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
 * following conditions are met:
 * 1.   Redistributions of source code must retain the above copyright notice, this list of conditions and the following
 *      disclaimer.
 * 2.   Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
 *      following disclaimer in the documentation and/or other materials provided with the distribution.
 * 3.   Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote
 *      products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

pragma solidity ^0.5.13;

contract GovernorAlphaData {

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string title, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint id;

        /// @notice Creator of the proposal
        address proposer;

        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;

        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;

        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;

        /// @notice The ordered list of function signatures to be called
        string[] signatures;

        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;

        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint endBlock;

        /// @notice Current number of votes in favor of this proposal
        uint forVotes;

        /// @notice Current number of votes in opposition to this proposal
        uint againstVotes;

        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;

        /// @notice Flag marking whether the proposal has been executed
        bool executed;

        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Whether or not the voter supports the proposal
        bool support;

        /// @notice The number of votes the voter had, which were cast
        uint128 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

}

// File: contracts/governance/governors/GovernorAlpha.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 *
 * Copyright 2020 Compound Labs, Inc.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
 * following conditions are met:
 * 1.   Redistributions of source code must retain the above copyright notice, this list of conditions and the following
 *      disclaimer.
 * 2.   Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
 *      following disclaimer in the documentation and/or other materials provided with the distribution.
 * 3.   Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote
 *      products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

pragma solidity ^0.5.13;





/**
 * This contract is mainly based on Compound's Governor Alpha contract. Attribution to Compound Labs as the original
 * creator of the contract can be seen above.
 *
 * Changes made to the original contract include slight name changes, adding a `title` field to the Proposal struct,
 * and minor data type adjustments to account for DMG using more bits for storage (128 instead of 96).
 */
contract GovernorAlpha is GovernorAlphaData {
    /// @notice The name of this contract
    string public constant name = "DMM Governor Alpha";

    /// @notice The address of the DMM Protocol Timelock
    ITimelockInterface public timelock;

    /// @notice The address of the DMG governance token
    IDMGToken public dmg;

    /// @notice The address of the Governor Guardian
    address public guardian;

    /// @notice The total number of proposals
    uint public proposalCount;

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    uint public quorumVotes;

    /// @notice The minimum number of votes needed to create a proposal
    uint public proposalThreshold;

    /// @notice The duration of voting on a proposal, in blocks
    uint public votingPeriod;

    /// @notice The official record of all proposals ever proposed
    mapping(uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint) public latestProposalIds;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    constructor(
        address dmg_,
        address guardian_
    ) public {
        dmg = IDMGToken(dmg_);
        guardian = guardian_;
        quorumVotes = 500_000e18;
        proposalThreshold = 100_000e18;

        // ~3 days in blocks (assuming 15s blocks)
        votingPeriod = 17280;
    }

    function initializeTimelock(
        address timelock_
    ) public {
        require(
            msg.sender == guardian,
            "GovernorAlpha::setTimelock: Caller must be guardian"
        );
        require(
            address(timelock) == address(0x0),
            "GovernorAlpha::setTimelock: timelock must not be initialized yet"
        );

        timelock = ITimelockInterface(timelock_);
    }

    function setQuorumVotes(
        uint quorumVotes_
    ) public {
        require(
            msg.sender == address(timelock),
            "GovernorAlpha::setQuorumVotes: invalid sender"
        );
        quorumVotes = quorumVotes_;
    }

    function setProposalThreshold(
        uint proposalThreshold_
    ) public {
        require(
            msg.sender == address(timelock),
            "GovernorAlpha::setProposalThreshold: invalid sender"
        );
        proposalThreshold = proposalThreshold_;
    }

    /**
     * @return  The maximum number of actions that can be included in a proposal
     */
    function proposalMaxOperations() public pure returns (uint) {
        // 10 actions
        return 10;
    }

    /**
     * @return  The delay (represented as number of blocks) before voting on a proposal may take place, once proposed
     */
    function votingDelay() public pure returns (uint) {
        // 1 block
        return 1;
    }

    function setVotingPeriod(
        uint votingPeriod_
    ) public {
        require(
            msg.sender == address(timelock),
            "GovernorAlpha::setVotingPeriod: invalid sender"
        );
        require(
            votingPeriod_ >= 5760,
            "GovernorAlpha::setVotingPeriod: new voting period must exceed minimum"
        );

        // The minimum number of blocks for a vote is ~1 day (assuming 15s blocks)
        votingPeriod = votingPeriod_;
    }

    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory title,
        string memory description
    ) public returns (uint) {
        require(
            msg.sender == guardian || _getVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold,
            "GovernorAlpha::propose: proposer votes below proposal threshold"
        );
        require(
            targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length,
            "GovernorAlpha::propose: proposal function information arity mismatch"
        );
        require(
            targets.length != 0,
            "GovernorAlpha::propose: must provide actions"
        );
        require(
            targets.length <= proposalMaxOperations(),
            "GovernorAlpha::propose: too many actions"
        );

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(
                proposersLatestProposalState != ProposalState.Active,
                "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal"
            );
            require(
                proposersLatestProposalState != ProposalState.Pending,
                "GovernorAlpha::propose: one live proposal per proposer, found an already pending proposal"
            );
        }

        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod);

        proposalCount++;
        Proposal memory newProposal = Proposal({
        id : proposalCount,
        proposer : msg.sender,
        eta : 0,
        targets : targets,
        values : values,
        signatures : signatures,
        calldatas : calldatas,
        startBlock : startBlock,
        endBlock : endBlock,
        forVotes : 0,
        againstVotes : 0,
        canceled : false,
        executed : false
        });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, title, description);
        return newProposal.id;
    }

    function queue(
        uint proposalId
    ) public {
        require(
            state(proposalId) == ProposalState.Succeeded,
            "GovernorAlpha::queue: proposal can only be queued if it is succeeded"
        );

        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function _queueOrRevert(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) internal {
        require(
            !timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))),
            "GovernorAlpha::_queueOrRevert: proposal action already queued at eta"
        );

        timelock.queueTransaction(target, value, signature, data, eta);
    }

    function execute(
        uint proposalId
    ) public payable {
        require(
            state(proposalId) == ProposalState.Queued,
            "GovernorAlpha::execute: proposal can only be executed if it is queued"
        );

        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction.value(proposal.values[i])(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(
        uint proposalId
    ) public {
        ProposalState state = state(proposalId);
        require(
            state != ProposalState.Executed,
            "GovernorAlpha::cancel: cannot cancel executed proposal"
        );

        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == proposal.proposer || _getVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold,
            "GovernorAlpha::cancel: proposer above threshold"
        );

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    function getActions(
        uint proposalId
    ) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(
        uint proposalId
    ) public view returns (ProposalState) {
        require(
            proposalCount >= proposalId && proposalId > 0,
            "GovernorAlpha::state: invalid proposal id"
        );

        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(
        uint proposalId,
        bool support
    )
    public returns (uint128) {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(
        uint proposalId,
        bool support,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    public returns (uint128) {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "GovernorAlpha::castVoteBySig: invalid signature"
        );
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(
        address voter,
        uint proposalId,
        bool support
    ) internal returns (uint128) {
        require(
            state(proposalId) == ProposalState.Active,
            "GovernorAlpha::_castVote: voting is closed"
        );

        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(
            receipt.hasVoted == false,
            "GovernorAlpha::_castVote: voter already voted"
        );

        uint128 votes = _getVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);

        return votes;
    }

    function __acceptAdmin() public {
        require(
            msg.sender == guardian || msg.sender == address(timelock),
            "GovernorAlpha::__acceptAdmin: sender must be gov guardian or timelock"
        );

        timelock.acceptAdmin();
    }

    function __abdicate() public {
        require(
            msg.sender == guardian,
            "GovernorAlpha::__abdicate: sender must be gov guardian"
        );

        guardian = address(0);
    }

    function __queueSetTimelockPendingAdmin(
        address newPendingAdmin,
        uint eta
    ) public {
        require(
            msg.sender == guardian,
            "GovernorAlpha::__queueSetTimelockPendingAdmin: sender must be gov guardian"
        );

        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function __executeSetTimelockPendingAdmin(
        address newPendingAdmin,
        uint eta
    ) public {
        require(
            msg.sender == guardian,
            "GovernorAlpha::__executeSetTimelockPendingAdmin: sender must be gov guardian"
        );

        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function _getVotes(
        address user,
        uint blockNumber
    ) internal view returns (uint128) {
        return dmg.getPriorVotes(user, blockNumber);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "GovernorAlpha::add256: ADDITION_OVERFLOW");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "GovernorAlpha::add256: SUBTRACTION_UNDERFLOW");
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly {chainId := chainid()}
        return chainId;
    }
}

// File: contracts/governance/dmg/SafeBitMath.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.0;

library SafeBitMath {

    function safe64(uint n, string memory errorMessage) internal pure returns (uint64) {
        require(n < 2 ** 64, errorMessage);
        return uint64(n);
    }

    function safe128(uint n, string memory errorMessage) internal pure returns (uint128) {
        require(n < 2 ** 128, errorMessage);
        return uint128(n);
    }

    function add128(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function add128(uint128 a, uint128 b) internal pure returns (uint128) {
        return add128(a, b, "");
    }

    function sub128(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function sub128(uint128 a, uint128 b) internal pure returns (uint128) {
        return sub128(a, b, "");
    }

}

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: contracts/protocol/interfaces/IOwnableOrGuardian.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.0;


/**
 * NOTE:    THE STATE VARIABLES IN THIS CONTRACT CANNOT CHANGE NAME OR POSITION BECAUSE THIS CONTRACT IS USED IN
 *          UPGRADEABLE CONTRACTS.
 */
contract IOwnableOrGuardian is Initializable {

    // *************************
    // ***** Events
    // *************************

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event GuardianTransferred(address indexed previousGuardian, address indexed newGuardian);

    // *************************
    // ***** Modifiers
    // *************************

    modifier onlyOwnerOrGuardian {
        require(
            msg.sender == _owner || msg.sender == _guardian,
            "OwnableOrGuardian: UNAUTHORIZED_OWNER_OR_GUARDIAN"
        );
        _;
    }

    modifier onlyOwner {
        require(
            msg.sender == _owner,
            "OwnableOrGuardian: UNAUTHORIZED"
        );
        _;
    }
    // *********************************************
    // ***** State Variables DO NOT CHANGE OR MOVE
    // *********************************************

    // ******************************
    // ***** DO NOT CHANGE OR MOVE
    // ******************************
    address internal _owner;
    address internal _guardian;
    // ******************************
    // ***** DO NOT CHANGE OR MOVE
    // ******************************

    // ******************************
    // ***** Misc Functions
    // ******************************

    function owner() external view returns (address) {
        return _owner;
    }

    function guardian() external view returns (address) {
        return _guardian;
    }

    // ******************************
    // ***** Admin Functions
    // ******************************

    function initialize(
        address __owner,
        address __guardian
    )
    public
    initializer {
        _transferOwnership(__owner);
        _transferGuardian(__guardian);
    }

    function transferOwnership(
        address __owner
    )
    public
    onlyOwner {
        require(
            __owner != address(0),
            "OwnableOrGuardian::transferOwnership: INVALID_OWNER"
        );
        _transferOwnership(__owner);
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function transferGuardian(
        address __guardian
    )
    public
    onlyOwner {
        require(
            __guardian != address(0),
            "OwnableOrGuardian::transferGuardian: INVALID_OWNER"
        );
        _transferGuardian(__guardian);
    }

    function renounceGuardian() public onlyOwnerOrGuardian {
        _transferGuardian(address(0));
    }

    // ******************************
    // ***** Internal Functions
    // ******************************

    function _transferOwnership(
        address __owner
    )
    internal {
        address previousOwner = _owner;
        _owner = __owner;
        emit OwnershipTransferred(previousOwner, __owner);
    }

    function _transferGuardian(
        address __guardian
    )
    internal {
        address previousGuardian = _guardian;
        _guardian = __guardian;
        emit GuardianTransferred(previousGuardian, __guardian);
    }

}

// File: contracts/external/asset_introducers/AssetIntroducerData.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.0;




contract AssetIntroducerData is Initializable, IOwnableOrGuardian {

    // *************************
    // ***** Constants
    // *************************

    // *************************
    // ***** V1 State Variables
    // *************************

    /// For preventing reentrancy attacks
    uint64 internal _guardCounter;

    AssetIntroducerStateV1 internal _assetIntroducerStateV1;

    ERC721StateV1 internal _erc721StateV1;

    VoteStateV1 internal _voteStateV1;

    // *************************
    // ***** Data Structures
    // *************************

    enum AssetIntroducerType {
        PRINCIPAL, AFFILIATE
    }

    struct AssetIntroducerStateV1 {
        /// The timestamp at which this contract was initialized
        uint64 initTimestamp;

        /// True if the DMM Foundation purchased its token for the bootstrapped pool, false otherwise.
        bool isDmmFoundationSetup;

        /// Total amount of DMG locked in this contract
        uint128 totalDmgLocked;

        /// For calculating the results of off-chain signature requests
        bytes32 domainSeparator;

        /// Address of the DMG token
        address dmg;

        /// Address of the DMM Controller
        address dmmController;

        /// Address of the DMM token valuator, which gets the USD value of a token
        address underlyingTokenValuator;

        /// Address of the implementation for the discount
        address assetIntroducerDiscount;

        /// Address of the implementation for the staking purchaser contract. Used to buy NFTs at a steep discount by
        /// staking mTokens.
        address stakingPurchaser;

        /// Mapping from NFT ID to the asset introducer struct.
        mapping(uint => AssetIntroducer) idToAssetIntroducer;

        /// Mapping from country code to asset introducer type to token IDs
        mapping(bytes3 => mapping(uint8 => uint[])) countryCodeToAssetIntroducerTypeToTokenIdsMap;

        /// A mapping from the country code to asset introducer type to the cost needed to buy one. The cost is represented
        /// in USD (with 18 decimals) and is purchased using DMG, so a conversion is needed using Chainlink.
        mapping(bytes3 => mapping(uint8 => uint96)) countryCodeToAssetIntroducerTypeToPriceUsd;

        /// The dollar amount that has actually been deployed by the asset introducer
        mapping(uint => mapping(address => uint)) tokenIdToUnderlyingTokenToWithdrawnAmount;

        /// Mapping for the count of each user's off-chain signed messages. 0-indexed.
        mapping(address => uint) ownerToNonceMap;
    }

    struct ERC721StateV1 {
        /// Total number of NFTs created
        uint64 totalSupply;

        /// The proxy address created by OpenSea, which is used to enable a smoother trading experience
        address openSeaProxyRegistry;

        /// The last token ID in the linked list.
        uint lastTokenId;

        /// The base URI for getting NFT information by token ID.
        string baseURI;

        /// Mapping of all token IDs. Works as a linked list such that previous key --> next value. The 0th key in the
        /// list is LINKED_LIST_GUARD.
        mapping(uint => uint) allTokens;

        /// Mapping from NFT ID to owner address.
        mapping(uint256 => address) idToOwnerMap;

        /// Mapping from NFT ID to approved address.
        mapping(uint256 => address) idToSpenderMap;

        /// Mapping from owner to an operator that can spend all of owner's NFTs.
        mapping(address => mapping(address => bool)) ownerToOperatorToIsApprovedMap;

        /// Mapping from owner address to all owned token IDs. Works as a linked list such that previous key --> next value.
        /// The 0th key in the list is LINKED_LIST_GUARD.
        mapping(address => mapping(uint => uint)) ownerToTokenIds;

        /// Mapping from owner address to a count of all owned NFTs.
        mapping(address => uint32) ownerToTokenCount;

        /// Mapping from an interface to whether or not it's supported.
        mapping(bytes4 => bool) interfaceIdToIsSupportedMap;
    }

    /// Used for storing information about voting
    struct VoteStateV1 {
        /// Taken from the DMG token implementation
        mapping(address => mapping(uint64 => Checkpoint)) ownerToCheckpointIndexToCheckpointMap;
        /// Taken from the DMG token implementation
        mapping(address => uint64) ownerToCheckpointCountMap;
    }

    /// Tightly-packed, this data structure is 2 slots; 64 bytes
    struct AssetIntroducer {
        bytes3 countryCode;
        AssetIntroducerType introducerType;
        /// True if the asset introducer has been purchased yet, false if it hasn't and is thus
        bool isOnSecondaryMarket;
        /// True if the asset introducer can withdraw tokens from mToken deposits, false if it cannot yet. This value
        /// must only be changed to `true` via governance vote
        bool isAllowedToWithdrawFunds;
        /// 1-based index at which the asset introducer was created. Used for optics
        uint16 serialNumber;
        uint96 dmgLocked;
        /// How much this asset introducer can manage
        uint96 dollarAmountToManage;
        uint tokenId;
    }

    /// Used for tracking delegation and number of votes each user has at a given block height.
    struct Checkpoint {
        uint64 fromBlock;
        uint128 votes;
    }

    /// Used to prevent the "stack too deep" error and make code more readable
    struct DmgApprovalStruct {
        address spender;
        uint rawAmount;
        uint nonce;
        uint expiry;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct DiscountStruct {
        uint64 initTimestamp;
    }

    // *************************
    // ***** Modifiers
    // *************************

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;

        _;

        require(
            localCounter == _guardCounter,
            "AssetIntroducerData: REENTRANCY"
        );
    }

    /// Enforces that an NFT has NOT been sold to a user yet
    modifier requireIsPrimaryMarketNft(uint __tokenId) {
        require(
            !_assetIntroducerStateV1.idToAssetIntroducer[__tokenId].isOnSecondaryMarket,
            "AssetIntroducerData: IS_SECONDARY_MARKET"
        );

        _;
    }

    /// Enforces that an NFT has been sold to a user
    modifier requireIsSecondaryMarketNft(uint __tokenId) {
        require(
            _assetIntroducerStateV1.idToAssetIntroducer[__tokenId].isOnSecondaryMarket,
            "AssetIntroducerData: IS_PRIMARY_MARKET"
        );

        _;
    }

    modifier requireIsValidNft(uint __tokenId) {
        require(
            _erc721StateV1.idToOwnerMap[__tokenId] != address(0),
            "AssetIntroducerData: INVALID_NFT"
        );

        _;
    }

    modifier requireIsNftOwner(uint __tokenId) {
        require(
            _erc721StateV1.idToOwnerMap[__tokenId] == msg.sender,
            "AssetIntroducerData: INVALID_NFT_OWNER"
        );

        _;
    }

    modifier requireCanWithdrawFunds(uint __tokenId) {
        require(
            _assetIntroducerStateV1.idToAssetIntroducer[__tokenId].isAllowedToWithdrawFunds,
            "AssetIntroducerData: NFT_NOT_ACTIVATED"
        );

        _;
    }

    modifier requireIsStakingPurchaser() {
        require(
            _assetIntroducerStateV1.stakingPurchaser != address(0),
            "AssetIntroducerData: STAKING_PURCHASER_NOT_SETUP"
        );

        require(
            _assetIntroducerStateV1.stakingPurchaser == msg.sender,
            "AssetIntroducerData: INVALID_SENDER_FOR_STAKING"
        );
        _;
    }

}

// File: contracts/external/asset_introducers/v1/IAssetIntroducerV1.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.0;


interface IAssetIntroducerV1 {

    // *************************
    // ***** Events
    // *************************

    event AssetIntroducerBought(uint indexed tokenId, address indexed buyer, address indexed recipient, uint dmgAmount);
    event AssetIntroducerActivationChanged(uint indexed tokenId, bool isActivated);
    event AssetIntroducerCreated(uint indexed tokenId, string countryCode, AssetIntroducerData.AssetIntroducerType introducerType, uint serialNumber);
    event AssetIntroducerDiscountChanged(address indexed oldAssetIntroducerDiscount, address indexed newAssetIntroducerDiscount);
    event AssetIntroducerDollarAmountToManageChange(uint indexed tokenId, uint oldDollarAmountToManage, uint newDollarAmountToManage);
    event AssetIntroducerPriceChanged(string indexed countryCode, AssetIntroducerData.AssetIntroducerType indexed introducerType, uint oldPriceUsd, uint newPriceUsd);
    event BaseURIChanged(string newBaseURI);
    event CapitalDeposited(uint indexed tokenId, address indexed token, uint amount);
    event CapitalWithdrawn(uint indexed tokenId, address indexed token, uint amount);
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
    event InterestPaid(uint indexed tokenId, address indexed token, uint amount);
    event SignatureValidated(address indexed signer, uint nonce);
    event StakingPurchaserChanged(address indexed oldStakingPurchaser, address indexed newStakingPurchaser);

    // *************************
    // ***** Admin Functions
    // *************************

    function createAssetIntroducersForPrimaryMarket(
        string[] calldata countryCode,
        AssetIntroducerData.AssetIntroducerType[] calldata introducerType
    ) external returns (uint[] memory);

    function setDollarAmountToManageByTokenId(
        uint tokenId,
        uint dollarAmountToManage
    ) external;

    function setDollarAmountToManageByCountryCodeAndIntroducerType(
        string calldata countryCode,
        AssetIntroducerData.AssetIntroducerType introducerType,
        uint dollarAmountToManage
    ) external;

    function setAssetIntroducerDiscount(
        address assetIntroducerDiscount
    ) external;

    function setAssetIntroducerPrice(
        string calldata countryCode,
        AssetIntroducerData.AssetIntroducerType introducerType,
        uint priceUsd
    ) external;

    function activateAssetIntroducerByTokenId(
        uint tokenId
    ) external;

    function setStakingPurchaser(
        address stakingPurchaser
    ) external;

    // *************************
    // ***** Misc Functions
    // *************************

    /**
     * @return  The timestamp at which this contract was created
     */
    function initTimestamp() external view returns (uint64);

    function stakingPurchaser() external view returns (address);

    function openSeaProxyRegistry() external view returns (address);

    /**
     * @return  The domain separator used in off-chain signatures. See EIP 712 for more:
     *          https://eips.ethereum.org/EIPS/eip-712
     */
    function domainSeparator() external view returns (bytes32);

    /**
     * @return  The address of the DMG token
     */
    function dmg() external view returns (address);

    function dmmController() external view returns (address);

    function underlyingTokenValuator() external view returns (address);

    function assetIntroducerDiscount() external view returns (address);

    /**
     * @return  The discount applied to the price of the asset introducer for being an early purchaser. Represented as
     *          a number with 18 decimals, such that 0.1 * 1e18 == 10%
     */
    function getAssetIntroducerDiscount() external view returns (uint);

    /**
     * @return  The price of the asset introducer, represented in USD
     */
    function getAssetIntroducerPriceUsdByTokenId(
        uint tokenId
    ) external view returns (uint);

    /**
     * @return  The price of the asset introducer, represented in DMG. DMG is the needed currency to purchase an asset
     *          introducer NFT.
     */
    function getAssetIntroducerPriceDmgByTokenId(
        uint tokenId
    ) external view returns (uint);

    function getAssetIntroducerPriceUsdByCountryCodeAndIntroducerType(
        string calldata countryCode,
        AssetIntroducerData.AssetIntroducerType introducerType
    )
    external view returns (uint);

    function getAssetIntroducerPriceDmgByCountryCodeAndIntroducerType(
        string calldata countryCode,
        AssetIntroducerData.AssetIntroducerType introducerType
    )
    external view returns (uint);

    /**
     * @return  The total amount of DMG locked in the asset introducer reserves
     */
    function getTotalDmgLocked() external view returns (uint);

    /**
     * @return  The amount that this asset introducer can manager, represented in wei format (a number with 18
     *          decimals). Meaning, 10,000.25 * 1e18 == $10,000.25
     */
    function getDollarAmountToManageByTokenId(
        uint tokenId
    ) external view returns (uint);

    /**
     * @return  The amount of DMG that this asset introducer has locked in order to maintain a valid status as an asset
     *          introducer.
     */
    function getDmgLockedByTokenId(
        uint tokenId
    ) external view returns (uint);

    function getAssetIntroducerByTokenId(
        uint tokenId
    ) external view returns (AssetIntroducerData.AssetIntroducer memory);

    function getAssetIntroducersByCountryCode(
        string calldata countryCode
    ) external view returns (AssetIntroducerData.AssetIntroducer[] memory);

    function getAllAssetIntroducers() external view returns (AssetIntroducerData.AssetIntroducer[] memory);

    function getPrimaryMarketAssetIntroducers() external view returns (AssetIntroducerData.AssetIntroducer[] memory);

    function getSecondaryMarketAssetIntroducers() external view returns (AssetIntroducerData.AssetIntroducer[] memory);

    // *************************
    // ***** User Functions
    // *************************

    function getNonceByUser(
        address user
    ) external view returns (uint);

    function getNextAssetIntroducerTokenId(
        string calldata __countryCode,
        AssetIntroducerData.AssetIntroducerType __introducerType
    ) external view returns (uint);

    /**
     * Buys the slot for the appropriate amount of DMG, by attempting to transfer the DMG from `msg.sender` to this
     * contract
     */
    function buyAssetIntroducerSlot(
        uint tokenId
    ) external returns (bool);

    /**
     * Buys the slot for the appropriate amount of DMG, by attempting to transfer the DMG from `msg.sender` to this
     * contract. The additional discount is added to the existing one
     */
    function buyAssetIntroducerSlotViaStaking(
        uint tokenId,
        uint additionalDiscount
    ) external returns (bool);

    function nonceOf(
        address user
    ) external view returns (uint);

    function buyAssetIntroducerSlotBySig(
        uint tokenId,
        address recipient,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function buyAssetIntroducerSlotBySigWithDmgPermit(
        uint __tokenId,
        address __recipient,
        uint __nonce,
        uint __expiry,
        uint8 __v,
        bytes32 __r,
        bytes32 __s,
        AssetIntroducerData.DmgApprovalStruct calldata dmgApprovalStruct
    ) external returns (bool);

    function getPriorVotes(
        address user,
        uint blockNumber
    ) external view returns (uint128);

    function getCurrentVotes(
        address user
    ) external view returns (uint);

    function getDmgLockedByUser(
        address user
    ) external view returns (uint);

    /**
     * @return  The amount of capital that has been withdrawn by this asset introducer, denominated in USD with 18
     *          decimals
     */
    function getDeployedCapitalUsdByTokenId(
        uint tokenId
    ) external view returns (uint);

    function getWithdrawnAmountByTokenIdAndUnderlyingToken(
        uint tokenId,
        address underlyingToken
    ) external view returns (uint);

    /**
     * @dev Deactivates the specified asset introducer from being able to withdraw funds. Doing so enables it to
     *      be transferred. NOTE: NFTs can only be deactivated once all deployed capital is returned.
     */
    function deactivateAssetIntroducerByTokenId(
        uint tokenId
    ) external;

    function withdrawCapitalByTokenIdAndToken(
        uint tokenId,
        address token,
        uint amount
    ) external;

    function depositCapitalByTokenIdAndToken(
        uint tokenId,
        address token,
        uint amount
    ) external;

    function payInterestByTokenIdAndToken(
        uint tokenId,
        address token,
        uint amount
    ) external;

    // *************************
    // ***** Other Functions
    // *************************

    /**
     * @dev Used by the DMMF to buy its token and initialize it based upon its usage of the protocol prior to the NFT
     *      system having been created. We are passing through the USDC token specifically, because it was drawn down
     *      by 300,000 early in the system's maturity to run a full cycle of the system and do a small allocation to
     *      the bootstrapped asset pool.
     */
    function buyDmmFoundationToken(
        uint tokenId,
        address usdcToken
    ) external returns (bool);

    function isDmmFoundationSetup() external view returns (bool);

}

// File: contracts/governance/governors/GovernorBeta.sol

/*
 * Copyright 2020 DMM Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


pragma solidity ^0.5.13;




contract GovernorBeta is GovernorAlpha {

    using SafeBitMath for uint128;

    event LocalOperatorSet(address indexed voter, address indexed operator, bool isTrusted);
    event GlobalOperatorSet(address indexed operator, bool isTrusted);

    modifier onlyTrustedOperator(address voter) {
        require(
            msg.sender == voter ||
            _globalOperatorToIsSupportedMap[msg.sender] ||
            _voterToLocalOperatorToIsSupportedMap[voter][msg.sender],
            "GovernorBeta: UNAUTHORIZED_OPERATOR"
        );

        _;
    }

    IAssetIntroducerV1 public assetIntroducerProxy;
    mapping(address => mapping(address => bool)) internal _voterToLocalOperatorToIsSupportedMap;
    mapping(address => bool) internal _globalOperatorToIsSupportedMap;

    constructor(
        address __assetIntroducerProxy,
        address __dmg,
        address __guardian
    ) public GovernorAlpha(__dmg, __guardian) {
        assetIntroducerProxy = IAssetIntroducerV1(__assetIntroducerProxy);
    }

    // *************************
    // ***** Admin Functions
    // *************************

    function setGlobalOperator(
        address __operator,
        bool __isTrusted
    ) public {
        require(
            address(timelock) == msg.sender,
            "GovernorBeta::setGlobalOperator: UNAUTHORIZED"
        );

        _globalOperatorToIsSupportedMap[__operator] = __isTrusted;
        emit GlobalOperatorSet(__operator, __isTrusted);
    }

    function __acceptAdmin() public {
        require(
            msg.sender == address(timelock),
            "GovernorBeta::__acceptAdmin: sender must be timelock"
        );

        timelock.acceptAdmin();
    }

    function __queueSetTimelockPendingAdmin(
        address,
        uint
    ) public {
        // The equivalent of this function should be called via governance proposal execution
        revert("GovernorBeta::__queueSetTimelockPendingAdmin: NOT_USED");
    }

    function __executeSetTimelockPendingAdmin(
        address,
        uint
    ) public {
        // The equivalent of this function should be called via governance proposal execution
        revert("GovernorBeta::__executeSetTimelockPendingAdmin: NOT_USED");
    }

    // *************************
    // ***** User Functions
    // *************************

    function setLocalOperator(
        address __operator,
        bool __isTrusted
    ) public {
        _voterToLocalOperatorToIsSupportedMap[msg.sender][__operator] = __isTrusted;
        emit LocalOperatorSet(msg.sender, __operator, __isTrusted);
    }

    /**
     * Can be called by a global operator or local operator on behalf of `voter` to cast votes on `voter`'s behalf.
     *
     * This function is mainly used to wrap around voting functionality with a proxy contract to perform additional
     * logic before or after voting.
     *
     * @return The amount of votes the user casted in favor of or against the proposal.
     */
    function castVote(
        address __voter,
        uint __proposalId,
        bool __support
    )
    onlyTrustedOperator(__voter)
    public returns (uint128) {
        return _castVote(__voter, __proposalId, __support);
    }

    // *************************
    // ***** Misc Functions
    // *************************

    function getIsLocalOperator(
        address __voter,
        address __operator
    ) public view returns (bool) {
        return _voterToLocalOperatorToIsSupportedMap[__voter][__operator];
    }

    function getIsGlobalOperator(
        address __operator
    ) public view returns (bool) {
        return _globalOperatorToIsSupportedMap[__operator];
    }

    // *************************
    // ***** Internal Functions
    // *************************

    function _getVotes(
        address __user,
        uint __blockNumber
    ) internal view returns (uint128) {
        return SafeBitMath.add128(
            super._getVotes(__user, __blockNumber),
            assetIntroducerProxy.getPriorVotes(__user, __blockNumber)
        );
    }

}