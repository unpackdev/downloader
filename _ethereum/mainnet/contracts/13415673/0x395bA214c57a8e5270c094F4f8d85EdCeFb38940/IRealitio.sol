// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@hbarcelos]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.7.6;

/**
 *  @title IRealitio
 *  @dev Required subset of https://github.com/realitio/realitio-contracts/blob/master/truffle/contracts/IRealitio.sol to implement a Realitio arbitrator.
 */
interface IRealitio {
    /// @notice Notify the contract that the arbitrator has been paid for a question, freezing it pending their decision.
    /// @dev The arbitrator contract is trusted to only call this if they've been paid, and tell us who paid them.
    /// @param question_id The ID of the question
    /// @param requester The account that requested arbitration
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    function notifyOfArbitrationRequest(
        bytes32 question_id,
        address requester,
        uint256 max_previous
    ) external;

    /// @notice Submit the answer for a question, for use by the arbitrator.
    /// @dev Doesn't require (or allow) a bond. Required only in v2.0.
    /// If the current final answer is correct, the account should be whoever submitted it.
    /// If the current final answer is wrong, the account should be whoever paid for arbitration.
    /// However, the answerer stipulations are not enforced by the contract.
    /// @param question_id The ID of the question.
    /// @param answer The answer, encoded into bytes32.
    /// @param answerer The account credited with this answer for the purpose of bond claims.
    function submitAnswerByArbitrator(
        bytes32 question_id,
        bytes32 answer,
        address answerer
    ) external;

    /// @notice Returns the history hash of the question. Required before calling submitAnswerByArbitrator to make sure history is correct.
    /// @dev Required only in v2.0.
    /// @param question_id The ID of the question.
    /// @dev Updated on each answer, then rewound as each is claimed.
    function getHistoryHash(bytes32 question_id) external view returns (bytes32);

    /// @notice Returns the commitment info by its id. Required before calling submitAnswerByArbitrator to make sure history is correct.
    /// @dev Required only in v2.0.
    /// @param commitment_id The ID of the commitment.
    /// @return Time after which the committed answer can be revealed.
    /// @return Whether the commitment has already been revealed or not.
    /// @return The committed answer, encoded as bytes32.
    function commitments(bytes32 commitment_id)
        external
        view
        returns (
            uint32,
            bool,
            bytes32
        );

    /// @notice Submit the answer for a question, for use by the arbitrator, working out the appropriate winner based on the last answer details.
    /// @dev Doesn't require (or allow) a bond. Required only in v2.1.
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded into bytes32
    /// @param payee_if_wrong The account to by credited as winner if the last answer given is wrong, usually the account that paid the arbitrator
    /// @param last_history_hash The history hash before the final one
    /// @param last_answer_or_commitment_id The last answer given, or the commitment ID if it was a commitment.
    /// @param last_answerer The address that supplied the last answer
    function assignWinnerAndSubmitAnswerByArbitrator(
        bytes32 question_id,
        bytes32 answer,
        address payee_if_wrong,
        bytes32 last_history_hash,
        bytes32 last_answer_or_commitment_id,
        address last_answerer
    ) external;
}
