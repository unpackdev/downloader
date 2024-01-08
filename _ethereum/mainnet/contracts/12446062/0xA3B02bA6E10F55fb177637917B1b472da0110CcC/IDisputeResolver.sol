// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ferittuncer]
 *  @reviewers: [@mtsalenc*, @hbarcelos*, @unknownunknown1*, @MerlinEgalite*]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.7.0;

import "./IArbitrable.sol";
import "./IEvidence.sol";
import "./IArbitrator.sol";

/**
 *  @title This serves as a standard interface for crowdfunded appeals and evidence submission, which are not already standardized by IArbitrable.
    This interface is used in Dispute Resolver (resolve.kleros.io).
 */
abstract contract IDisputeResolver is IArbitrable, IEvidence {
    string public constant VERSION = "1.0.0"; // Can be used to distinguish between multiple deployed versions, if necessary.

    /** @dev Raised when a contribution is made, inside fundAppeal function.
     *  @param localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param round The round number the contribution was made to.
     *  @param ruling Indicates the ruling option which got the contribution.
     *  @param contributor Caller of fundAppeal function.
     *  @param amount Contribution amount.
     */
    event Contribution(uint256 indexed localDisputeID, uint256 indexed round, uint256 ruling, address indexed contributor, uint256 amount);

    /** @dev Raised when a contributor withdraws non-zero value.
     *  @param localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param round The round number the withdrawal was made from.
     *  @param ruling Indicates the ruling option which contributor gets rewards from.
     *  @param contributor The beneficiary of withdrawal.
     *  @param reward Total amount of withdrawal, consists of reimbursed deposits plus rewards.
     */
    event Withdrawal(uint256 indexed localDisputeID, uint256 indexed round, uint256 ruling, address indexed contributor, uint256 reward);

    /** @dev To be raised when a ruling option is fully funded for appeal.
     *  @param localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param round Number of the round this ruling option was fully funded in.
     *  @param ruling The ruling option which just got fully funded.
     */
    event RulingFunded(uint256 indexed localDisputeID, uint256 indexed round, uint256 indexed ruling);

    /** @dev Maps external (arbitrator side) dispute id to local (arbitrable) dispute id.
     *  @param externalDisputeID Dispute id as in arbitrator contract.
     *  @return localDisputeID Dispute id as in arbitrable contract.
     */
    function externalIDtoLocalID(uint256 externalDisputeID) external virtual returns (uint256 localDisputeID);

    /** @dev Returns number of possible ruling options. Valid rulings are [0, return value].
     *  @param localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @return count The number of ruling options.
     */
    function numberOfRulingOptions(uint256 localDisputeID) external view virtual returns (uint256 count);

    /** @dev Allows to submit evidence for a given dispute.
     *  @param localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param evidenceURI IPFS path to evidence, example: '/ipfs/QmYua74eToq6mUpNSEeZUREFZtcWYCrKP6MBepz8C9hTVy/wtf.txt'
     */
    function submitEvidence(uint256 localDisputeID, string calldata evidenceURI) external virtual;

    /** @dev Manages contributions and calls appeal function of the specified arbitrator to appeal a dispute. This function lets appeals be crowdfunded.
     *  @param localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param ruling The ruling option to which the caller wants to contribute.
     *  @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
     */
    function fundAppeal(uint256 localDisputeID, uint256 ruling) external payable virtual returns (bool fullyFunded);

    /** @dev Returns appeal multipliers.
     *  @return winnerStakeMultiplier Winners stake multiplier.
     *  @return loserStakeMultiplier Losers stake multiplier.
     *  @return loserAppealPeriodMultiplier Losers appeal period multiplier. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
     *  @return denominator Multiplier denominator in basis points.
     */
    function getMultipliers()
        external
        view
        virtual
        returns (
            uint256 winnerStakeMultiplier,
            uint256 loserStakeMultiplier,
            uint256 loserAppealPeriodMultiplier,
            uint256 denominator
        );

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved.
     *  @param localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param contributor Beneficiary of withdraw operation.
     *  @param roundNumber Number of the round that caller wants to execute withdraw on.
     *  @param ruling A ruling option that caller wants to execute withdraw on.
     *  @return sum The amount that is going to be transfferred to contributor as a result of this function call, if it's not zero.
     */
    function withdrawFeesAndRewards(
        uint256 localDisputeID,
        address payable contributor,
        uint256 roundNumber,
        uint256 ruling
    ) external virtual returns (uint256 sum);

    /** @dev Allows to withdraw any reimbursable fees or rewards after the dispute gets solved. For multiple ruling options at once.
     *  @param localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param contributor Beneficiary of withdraw operation.
     *  @param roundNumber Number of the round that caller wants to execute withdraw on.
     *  @param contributedTo Ruling options that caller wants to execute withdraw on.
     */
    function withdrawFeesAndRewardsForMultipleRulings(
        uint256 localDisputeID,
        address payable contributor,
        uint256 roundNumber,
        uint256[] memory contributedTo
    ) external virtual;

    /** @dev Allows to withdraw any rewards or reimbursable fees after the dispute gets resolved. For multiple rulings options and for all rounds at once.
     *  @param localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param contributor Beneficiary of withdraw operation.
     *  @param contributedTo Ruling options that caller wants to execute withdraw on.
     */
    function withdrawFeesAndRewardsForAllRounds(
        uint256 localDisputeID,
        address payable contributor,
        uint256[] memory contributedTo
    ) external virtual;

    /** @dev Returns the sum of withdrawable amount.
     *  @param localDisputeID Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
     *  @param contributor Beneficiary of withdraw operation.
     *  @param contributedTo Ruling options that caller wants to execute withdraw on.
     *  @return sum The total amount available to withdraw.
     */
    function getTotalWithdrawableAmount(
        uint256 localDisputeID,
        address payable contributor,
        uint256[] memory contributedTo
    ) public view virtual returns (uint256 sum);
}
