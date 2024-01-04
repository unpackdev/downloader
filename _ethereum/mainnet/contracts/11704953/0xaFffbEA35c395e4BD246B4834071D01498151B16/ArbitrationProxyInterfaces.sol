// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

import "./IArbitrable.sol";
import "./IEvidence.sol";

interface IHomeArbitrationProxy {
    /**
     * @notice To be emitted when arbitration request is rejected.
     * @dev This can happen if the contested answer is different from the current best answer,
     * if the notification of arbitration request fails or if the question is already finalized.
     * @param _questionID The ID of the question.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     * @param _requester The address of the user that requested arbitration.
     */
    event RequestRejected(bytes32 indexed _questionID, bytes32 indexed _contestedAnswer, address indexed _requester);

    /**
     * @notice To be emitted when the Realitio contract has been notified of an arbitration request.
     * @param _questionID The ID of the question.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     * @param _requester The address of the user that requested arbitration.
     */
    event RequestNotified(bytes32 indexed _questionID, bytes32 indexed _contestedAnswer, address indexed _requester);

    /**
     * @notice To be emitted when the arbitration request acknowledgement is sent to the Foreign Chain.
     * @param _questionID The ID of the question.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     */
    event RequestAcknowledged(bytes32 indexed _questionID, bytes32 indexed _contestedAnswer);

    /**
     * @notice To be emitted when the arbitration request is canceled.
     * @param _questionID The ID of the question.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     */
    event RequestCanceled(bytes32 indexed _questionID, bytes32 indexed _contestedAnswer);

    /**
     * @notice To be emitted when the dispute could not be created on the Foreign Chain.
     * @dev This will happen if the arbitration fee increases in between the arbitration request and acknowledgement.
     * @param _questionID The ID of the question.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     */
    event ArbitrationFailed(bytes32 indexed _questionID, bytes32 indexed _contestedAnswer);

    /**
     * @notice To be emitted when receiving the answer from the arbitrator.
     * @param _questionID The ID of the question.
     * @param _answer The answer from the arbitrator.
     */
    event ArbitratorAnswered(bytes32 indexed _questionID, bytes32 _answer);

    /**
     * @notice To be emitted when reporting the arbitrator answer to Realitio.
     * @param _questionID The ID of the question.
     */
    event ArbitrationFinished(bytes32 indexed _questionID);

    /**
     * @dev Receives the requested arbitration for a question. TRUSTED.
     * @param _questionID The ID of the question.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     * @param _requester The address of the user that requested arbitration.
     */
    function receiveArbitrationRequest(
        bytes32 _questionID,
        bytes32 _contestedAnswer,
        address _requester
    ) external;

    /**
     * @notice Handles arbitration request after it has been notified to Realitio for a given question.
     * @dev This method exists because `receiveArbitrationRequest` is called by the AMB and cannot send messages back to it.
     * @param _questionID The ID of the question.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     */
    function handleNotifiedRequest(bytes32 _questionID, bytes32 _contestedAnswer) external;

    /**
     * @notice Handles arbitration request after it has been rejected.
     * @dev This method exists because `receiveArbitrationRequest` is called by the AMB and cannot send messages back to it.
     * Reasons why the request might be rejected:
     *  - The question does not exist
     *  - The question was not answered yet
     *  - The contested answer is different from the current best answer
     *  - Another request was already accepted
     * @param _questionID The ID of the question.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     */
    function handleRejectedRequest(bytes32 _questionID, bytes32 _contestedAnswer) external;

    /**
     * @notice Receives a failed attempt to request arbitration. TRUSTED.
     * @param _questionID The ID of the question.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     */
    function receiveArbitrationFailure(bytes32 _questionID, bytes32 _contestedAnswer) external;

    /**
     * @notice Receives the answer to a specified question. TRUSTED.
     * @param _questionID The ID of the question.
     * @param _answer The answer from the arbitrator.
     */
    function receiveArbitrationAnswer(bytes32 _questionID, bytes32 _answer) external;
}

interface IForeignArbitrationProxy is IArbitrable, IEvidence {
    /**
     * @notice Should be emitted when the arbitration is requested.
     * @param _questionID The ID of the question to be arbitrated.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     * @param _requester The requester.
     */
    event ArbitrationRequested(
        bytes32 indexed _questionID,
        bytes32 indexed _contestedAnswer,
        address indexed _requester
    );

    /**
     * @notice Should be emitted when the dispute is created.
     * @param _questionID The ID of the question to be arbitrated.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     * @param _disputeID The ID of the dispute.
     */
    event ArbitrationCreated(bytes32 indexed _questionID, bytes32 indexed _contestedAnswer, uint256 indexed _disputeID);

    /**
     * @notice Should be emitted when the dispute could not be created.
     * @dev This will happen if there is an increase in the arbitration fees
     * between the time the arbitration is made and the time it is acknowledged.
     * @param _questionID The ID of the question to be arbitrated.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     */
    event ArbitrationFailed(bytes32 indexed _questionID, bytes32 indexed _contestedAnswer);

    /**
     * @notice Should be emitted when the arbitration is canceled by the Home Chain.
     * @param _questionID The ID of the question to be arbitrated.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     */
    event ArbitrationCanceled(bytes32 indexed _questionID, bytes32 indexed _contestedAnswer);

    /**
     * @notice Requests arbitration for the given question and contested answer.
     * @dev Can be executed only if the contract has been initialized.
     * @param _questionID The ID of the question.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     */
    function requestArbitration(bytes32 _questionID, bytes32 _contestedAnswer) external payable;

    /**
     * @dev Acknowledges the arbitration request for the given question and contested answer. TRUSTED.
     * @param _questionID The ID of the question.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     */
    function acknowledgeArbitration(bytes32 _questionID, bytes32 _contestedAnswer) external;

    /**
     * @dev Cancels the arbitration request. TRUSTED.
     * @param _questionID The ID of the question.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     */
    function cancelArbitration(bytes32 _questionID, bytes32 _contestedAnswer) external;

    /**
     * @notice Cancels the arbitration in case the dispute could not be created.
     * @param _questionID The ID of the question.
     * @param _contestedAnswer The answer the requester deems to be incorrect.
     */
    function handleFailedDisputeCreation(bytes32 _questionID, bytes32 _contestedAnswer) external;

    /**
     * @notice Gets the fee to create a dispute.
     * @param _questionID the ID of the question.
     * @return The fee to create a dispute.
     */
    function getDisputeFee(bytes32 _questionID) external view returns (uint256);
}
