// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@unknownunknown1, @hbarcelos*, @MerlinEgalite, @shalzz*, @fnanni-0*, @clesaege*, @jaybuidl*]
 *  @auditors: []
 *  @bounties: []
 */

pragma solidity ^0.7.0;

import "./IRealitio.sol";
import "./IRealitioArbitrator.sol";
import "./IDisputeResolver.sol";
import "./CappedMath.sol";

/**
 *  @title RealitioArbitratorWithAppealsBase
 *  @dev A Realitio arbitrator base implementation that uses Realitio v2.x and Kleros. It notifies Realitio contract for arbitration requests and creates corresponding dispute on Kleros. Transmits Kleros ruling to Realitio contract. Maintains crowdfunded appeals and notifies Kleros contract. Provides a function to submit evidence for Kleros dispute. This contract is abstract as it does not have a function to report answer, see child contracts.
 *  There is a conversion between Kleros ruling and Realitio answer and there is a need for shifting by 1. This is because ruling 0 in Kleros signals tie or no-ruling but in Realitio 0 is a valid answer. For reviewers this should be a focus as it's quite easy to get confused. Any mistakes on this conversion will render this contract useless.
 *  NOTE: This contract trusts the Kleros arbitrator and Realitio.
 */
abstract contract RealitioArbitratorWithAppealsBase is IDisputeResolver, IRealitioArbitrator {
    using CappedMath for uint256; // Overflows and underflows are prevented by returning uint256 max and min values in case of overflows and underflows, respectively.

    IRealitio public immutable override realitio; // Actual implementation of Realitio.
    IArbitrator public immutable arbitrator; // The Kleros arbitrator.
    bytes public arbitratorExtraData; // Required for Kleros arbitrator. First 64 bytes contain subcourtID and the second 64 bytes contain number of votes in the jury.
    string public override metadata; // Metadata for Realitio. See IRealitioArbitrator.

    // The required fee stake that a party must deposit, which depends on who won the previous round and is proportional to the arbitration cost such that the fee stake for a round is `multiplier * arbitration_cost` for that round.
    uint256 public constant WINNER_STAKE_MULTIPLIER = 3000; // Multiplier of the arbitration cost that the winner has to pay as fee stake for a round in basis points.
    uint256 public constant LOSER_STAKE_MULTIPLIER = 7000; // Multiplier of the arbitration cost that the loser has to pay as fee stake for a round in basis points.
    uint256 public constant LOSER_APPEAL_PERIOD_MULTIPLIER = 5000; // Multiplier of the appeal period for losers (any other ruling options) in basis points. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
    uint256 public constant MULTIPLIER_DENOMINATOR = 10000; // Denominator for multipliers.
    uint256 private constant NUMBER_OF_RULING_OPTIONS = type(uint256).max; // The amount of non 0 choices the arbitrator can give.

    enum Status {
        None, // The question hasn't been requested arbitration yet.
        Disputed, // The question has been requested arbitration.
        Ruled, // The question has been ruled by arbitrator.
        Reported // The answer of the question has been reported to Realitio.
    }

    // To track internal dispute state in this contract.
    struct ArbitrationRequest {
        Status status; // The current status of the question.
        address requester; // The address that requested the arbitration.
        uint256 disputeID; // The ID of the dispute raised in the arbitrator contract.
        uint256 ruling; // The ruling given by the arbitrator.
        Round[] rounds; // Tracks each appeal round of a dispute.
    }

    // For appeal logic.
    struct Round {
        mapping(uint256 => uint256) paidFees; // Tracks the fees paid in this round in the form paidFees[answer].
        mapping(uint256 => bool) hasPaid; // True if the fees for this particular answer has been fully paid in the form hasPaid[answer].
        mapping(address => mapping(uint256 => uint256)) contributions; // Maps contributors to their contributions for each answer in the form contributions[address][answer].
        uint256 feeRewards; // Sum of reimbursable appeal fees available to the parties that made contributions to the answer that ultimately wins a dispute.
        uint256[] fundedRulings; // Stores the answer choices that are fully funded.
    }

    mapping(uint256 => ArbitrationRequest) public arbitrationRequests; // Maps a question identifier in uint to its arbitration details. Example: arbitrationRequests[uint(questionID)]
    mapping(uint256 => uint256) public override externalIDtoLocalID; // Map arbitrator dispute identifiers to local identifiers. We use question ids casted to uint as local identifier.

    /** @dev Emitted when arbitration is requested, to link dispute identifier to question identifier for dynamic script that is used in metaevidence. See https://github.com/kleros/realitio-script/blob/master/src/index.js
     *  @param _disputeID The ID of the dispute in the ERC792 arbitrator.
     *  @param _questionID The ID of the question.
     */
    event DisputeIDToQuestionID(uint256 indexed _disputeID, bytes32 _questionID);

    /** @dev Constructor.
     *  @param _realitio The address of the Realitio contract.
     *  @param _metadata The metadata required for RealitioArbitrator.
     *  @param _arbitrator The address of the ERC792 arbitrator.
     *  @param _arbitratorExtraData The extra data used to raise a dispute in the ERC792 arbitrator.
     *  @param _metaevidence Metaevidence as defined in ERC-1497.
     */
    constructor(
        IRealitio _realitio,
        string memory _metadata,
        IArbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        string memory _metaevidence
    ) {
        realitio = _realitio;
        metadata = _metadata;
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
        emit MetaEvidence(0, _metaevidence); // No setter for meta-evidence. To change it, deploy a new contract.
    }

    /** @dev Allows to submit evidence for a given dispute.
     *  @param _questionID Realitio question identifier.
     *  @param _evidenceURI Link to evidence.
     */
    function submitEvidence(uint256 _questionID, string calldata _evidenceURI) external override {
        emit Evidence(arbitrator, _questionID, msg.sender, _evidenceURI); // We use _questionID for evidence group identifier.
    }

    /** @dev Request arbitration from Kleros for given _questionID.
     *  @param _questionID The question identifier in Realitio contract.
     *  @param _maxPrevious If specified, reverts if a bond higher than this was submitted after you sent your transaction.
     *  @return disputeID ID of the resulting dispute on arbitrator.
     */
    function requestArbitration(bytes32 _questionID, uint256 _maxPrevious) external payable returns (uint256 disputeID) {
        ArbitrationRequest storage arbitrationRequest = arbitrationRequests[uint256(_questionID)];
        require(arbitrationRequest.status == Status.None, "Arbitration already requested");

        // Notify Kleros
        disputeID = arbitrator.createDispute{value: msg.value}(NUMBER_OF_RULING_OPTIONS, arbitratorExtraData); /* If msg.value is greater than intended number of votes (specified in arbitratorExtraData),
        Kleros will automatically spend excess for additional votes. */
        emit Dispute(arbitrator, disputeID, 0, uint256(_questionID)); // We use _questionID in uint as evidence group identifier.
        emit DisputeIDToQuestionID(disputeID, _questionID); // For the dynamic script https://github.com/kleros/realitio-script/blob/master/src/index.js
        externalIDtoLocalID[disputeID] = uint256(_questionID);

        // Update internal state
        arbitrationRequest.requester = msg.sender;
        arbitrationRequest.status = Status.Disputed;
        arbitrationRequest.disputeID = disputeID;
        arbitrationRequest.rounds.push();

        // Notify Realitio
        realitio.notifyOfArbitrationRequest(_questionID, msg.sender, _maxPrevious);
    }

    /** @dev Receives ruling from Kleros and enforces it.
     *  @param _disputeID ID of Kleros dispute.
     *  @param _ruling Ruling that is given by Kleros. This needs to be converted to Realitio answer before reporting the answer by shifting by 1.
     */
    function rule(uint256 _disputeID, uint256 _ruling) public override {
        require(IArbitrator(msg.sender) == arbitrator, "Only arbitrator allowed");

        uint256 questionID = externalIDtoLocalID[_disputeID];
        ArbitrationRequest storage arbitrationRequest = arbitrationRequests[questionID];

        require(arbitrationRequest.status == Status.Disputed, "Invalid arbitration status");

        Round storage round = arbitrationRequest.rounds[arbitrationRequest.rounds.length - 1];

        // If there is only one ruling option in last round that is fully funded, no matter what Kleros ruling was this ruling option is the winner by default.
        uint256 finalRuling = (round.fundedRulings.length == 1) ? round.fundedRulings[0] : _ruling;

        arbitrationRequest.ruling = finalRuling;
        arbitrationRequest.status = Status.Ruled;

        emit Ruling(IArbitrator(msg.sender), _disputeID, finalRuling);

        // Ready to call `reportAnswer` now.
    }

    /** @dev TRUSTED. Manages crowdfunded appeals contributions and calls appeal function of the Kleros arbitrator to appeal a dispute.
     *  @param _questionID Identifier of the Realitio question, casted to uint. This also serves as the local identifier in this contract.
     *  @param _ruling The ruling option to which the caller wants to contribute to.
     *  @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
     */
    function fundAppeal(uint256 _questionID, uint256 _ruling) external payable override returns (bool fullyFunded) {
        ArbitrationRequest storage arbitrationRequest = arbitrationRequests[_questionID];
        require(arbitrationRequest.status == Status.Disputed, "No dispute to appeal.");

        uint256 disputeID = arbitrationRequest.disputeID;
        uint256 currentRuling = arbitrator.currentRuling(disputeID);
        uint256 originalCost;
        uint256 totalCost;
        {
            (uint256 originalStart, uint256 originalEnd) = arbitrator.appealPeriod(disputeID);

            uint256 multiplier;

            if (_ruling == currentRuling) {
                require(block.timestamp < originalEnd, "Funding must be made within the appeal period.");

                multiplier = WINNER_STAKE_MULTIPLIER;
            } else {
                require(block.timestamp < (originalStart + ((originalEnd - originalStart) / 2)), "Funding must be made within the first half appeal period.");

                multiplier = LOSER_STAKE_MULTIPLIER;
            }

            originalCost = arbitrator.appealCost(disputeID, arbitratorExtraData);
            totalCost = originalCost.addCap(originalCost.mulCap(multiplier) / MULTIPLIER_DENOMINATOR);
        }

        uint256 lastRoundIndex = arbitrationRequest.rounds.length - 1;
        Round storage lastRound = arbitrationRequest.rounds[lastRoundIndex];
        require(!lastRound.hasPaid[_ruling], "Appeal fee has already been paid.");

        uint256 contribution = totalCost.subCap(lastRound.paidFees[_ruling]) > msg.value ? msg.value : totalCost.subCap(lastRound.paidFees[_ruling]);
        emit Contribution(_questionID, lastRoundIndex, _ruling, msg.sender, contribution);

        lastRound.contributions[msg.sender][_ruling] += contribution;
        lastRound.paidFees[_ruling] += contribution;

        if (lastRound.paidFees[_ruling] >= totalCost) {
            lastRound.feeRewards += lastRound.paidFees[_ruling];
            lastRound.fundedRulings.push(_ruling);
            lastRound.hasPaid[_ruling] = true;
            emit RulingFunded(_questionID, lastRoundIndex, _ruling);
        }

        if (lastRound.fundedRulings.length == 2) {
            // At least two ruling options are fully funded.
            arbitrationRequest.rounds.push();

            lastRound.feeRewards = lastRound.feeRewards.subCap(originalCost);
            arbitrator.appeal{value: originalCost}(disputeID, arbitratorExtraData);
        }

        if (msg.value.subCap(contribution) > 0) msg.sender.send(msg.value.subCap(contribution)); // Sending extra value back to contributor.

        return lastRound.hasPaid[_ruling];
    }

    /** @dev Returns number of possible ruling options. Valid rulings are [0, count].
     *  @return count The number of ruling options.
     */
    function numberOfRulingOptions(uint256) external pure override returns (uint256 count) {
        return NUMBER_OF_RULING_OPTIONS;
    }

    /** @dev Returns arbitration fee by calling arbitrationCost function in the arbitrator contract.
     *  @return fee Arbitration fee that needs to be paid.
     */
    function getDisputeFee(bytes32) external view override returns (uint256 fee) {
        return arbitrator.arbitrationCost(arbitratorExtraData);
    }

    /** @dev Returns multipliers for appeals.
     *  @return _WINNER_STAKE_MULTIPLIER Winners stake multiplier.
     *  @return _LOSER_STAKE_MULTIPLIER Losers stake multiplier.
     *  @return _LOSER_APPEAL_PERIOD_MULTIPLIER Losers appeal period multiplier. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
     *  @return _DENOMINATOR Multiplier denominator in basis points. Required for achieving floating-point-like behavior.
     */
    function getMultipliers()
        external
        pure
        override
        returns (
            uint256 _WINNER_STAKE_MULTIPLIER,
            uint256 _LOSER_STAKE_MULTIPLIER,
            uint256 _LOSER_APPEAL_PERIOD_MULTIPLIER,
            uint256 _DENOMINATOR
        )
    {
        return (WINNER_STAKE_MULTIPLIER, LOSER_STAKE_MULTIPLIER, LOSER_APPEAL_PERIOD_MULTIPLIER, MULTIPLIER_DENOMINATOR);
    }

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved. For all rounds at once.
     *  This function has O(m) time complexity where m is number of rounds.
     *  It is safe to assume m is always less than 10 as appeal cost growth order is O(2^m).
     *  @param _questionID Identifier of the Realitio question, casted to uint. This also serves as the local identifier in this contract.
     *  @param _contributor The address whose rewards to withdraw.
     *  @param _ruling Ruling that received contributions from contributor.
     */
    function withdrawFeesAndRewardsForAllRounds(
        uint256 _questionID,
        address payable _contributor,
        uint256 _ruling
    ) external override {
        ArbitrationRequest storage arbitrationRequest = arbitrationRequests[_questionID];
        uint256 noOfRounds = arbitrationRequest.rounds.length;

        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            withdrawFeesAndRewards(_questionID, _contributor, roundNumber, _ruling);
        }
    }

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved.
     *  @param _questionID Identifier of the Realitio question, casted to uint. This also serves as the local identifier in this contract.
     *  @param _contributor The address whose rewards to withdraw.
     *  @param _roundNumber The number of the round caller wants to withdraw from.
     *  @param _ruling Ruling that received contribution from contributor.
     *  @return amount The amount available to withdraw for given question, contributor, round number and ruling option.
     */
    function withdrawFeesAndRewards(
        uint256 _questionID,
        address payable _contributor,
        uint256 _roundNumber,
        uint256 _ruling
    ) public override returns (uint256 amount) {
        ArbitrationRequest storage arbitrationRequest = arbitrationRequests[_questionID];
        require(arbitrationRequest.status > Status.Disputed, "There is no ruling yet.");

        Round storage round = arbitrationRequest.rounds[_roundNumber];

        amount = getWithdrawableAmount(round, _contributor, _ruling, arbitrationRequest.ruling);

        if (amount != 0) {
            round.contributions[_contributor][_ruling] = 0;
            _contributor.send(amount); // Ignoring failure condition deliberately.
            emit Withdrawal(_questionID, _roundNumber, _ruling, _contributor, amount);
        }
    }

    /** @dev Returns the sum of withdrawable amount.
     *  This function has O(m) time complexity where m is number of rounds.
     *  It is safe to assume m is always less than 10 as appeal cost growth order is O(m^2).
     *  @param _questionID Identifier of the Realitio question, casted to uint. This also serves as the local identifier in this contract.
     *  @param _contributor The contributor for which to query.
     *  @param _ruling Ruling option to look for potential withdrawals.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        uint256 _questionID,
        address payable _contributor,
        uint256 _ruling
    ) external view override returns (uint256 sum) {
        ArbitrationRequest storage arbitrationRequest = arbitrationRequests[_questionID];
        if (arbitrationRequest.status < Status.Ruled) return 0;
        uint256 noOfRounds = arbitrationRequest.rounds.length;
        uint256 finalRuling = arbitrationRequest.ruling;

        for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
            Round storage round = arbitrationRequest.rounds[roundNumber];
            sum += getWithdrawableAmount(round, _contributor, _ruling, finalRuling);
        }
    }

    /** @dev Returns withdrawable amount for given parameters.
     *  @param _round The round to calculate amount for.
     *  @param _contributor The contributor for which to query.
     *  @param _ruling The ruling option to search for potential withdrawal.
     *  @param _finalRuling Final ruling given by arbitrator.
     *  @return amount Amount available to withdraw for given ruling option.
     */
    function getWithdrawableAmount(
        Round storage _round,
        address _contributor,
        uint256 _ruling,
        uint256 _finalRuling
    ) internal view returns (uint256 amount) {
        if (!_round.hasPaid[_ruling]) {
            // Allow to reimburse if funding was unsuccessful for this ruling option.
            amount = _round.contributions[_contributor][_ruling];
        } else {
            // Funding was successful for this ruling option.
            if (_ruling == _finalRuling) {
                // This ruling option is the ultimate winner.
                amount = _round.paidFees[_ruling] > 0 ? (_round.contributions[_contributor][_ruling] * _round.feeRewards) / _round.paidFees[_ruling] : 0;
            } else if (!_round.hasPaid[_finalRuling]) {
                // The ultimate winner was not funded in this round. Contributions discounting the appeal fee are reimbursed proportionally.
                amount = (_round.contributions[_contributor][_ruling] * _round.feeRewards) / (_round.paidFees[_round.fundedRulings[0]] + _round.paidFees[_round.fundedRulings[1]]);
            }
        }
    }
}
