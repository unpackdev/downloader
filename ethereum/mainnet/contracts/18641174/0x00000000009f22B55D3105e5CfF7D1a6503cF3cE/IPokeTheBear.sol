// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPokeTheBear {
    /**
     * @notice The status of a round.
     *         None: The round hasn't started yet.
     *         Open: The round is open for players to enter.
     *         Drawing: The round is being drawn using Chainlink VRF.
     *         Drawn: The round has been drawn. Chainlink VRF has returned a random number.
     *         Revealed: The loser has been revealed.
     *         Cancelled: The round has been cancelled.
     */
    enum RoundStatus {
        None,
        Open,
        Drawing,
        Drawn,
        Revealed,
        Cancelled
    }

    /**
     * @notice A player in a round.
     * @param addr The address of the player.
     * @param isLoser Whether the player is the loser.
     * @param withdrawn Whether the player has withdrawn the prize or the original deposit.
     */
    struct Player {
        address addr;
        bool isLoser;
        bool withdrawn;
    }

    /**
     * @notice A round of Poke The Bear.
     * @param status The status of the round.
     * @param cutoffTime The cutoff time to start or cancel the round if there aren't enough players.
     * @param drawnAt The timestamp when the round was drawn.
     * @param commitment The commitment of the shuffled player indices.
     * @param salt The salt used to generate the commitment.
     * @param playerIndices The player indices.
     * @param players The players.
     */
    struct Round {
        RoundStatus status;
        uint40 cutoffTime;
        uint40 drawnAt;
        bytes32 commitment;
        bytes32 salt;
        uint8[32] playerIndices;
        Player[] players;
    }

    /**
     * @param exists Whether the request exists.
     * @param caveId The id of the cave.
     * @param roundId The id of the round.
     * @param randomWord The random words returned by Chainlink VRF.
     *                   If randomWord == 0, then the request is still pending.
     */
    struct RandomnessRequest {
        bool exists;
        uint40 caveId;
        uint40 roundId;
        uint256 randomWord;
    }

    /**
     * @notice A cave of Poke The Bear.
     * @param enterAmount The amount to enter the cave with.
     * @param enterCurrency The currency to enter the cave with.
     * @param roundsCount The number of rounds in the cave.
     * @param lastCommittedRoundId The last committed round ID.
     * @param roundDuration The duration of a round.
     * @param playersPerRound The maximum number of players in a round.
     * @param protocolFeeBp The protocol fee in basis points.
     */
    struct Cave {
        uint256 enterAmount;
        address enterCurrency;
        uint40 roundsCount;
        uint40 lastCommittedRoundId;
        uint40 roundDuration;
        uint8 playersPerRound;
        uint16 protocolFeeBp;
        bool isActive;
    }

    /**
     * @notice The calldata for commitments.
     * @param caveId The cave ID of the commitments.
     * @param commitments The commitments. The pre-image of the commitment is the shuffled player indices.
     */
    struct CommitmentCalldata {
        uint256 caveId;
        bytes32[] commitments;
    }

    /**
     * @notice The calldata for a withdrawal/claim/rollover.
     * @param caveId The cave ID of the withdrawal/claim/rollover.
     * @param playerDetails The player's details in the rounds' players array.
     */
    struct WithdrawalCalldata {
        uint256 caveId;
        PlayerWithdrawalCalldata[] playerDetails;
    }

    /**
     * @notice The calldata for a withdrawal/claim/rollover.
     * @param caveId The cave ID of the withdrawal/claim/rollover.
     * @param startingRoundId The starting round ID to enter.
     * @param numberOfExtraRoundsToEnter The number of extra rounds to enter, in addition to rollover rounds.
     * @param playerDetails The player's details in the rounds' players array.
     */
    struct RolloverCalldata {
        uint256 caveId;
        uint256 startingRoundId;
        uint256 numberOfExtraRoundsToEnter;
        PlayerWithdrawalCalldata[] playerDetails;
    }

    /**
     * @notice The calldata for a single player withdrawal/claim/rollover.
     * @param roundId The round ID of the withdrawal/claim/rollover.
     * @param playerIndex The player index of the withdrawal/claim/rollover.
     */
    struct PlayerWithdrawalCalldata {
        uint256 roundId;
        uint256 playerIndex;
    }

    /**
     * @notice The withdrawal/claim/rollover.
     * @param caveId The cave ID of the withdrawal/claim/rollover.
     * @param roundIds The round IDs to withdraw/claim/rollover.
     */
    struct Withdrawal {
        uint256 caveId;
        uint256[] roundIds;
    }

    /**
     * @notice The rollover for event emission.
     * @param caveId The cave ID of the rollover.
     * @param rolledOverRoundIds The rolled over round IDs.
     * @param rollingOverToRoundIdStart The starting round ID to roll into
     */
    struct Rollover {
        uint256 caveId;
        uint256[] rolledOverRoundIds;
        uint256 rollingOverToRoundIdStart;
    }

    /**
     * @notice This is used to accumulate the amount of tokens to be transferred.
     * @param tokenAddress The address of the token.
     * @param amount The amount of tokens accumulated.
     */
    struct TransferAccumulator {
        address tokenAddress;
        uint256 amount;
    }

    event CommitmentsSubmitted(CommitmentCalldata[] commitments);
    event DepositsRolledOver(Rollover[] rollovers, address player);
    event DepositsRefunded(Withdrawal[] deposits, address player);
    event PrizesClaimed(Withdrawal[] prizes, address player);
    event ProtocolFeeRecipientUpdated(address protocolFeeRecipient);
    event RoundStatusUpdated(uint256 caveId, uint256 roundId, RoundStatus status);
    event RoundsCancelled(uint256 caveId, uint256 startingRoundId, uint256 numberOfRounds);
    event RoundsEntered(uint256 caveId, uint256 startingRoundId, uint256 numberOfRounds, address player);
    event RandomnessRequested(uint256 caveId, uint256 roundId, uint256 requestId);
    event CaveAdded(
        uint256 caveId,
        uint256 enterAmount,
        address enterCurrency,
        uint40 roundDuration,
        uint8 playersPerRound,
        uint16 protocolFeeBp
    );
    event CaveRemoved(uint256 caveId);

    error CommitmentNotAvailable();
    error ExceedsMaximumNumberOfPlayersPerRound();
    error HashedPlayerIndicesDoesNotMatchCommitment();
    error InactiveCave();
    error IndivisibleEnterAmount();
    error IneligibleToWithdraw(uint256 caveId, uint256 roundId);
    error InvalidEnterAmount();
    error InsufficientNumberOfPlayers();
    error InvalidCommitment(uint256 caveId, uint256 roundId);
    error InvalidPlayerDetails();
    error InvalidPlayerIndex(uint256 caveId, uint256 roundId);
    error InvalidRoundDuration();
    error InvalidRoundParameters();
    error InvalidRoundStatus();
    error InvalidEnterCurrency();
    error InvalidValue();
    error NotOperator();
    error NotOwner();
    error NotCancellable();
    error PlayerAlreadyParticipated(uint256 caveId, uint256 roundId, address player);
    error ProtocolFeeBasisPointsTooHigh();
    error RepeatingPlayerIndex();
    error RandomnessRequestAlreadyExists();
    error RoundCannotBeEntered(uint256 caveId, uint256 roundId);
    error RoundsIncomplete();

    /**
     * @notice Add a new cave. Only callable by the contract owner.
     * @param enterAmount The amount to enter the cave with.
     * @param enterCurrency The currency to enter the cave with.
     * @param playersPerRound The maximum number of players in a round.
     * @param roundDuration The duration of a round.
     * @param protocolFeeBp The protocol fee in basis points. Max 25%.
     */
    function addCave(
        uint256 enterAmount,
        address enterCurrency,
        uint8 playersPerRound,
        uint40 roundDuration,
        uint16 protocolFeeBp
    ) external returns (uint256 caveId);

    /**
     * @notice Remove a cave. Only callable by the contract owner.
     * @param caveId The cave ID to remove.
     */
    function removeCave(uint256 caveId) external;

    /**
     * @dev Update the protocol fee recipient. Only callable by the contract owner.
     * @param _protocolFeeRecipient The address of the protocol fee recipient
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external;

    /**
     * @notice Enter the current round of a cave.
     * @param caveId The cave ID of the round to enter.
     * @param startingRoundId The starting round ID to enter.
     * @param numberOfRounds The number of rounds to enter, starting from the starting round ID.
     */
    function enter(uint256 caveId, uint256 startingRoundId, uint256 numberOfRounds) external payable;

    /**
     * @notice Commit the player indices for multiple rounds.
     * @param commitments The array of commitments.
     */
    function commit(CommitmentCalldata[] calldata commitments) external;

    /**
     * @notice Reveal the result of a round.
     * @param requestId The Chainlink VRF request ID.
     * @param playerIndices The indices of the players.
     * @param salt The salt used to concatenate with the playerIndices to generate the commitment.
     */
    function reveal(uint256 requestId, uint256 playerIndices, bytes32 salt) external;

    /**
     * @notice Get a refund for cancelled rounds.
     * @param refundCalldataArray The array of refund calldata.
     */
    function refund(WithdrawalCalldata[] calldata refundCalldataArray) external;

    /**
     * @notice Rollover cancelled rounds' deposits to the current round + upcoming rounds.
     * @param rolloverCalldataArray The array of rollover calldata.
     */
    function rollover(RolloverCalldata[] calldata rolloverCalldataArray) external payable;

    /**
     * @notice Claim prizes for multiple rounds.
     * @param claimPrizeCalldataArray The array of claim prize calldata.
     */
    function claimPrizes(WithdrawalCalldata[] calldata claimPrizeCalldataArray) external;

    /**
     * @notice Cancel the latest round when the round is expired.
     * @param caveId The cave ID of the round to cancel.
     */
    function cancel(uint256 caveId) external;

    /**
     * @notice Allow the contract owner to cancel the current and future rounds if the contract is paused.
     * @param caveId The cave ID of the rounds to cancel.
     * @param numberOfRounds The number of rounds to cancel..
     */
    function cancel(uint256 caveId, uint256 numberOfRounds) external;

    /**
     * @notice Get a round of a given cave.
     * @param caveId The cave ID.
     * @param roundId The round ID.
     */
    function getRound(
        uint256 caveId,
        uint256 roundId
    )
        external
        view
        returns (
            RoundStatus status,
            uint40 cutoffTime,
            uint40 drawnAt,
            bytes32 commitment,
            bytes32 salt,
            uint8[32] memory playerIndices,
            Player[] memory players
        );

    /**
     * @notice Check if the player is in a specific round.
     * @param caveId The cave ID.
     * @param roundId The round ID.
     * @return The player's address.
     */
    function isPlayerInRound(uint256 caveId, uint256 roundId, address player) external view returns (bool);

    /**
     * @notice This function allows the owner to pause/unpause the contract.
     */
    function togglePaused() external;
}
