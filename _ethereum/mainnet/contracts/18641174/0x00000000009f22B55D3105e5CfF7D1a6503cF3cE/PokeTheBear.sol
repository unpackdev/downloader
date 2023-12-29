// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LowLevelWETH.sol";
import "./LowLevelERC20Transfer.sol";
import "./PackableReentrancyGuard.sol";
import "./Pausable.sol";

import "./ITransferManager.sol";

import "./AccessControl.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

import "./IPokeTheBear.sol";

//       ∩＿＿＿∩
//      |ノ      ヽ
//     /   ●    ● | クマ──！！
//    |     (_●_) ミ
//   彡､     |∪|  ､｀＼
// / ＿＿    ヽノ /´>   )
// (＿＿＿）     /  (_／
//   |        /
//   |   ／＼  ＼
//   | /     )   )
//    ∪     （   ＼
//            ＼＿)

/**
 * @title Poke The Bear, a bear might maul you to death if you poke it.
 * @author LooksRare protocol team (👀,💎)
 */
contract PokeTheBear is
    IPokeTheBear,
    AccessControl,
    Pausable,
    PackableReentrancyGuard,
    LowLevelERC20Transfer,
    LowLevelWETH,
    VRFConsumerBaseV2
{
    /**
     * @notice Operators are allowed to commit rounds
     */
    bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @notice 100% in basis points.
     */
    uint256 private constant ONE_HUNDRED_PERCENT_IN_BASIS_POINTS = 10_000;

    /**
     * @notice The maximum number of players per round.
     */
    uint256 private constant MAXIMUM_NUMBER_OF_PLAYERS_PER_ROUND = 32;

    /**
     * @notice The minimum duration for a round.
     */
    uint40 private constant MINIMUM_ROUND_DURATION = 1 minutes;

    /**
     * @notice The maximum duration for a round.
     */
    uint40 private constant MAXIMUM_ROUND_DURATION = 1 hours;

    /**
     * @notice Wrapped native token address. (WETH for most chains)
     */
    address private immutable WRAPPED_NATIVE_TOKEN;

    /**
     * @notice The key hash of the Chainlink VRF.
     */
    bytes32 private immutable KEY_HASH;

    /**
     * @notice The subscription ID of the Chainlink VRF.
     */
    uint64 private immutable SUBSCRIPTION_ID;

    /**
     * @notice The Chainlink VRF coordinator.
     */
    VRFCoordinatorV2Interface private immutable VRF_COORDINATOR;

    /**
     * @notice The transfer manager to handle ERC-20 deposits.
     */
    ITransferManager private immutable TRANSFER_MANAGER;

    mapping(uint256 requestId => RandomnessRequest) public randomnessRequests;

    mapping(uint256 caveId => mapping(uint256 => Round)) private rounds;

    /**
     * @notice Player participations in each round.
     * @dev 65,536 x 256 = 16,777,216 rounds, which is enough for 5 minutes rounds for 159 years.
     */
    mapping(address playerAddress => mapping(uint256 caveId => uint256[65536] roundIds)) private playerParticipations;

    mapping(uint256 caveId => Cave) public caves;

    /**
     * @notice The address of the protocol fee recipient.
     */
    address public protocolFeeRecipient;

    /**
     * @notice The next cave ID.
     */
    uint256 public nextCaveId = 1;

    /**
     * @param _owner The owner of the contract.
     * @param _protocolFeeRecipient The address of the protocol fee recipient.
     * @param wrappedNativeToken The wrapped native token address.
     * @param _transferManager The transfer manager to handle ERC-20 deposits.
     * @param keyHash The key hash of the Chainlink VRF.
     * @param vrfCoordinator The Chainlink VRF coordinator.
     * @param subscriptionId The subscription ID of the Chainlink VRF.
     */
    constructor(
        address _owner,
        address _operator,
        address _protocolFeeRecipient,
        address wrappedNativeToken,
        address _transferManager,
        bytes32 keyHash,
        address vrfCoordinator,
        uint64 subscriptionId
    ) VRFConsumerBaseV2(vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _operator);
        WRAPPED_NATIVE_TOKEN = wrappedNativeToken;
        KEY_HASH = keyHash;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        SUBSCRIPTION_ID = subscriptionId;
        TRANSFER_MANAGER = ITransferManager(_transferManager);

        _updateProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function addCave(
        uint256 enterAmount,
        address enterCurrency,
        uint8 playersPerRound,
        uint40 roundDuration,
        uint16 protocolFeeBp
    ) external returns (uint256 caveId) {
        _validateIsOwner();

        if (playersPerRound < 2) {
            revert InsufficientNumberOfPlayers();
        }

        if (playersPerRound > MAXIMUM_NUMBER_OF_PLAYERS_PER_ROUND) {
            revert ExceedsMaximumNumberOfPlayersPerRound();
        }

        if (protocolFeeBp > 2_500) {
            revert ProtocolFeeBasisPointsTooHigh();
        }

        unchecked {
            if (
                (enterAmount - ((enterAmount * protocolFeeBp) / ONE_HUNDRED_PERCENT_IN_BASIS_POINTS)) %
                    (playersPerRound - 1) !=
                0
            ) {
                revert IndivisibleEnterAmount();
            }
        }

        if (roundDuration < MINIMUM_ROUND_DURATION || roundDuration > MAXIMUM_ROUND_DURATION) {
            revert InvalidRoundDuration();
        }

        caveId = nextCaveId;

        caves[caveId].enterAmount = enterAmount;
        caves[caveId].enterCurrency = enterCurrency;
        caves[caveId].playersPerRound = playersPerRound;
        caves[caveId].roundDuration = roundDuration;
        caves[caveId].protocolFeeBp = protocolFeeBp;
        caves[caveId].isActive = true;

        _open({caveId: caveId, roundId: 1});

        unchecked {
            ++nextCaveId;
        }

        emit CaveAdded(caveId, enterAmount, enterCurrency, roundDuration, playersPerRound, protocolFeeBp);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function removeCave(uint256 caveId) external {
        _validateIsOwner();

        Cave storage cave = caves[caveId];
        if (cave.roundsCount < cave.lastCommittedRoundId) {
            revert RoundsIncomplete();
        }

        caves[caveId].isActive = false;
        emit CaveRemoved(caveId);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function commit(CommitmentCalldata[] calldata commitments) external {
        _validateIsOperator();
        uint256 commitmentsLength = commitments.length;
        for (uint256 i; i < commitmentsLength; ) {
            uint256 caveId = commitments[i].caveId;
            Cave storage cave = caves[caveId];
            if (!cave.isActive) {
                revert InactiveCave();
            }

            uint256 startingRoundId = cave.lastCommittedRoundId + 1;

            bytes32[] calldata perCaveCommitments = commitments[i].commitments;
            uint256 perCaveCommitmentsLength = perCaveCommitments.length;

            for (uint256 j; j < perCaveCommitmentsLength; ) {
                uint256 roundId = startingRoundId + j;
                bytes32 commitment = perCaveCommitments[j];

                if (commitment == bytes32(0)) {
                    revert InvalidCommitment(caveId, roundId);
                }

                rounds[caveId][roundId].commitment = commitment;

                unchecked {
                    ++j;
                }
            }

            cave.lastCommittedRoundId = uint40(startingRoundId + perCaveCommitmentsLength - 1);

            unchecked {
                ++i;
            }
        }

        emit CommitmentsSubmitted(commitments);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external {
        _validateIsOwner();
        _updateProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @inheritdoc IPokeTheBear
     * @notice As rounds to enter are in numerical order and cannot be skipped,
               entering multiple rounds can revert when a round in between is already filled.
               Resolve by sending multiple transactions of consecutive rounds if such issue exists.
               Fee on transfer tokens will not be supported.
     * @dev Players can still deposit into the round past the cutoff time. Only when other players start withdrawing
     *      or deposit into the next round, the current round will be cancelled and no longer accept deposits.
     */
    function enter(
        uint256 caveId,
        uint256 startingRoundId,
        uint256 numberOfRounds
    ) external payable nonReentrant whenNotPaused {
        Cave storage cave = caves[caveId];

        address enterCurrency = cave.enterCurrency;
        uint256 enterAmount = cave.enterAmount * numberOfRounds;

        if (enterCurrency == address(0)) {
            if (msg.value != enterAmount) {
                revert InvalidEnterAmount();
            }
        } else {
            if (msg.value != 0) {
                revert InvalidEnterCurrency();
            }
            TRANSFER_MANAGER.transferERC20(enterCurrency, msg.sender, address(this), enterAmount);
        }

        _enter(caveId, startingRoundId, numberOfRounds);
    }

    /**
     * @inheritdoc IPokeTheBear
     * @dev Player index starts from 1 as the array has a fixed length of 32 and
     *      0 is used to indicate an empty slot.
     */
    function reveal(uint256 requestId, uint256 playerIndices, bytes32 salt) external whenNotPaused {
        RandomnessRequest storage randomnessRequest = randomnessRequests[requestId];
        uint256 caveId = randomnessRequest.caveId;
        uint256 roundId = randomnessRequest.roundId;

        Round storage round = rounds[caveId][roundId];
        if (round.status != RoundStatus.Drawn) {
            revert InvalidRoundStatus();
        }

        if (keccak256(abi.encodePacked(playerIndices, salt)) != round.commitment) {
            revert HashedPlayerIndicesDoesNotMatchCommitment();
        }

        uint256 numberOfPlayers = round.players.length;
        uint256 losingIndex = (randomnessRequest.randomWord % numberOfPlayers) + 1;

        // Check numbers are nonrepeating and within the range
        uint256 playerIndicesBitmap;
        for (uint256 i; i < numberOfPlayers; ) {
            uint8 playerIndex = uint8(playerIndices >> (i * 8));

            // Player index starts from 1
            if (playerIndex == 0 || playerIndex > numberOfPlayers) {
                revert InvalidPlayerIndex(caveId, roundId);
            }

            uint256 bitmask = 1 << playerIndex;

            if (playerIndicesBitmap & bitmask != 0) {
                revert RepeatingPlayerIndex();
            }

            playerIndicesBitmap |= bitmask;

            round.playerIndices[i] = playerIndex;

            if (playerIndex == losingIndex) {
                round.players[i].isLoser = true;
            }

            unchecked {
                ++i;
            }
        }

        round.salt = salt;
        round.status = RoundStatus.Revealed;

        emit RoundStatusUpdated(caveId, roundId, RoundStatus.Revealed);

        Cave storage cave = caves[caveId];
        _transferTokens(
            protocolFeeRecipient,
            cave.enterCurrency,
            (cave.enterAmount * cave.protocolFeeBp) / ONE_HUNDRED_PERCENT_IN_BASIS_POINTS
        );

        _open(caveId, _unsafeAdd(roundId, 1));
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function refund(WithdrawalCalldata[] calldata refundCalldataArray) external nonReentrant whenNotPaused {
        TransferAccumulator memory transferAccumulator;
        uint256 refundCount = refundCalldataArray.length;

        Withdrawal[] memory withdrawalEventData = new Withdrawal[](refundCount);

        for (uint256 i; i < refundCount; ) {
            WithdrawalCalldata calldata refundCalldata = refundCalldataArray[i];
            uint256 caveId = refundCalldata.caveId;
            Cave storage cave = caves[caveId];
            uint256 roundsCount = refundCalldata.playerDetails.length;

            Withdrawal memory withdrawal = withdrawalEventData[i];
            withdrawal.caveId = caveId;
            withdrawal.roundIds = new uint256[](roundsCount);

            for (uint256 j; j < roundsCount; ) {
                PlayerWithdrawalCalldata calldata playerDetails = refundCalldata.playerDetails[j];
                uint256 roundId = playerDetails.roundId;

                Round storage round = rounds[caveId][roundId];
                RoundStatus roundStatus = round.status;
                uint256 currentNumberOfPlayers = round.players.length;

                {
                    if (roundStatus < RoundStatus.Revealed) {
                        if (!_cancellable(round, roundStatus, cave.playersPerRound, currentNumberOfPlayers)) {
                            revert InvalidRoundStatus();
                        }
                        _cancel(caveId, roundId);
                    }

                    uint256 playerIndex = playerDetails.playerIndex;
                    if (playerIndex >= currentNumberOfPlayers) {
                        revert InvalidPlayerIndex(caveId, roundId);
                    }

                    Player storage player = round.players[playerIndex];
                    _validatePlayerCanWithdraw(caveId, roundId, player);
                    player.withdrawn = true;
                }

                withdrawal.roundIds[j] = roundId;

                unchecked {
                    ++j;
                }
            }

            _accumulateOrTransferTokenOut(cave.enterAmount * roundsCount, cave.enterCurrency, transferAccumulator);

            unchecked {
                ++i;
            }
        }

        if (transferAccumulator.amount != 0) {
            _transferTokens(msg.sender, transferAccumulator.tokenAddress, transferAccumulator.amount);
        }

        emit DepositsRefunded(withdrawalEventData, msg.sender);
    }

    /**
     * @inheritdoc IPokeTheBear
     * @dev If a player chooses to rollover his prizes, only the principal is rolled over. The profit is
     *      always sent back to the player.
     */
    function rollover(RolloverCalldata[] calldata rolloverCalldataArray) external payable nonReentrant whenNotPaused {
        TransferAccumulator memory entryAccumulator;
        TransferAccumulator memory prizeAccumulator;
        Rollover[] memory rolloverEventData = new Rollover[](rolloverCalldataArray.length);

        uint256 msgValueLeft = msg.value;
        for (uint256 i; i < rolloverCalldataArray.length; ) {
            RolloverCalldata calldata rolloverCalldata = rolloverCalldataArray[i];
            uint256 roundsCount = rolloverCalldata.playerDetails.length;
            if (roundsCount == 0) {
                revert InvalidPlayerDetails();
            }

            uint256 caveId = rolloverCalldata.caveId;
            Cave storage cave = caves[caveId];
            uint256 numberOfExtraRoundsToEnter = rolloverCalldata.numberOfExtraRoundsToEnter;
            address enterCurrency = cave.enterCurrency;

            // Enter extra rounds
            if (numberOfExtraRoundsToEnter != 0) {
                if (enterCurrency == address(0)) {
                    msgValueLeft -= cave.enterAmount * numberOfExtraRoundsToEnter;
                } else {
                    if (enterCurrency == entryAccumulator.tokenAddress) {
                        entryAccumulator.amount += cave.enterAmount * numberOfExtraRoundsToEnter;
                    } else {
                        if (entryAccumulator.amount != 0) {
                            TRANSFER_MANAGER.transferERC20(
                                entryAccumulator.tokenAddress,
                                msg.sender,
                                address(this),
                                entryAccumulator.amount
                            );
                        }

                        entryAccumulator.tokenAddress = enterCurrency;
                        entryAccumulator.amount = cave.enterAmount * numberOfExtraRoundsToEnter;
                    }
                }
            }

            Rollover memory rolloverEvent = rolloverEventData[i];
            rolloverEvent.caveId = caveId;
            rolloverEvent.rolledOverRoundIds = new uint256[](roundsCount);

            uint256 prizeAmount;

            for (uint256 j; j < roundsCount; ) {
                PlayerWithdrawalCalldata calldata playerDetails = rolloverCalldata.playerDetails[j];

                RoundStatus roundStatus = _handleRolloverRound(playerDetails, caveId, cave.playersPerRound);

                if (roundStatus == RoundStatus.Revealed) {
                    prizeAmount += _prizeAmount(cave);
                }

                rolloverEvent.rolledOverRoundIds[j] = playerDetails.roundId;

                unchecked {
                    ++j;
                }
            }

            uint256 startingRoundId = rolloverCalldata.startingRoundId;
            rolloverEvent.rollingOverToRoundIdStart = startingRoundId;

            _enter({
                caveId: caveId,
                startingRoundId: startingRoundId,
                numberOfRounds: roundsCount + numberOfExtraRoundsToEnter
            });

            if (prizeAmount != 0) {
                _accumulateOrTransferTokenOut(prizeAmount, enterCurrency, prizeAccumulator);
            }

            unchecked {
                ++i;
            }
        }

        if (msgValueLeft != 0) {
            revert InvalidEnterAmount();
        }

        if (entryAccumulator.amount != 0) {
            TRANSFER_MANAGER.transferERC20(
                entryAccumulator.tokenAddress,
                msg.sender,
                address(this),
                entryAccumulator.amount
            );
        }

        if (prizeAccumulator.amount != 0) {
            _transferTokens(msg.sender, prizeAccumulator.tokenAddress, prizeAccumulator.amount);
        }

        emit DepositsRolledOver(rolloverEventData, msg.sender);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function claimPrizes(WithdrawalCalldata[] calldata claimPrizeCalldataArray) external nonReentrant whenNotPaused {
        TransferAccumulator memory transferAccumulator;
        uint256 claimPrizeCount = claimPrizeCalldataArray.length;

        Withdrawal[] memory withdrawalEventData = new Withdrawal[](claimPrizeCount);

        for (uint256 i; i < claimPrizeCount; ) {
            WithdrawalCalldata calldata claimPrizeCalldata = claimPrizeCalldataArray[i];
            uint256 caveId = claimPrizeCalldata.caveId;

            Cave storage cave = caves[caveId];
            uint256 roundAmount = cave.enterAmount + _prizeAmount(cave);

            PlayerWithdrawalCalldata[] calldata playerDetailsArray = claimPrizeCalldata.playerDetails;
            uint256 roundsCount = playerDetailsArray.length;

            Withdrawal memory withdrawal = withdrawalEventData[i];
            withdrawal.caveId = caveId;
            withdrawal.roundIds = new uint256[](roundsCount);

            for (uint256 j; j < roundsCount; ) {
                PlayerWithdrawalCalldata calldata playerDetails = playerDetailsArray[j];
                uint256 roundId = playerDetails.roundId;

                Round storage round = rounds[caveId][roundId];
                if (round.status != RoundStatus.Revealed) {
                    revert InvalidRoundStatus();
                }

                Player storage player = round.players[playerDetails.playerIndex];
                _validatePlayerCanWithdraw(caveId, roundId, player);

                player.withdrawn = true;

                withdrawal.roundIds[j] = roundId;

                unchecked {
                    ++j;
                }
            }

            _accumulateOrTransferTokenOut(roundAmount * roundsCount, cave.enterCurrency, transferAccumulator);

            unchecked {
                ++i;
            }
        }

        if (transferAccumulator.amount != 0) {
            _transferTokens(msg.sender, transferAccumulator.tokenAddress, transferAccumulator.amount);
        }

        emit PrizesClaimed(withdrawalEventData, msg.sender);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function cancel(uint256 caveId) external nonReentrant {
        Cave storage cave = caves[caveId];
        uint40 roundsCount = cave.roundsCount;
        Round storage round = rounds[caveId][roundsCount];
        if (!_cancellable(round, round.status, cave.playersPerRound, round.players.length)) {
            revert NotCancellable();
        }
        _cancel(caveId, roundsCount);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function cancel(uint256 caveId, uint256 numberOfRounds) external nonReentrant whenPaused {
        _validateIsOwner();

        Cave storage cave = caves[caveId];
        uint256 startingRoundId = cave.roundsCount;
        uint256 lastRoundId = startingRoundId + numberOfRounds - 1;

        if (numberOfRounds == 0 || lastRoundId > cave.lastCommittedRoundId) {
            revert NotCancellable();
        }

        for (uint256 roundId = startingRoundId; roundId <= lastRoundId; ) {
            rounds[caveId][roundId].status = RoundStatus.Cancelled;
            unchecked {
                ++roundId;
            }
        }

        cave.roundsCount = uint40(lastRoundId);

        emit RoundsCancelled(caveId, startingRoundId, numberOfRounds);
    }

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
        )
    {
        Round memory round = rounds[caveId][roundId];
        return (
            round.status,
            round.cutoffTime,
            round.drawnAt,
            round.commitment,
            round.salt,
            round.playerIndices,
            round.players
        );
    }

    /**
     * @dev Checks if the round is cancellable. A round is cancellable if its status is Cancelled,
     *      its status is Open but it has passed its cutoff time, its status is Drawing but Chainlink VRF
     *      callback did not happen on time, or its status is Drawn but the result was not revealed.
     * @param caveId The ID of the cave.
     * @param roundId The ID of the round.
     */
    function cancellable(uint256 caveId, uint256 roundId) external view returns (bool) {
        Round storage round = rounds[caveId][roundId];
        return _cancellable(round, round.status, caves[caveId].playersPerRound, round.players.length);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function togglePaused() external {
        _validateIsOwner();
        paused() ? _unpause() : _pause();
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function isPlayerInRound(uint256 caveId, uint256 roundId, address player) public view returns (bool) {
        uint256 bucket = roundId >> 8;
        uint256 slot = 1 << (roundId & 0xff);
        return playerParticipations[player][caveId][bucket] & slot != 0;
    }

    /**
     * @param requestId The ID of the request
     * @param randomWords The random words returned by Chainlink
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (randomnessRequests[requestId].exists) {
            uint256 caveId = randomnessRequests[requestId].caveId;
            uint256 roundId = randomnessRequests[requestId].roundId;

            Round storage round = rounds[caveId][roundId];

            if (round.status == RoundStatus.Drawing) {
                round.status = RoundStatus.Drawn;
                randomnessRequests[requestId].randomWord = randomWords[0];

                emit RoundStatusUpdated(caveId, roundId, RoundStatus.Drawn);
            }
        }
    }

    /**
     * @dev This function is used to enter rounds, charging is done outside of this function.
     * @param caveId The ID of the cave.
     * @param startingRoundId The ID of the starting round.
     * @param numberOfRounds The number of rounds to enter.
     */
    function _enter(uint256 caveId, uint256 startingRoundId, uint256 numberOfRounds) private {
        if (startingRoundId == 0 || numberOfRounds == 0) {
            revert InvalidRoundParameters();
        }

        Cave storage cave = caves[caveId];

        if (!cave.isActive) {
            revert InactiveCave();
        }

        uint256 endingRoundIdPlusOne = startingRoundId + numberOfRounds;

        if (_unsafeSubtract(endingRoundIdPlusOne, 1) > cave.lastCommittedRoundId) {
            revert CommitmentNotAvailable();
        }

        Round storage startingRound = rounds[caveId][startingRoundId];
        // We just need to check the first round's status. If the first round is open,
        // subsequent rounds will not be drawn/cancelled as well.
        RoundStatus startingRoundStatus = startingRound.status;
        if (startingRoundStatus > RoundStatus.Open) {
            revert RoundCannotBeEntered(caveId, startingRoundId);
        }

        uint8 playersPerRound = cave.playersPerRound;

        if (startingRoundStatus == RoundStatus.None) {
            if (startingRoundId > 1) {
                uint256 lastRoundId = _unsafeSubtract(startingRoundId, 1);
                Round storage lastRound = rounds[caveId][lastRoundId];
                if (_cancellable(lastRound, lastRound.status, playersPerRound, lastRound.players.length)) {
                    _cancel(caveId, lastRoundId);
                    // The current round is now open (_cancel calls _open), we can manually change startingRoundStatus without touching the storage.
                    startingRoundStatus = RoundStatus.Open;
                }
            }
        }

        for (uint256 roundId = startingRoundId; roundId < endingRoundIdPlusOne; ) {
            if (isPlayerInRound(caveId, roundId, msg.sender)) {
                revert PlayerAlreadyParticipated(caveId, roundId, msg.sender);
            }
            // Starting round already exists from outside the loop so we can reuse it for gas efficiency.
            Round storage round = roundId == startingRoundId ? startingRound : rounds[caveId][roundId];
            uint256 newNumberOfPlayers = _unsafeAdd(round.players.length, 1);
            // This is not be a problem for the current open round, but this
            // can be a problem for future rounds.
            if (newNumberOfPlayers > playersPerRound) {
                revert RoundCannotBeEntered(caveId, roundId);
            }

            round.players.push(Player({addr: msg.sender, isLoser: false, withdrawn: false}));
            _markPlayerInRound(caveId, roundId, msg.sender);

            // Start countdown only for the current round and only if it is the first player.
            if (roundId == startingRoundId) {
                if (startingRoundStatus == RoundStatus.Open) {
                    if (round.cutoffTime == 0) {
                        round.cutoffTime = uint40(block.timestamp) + cave.roundDuration;
                    }

                    if (newNumberOfPlayers == playersPerRound) {
                        _draw(caveId, roundId);
                    }
                }
            }

            unchecked {
                ++roundId;
            }
        }

        emit RoundsEntered(caveId, startingRoundId, numberOfRounds, msg.sender);
    }

    /**
     * @param caveId The ID of the cave.
     * @param roundId The ID of the round to draw.
     */
    function _draw(uint256 caveId, uint256 roundId) private {
        rounds[caveId][roundId].status = RoundStatus.Drawing;
        rounds[caveId][roundId].drawnAt = uint40(block.timestamp);

        uint256 requestId = VRF_COORDINATOR.requestRandomWords({
            keyHash: KEY_HASH,
            subId: SUBSCRIPTION_ID,
            minimumRequestConfirmations: uint16(3),
            callbackGasLimit: uint32(500_000),
            numWords: uint32(1)
        });

        if (randomnessRequests[requestId].exists) {
            revert RandomnessRequestAlreadyExists();
        }

        randomnessRequests[requestId].exists = true;
        randomnessRequests[requestId].caveId = uint40(caveId);
        randomnessRequests[requestId].roundId = uint40(roundId);

        emit RandomnessRequested(caveId, roundId, requestId);
        emit RoundStatusUpdated(caveId, roundId, RoundStatus.Drawing);
    }

    /**
     * @dev This function cancels the current round and opens the next round.
     * @param caveId The ID of the cave.
     * @param roundId The ID of the round to cancel.
     */
    function _cancel(uint256 caveId, uint256 roundId) private {
        rounds[caveId][roundId].status = RoundStatus.Cancelled;
        emit RoundStatusUpdated(caveId, roundId, RoundStatus.Cancelled);
        _open(caveId, _unsafeAdd(roundId, 1));
    }

    /**
     * @dev This function opens a new round.
     *      If the new round is already fully filled, it will be drawn immediately.
     *      If the round is partially filled, the countdown starts.
     * @param caveId The ID of the cave.
     * @param roundId The ID of the round to open.
     */
    function _open(uint256 caveId, uint256 roundId) private {
        Round storage round = rounds[caveId][roundId];
        uint256 playersCount = round.players.length;
        Cave storage cave = caves[caveId];

        if (playersCount == cave.playersPerRound) {
            _draw(caveId, roundId);
        } else {
            round.status = RoundStatus.Open;
            cave.roundsCount = uint40(roundId);
            emit RoundStatusUpdated(caveId, roundId, RoundStatus.Open);

            if (playersCount != 0) {
                round.cutoffTime = uint40(block.timestamp) + cave.roundDuration;
            }
        }
    }

    /**
     * @param playerDetails Information about the player to rollover.
     * @param caveId The ID of the cave.
     * @param playersPerRound The number of required players.
     */
    function _handleRolloverRound(
        PlayerWithdrawalCalldata calldata playerDetails,
        uint256 caveId,
        uint8 playersPerRound
    ) private returns (RoundStatus roundStatus) {
        uint256 roundId = playerDetails.roundId;
        uint256 playerIndex = playerDetails.playerIndex;
        Round storage round = rounds[caveId][roundId];
        roundStatus = round.status;
        uint256 currentNumberOfPlayers = round.players.length;

        if (roundStatus < RoundStatus.Revealed) {
            if (!_cancellable(round, roundStatus, playersPerRound, currentNumberOfPlayers)) {
                revert InvalidRoundStatus();
            }
            _cancel(caveId, roundId);
        }

        if (playerIndex >= currentNumberOfPlayers) {
            revert InvalidPlayerIndex(caveId, roundId);
        }

        Player storage player = round.players[playerIndex];
        _validatePlayerCanWithdraw(caveId, roundId, player);
        player.withdrawn = true;
    }

    /**
     * @param recipient The recipient of the transfer.
     * @param currency The transfer currency.
     * @param amount The transfer amount.
     */
    function _transferTokens(address recipient, address currency, uint256 amount) private {
        if (currency == address(0)) {
            _transferETHAndWrapIfFailWithGasLimit(WRAPPED_NATIVE_TOKEN, recipient, amount, gasleft());
        } else {
            _executeERC20DirectTransfer(currency, recipient, amount);
        }
    }

    /**
     * @param tokenAmount The amount of tokens to accumulate.
     * @param tokenAddress The token address to accumulate.
     * @param transferAccumulator The transfer accumulator state so far.
     */
    function _accumulateOrTransferTokenOut(
        uint256 tokenAmount,
        address tokenAddress,
        TransferAccumulator memory transferAccumulator
    ) private {
        if (tokenAddress == transferAccumulator.tokenAddress) {
            transferAccumulator.amount += tokenAmount;
        } else {
            if (transferAccumulator.amount != 0) {
                _transferTokens(msg.sender, transferAccumulator.tokenAddress, transferAccumulator.amount);
            }

            transferAccumulator.tokenAddress = tokenAddress;
            transferAccumulator.amount = tokenAmount;
        }
    }

    /**
     * @notice Marks a player as participated in a round.
     * @dev A round starts with the ID 1 and the bitmap starts with the index 0, therefore we need to subtract 1.
     * @param caveId The ID of the cave.
     * @param roundId The ID of the round.
     * @param player The address of the player.
     */
    function _markPlayerInRound(uint256 caveId, uint256 roundId, address player) private {
        uint256 bucket = roundId >> 8;
        uint256 slot = 1 << (roundId & 0xff);
        playerParticipations[player][caveId][bucket] |= slot;
    }

    /**
     * @notice Checks if the round data fulfills an expired open round.
     * @param roundStatus The status of the round.
     * @param cutoffTime The cutoff time of the round.
     * @param currentNumberOfPlayers The current number of players in the round.
     * @param playersPerRound The maximum number of players in a round.
     */
    function _isExpiredOpenRound(
        RoundStatus roundStatus,
        uint40 cutoffTime,
        uint256 currentNumberOfPlayers,
        uint8 playersPerRound
    ) private view returns (bool) {
        return
            roundStatus == RoundStatus.Open &&
            cutoffTime != 0 &&
            block.timestamp >= cutoffTime &&
            currentNumberOfPlayers < playersPerRound;
    }

    /**
     * @notice Checks if the round is pending VRF or commitment reveal for too long. We tolerate a delay of up to 1 day.
     * @param roundStatus The status of the round.
     * @param round The round to check.
     */
    function _pendingVRFOrRevealForTooLong(RoundStatus roundStatus, Round storage round) private view returns (bool) {
        return
            (roundStatus == RoundStatus.Drawing || roundStatus == RoundStatus.Drawn) &&
            block.timestamp >= round.drawnAt + 1 days;
    }

    /**
     * @dev player.isLoser is a check for claimPrize only, but it is also useful to act as an invariant for refund.
     * @param caveId The ID of the cave.
     * @param roundId The ID of the round.
     * @param player The player.
     */
    function _validatePlayerCanWithdraw(uint256 caveId, uint256 roundId, Player storage player) private view {
        if (player.isLoser || player.withdrawn || player.addr != msg.sender) {
            revert IneligibleToWithdraw(caveId, roundId);
        }
    }

    /**
     * @dev Checks if the round is cancellable. A round is cancellable if its status is Cancelled,
     *      its status is Open but it has passed its cutoff time, its status is Drawing but Chainlink VRF
     *      callback did not happen on time, or its status is Drawn but the result was not revealed.
     * @param round The round to check.
     * @param roundStatus The status of the round.
     * @param playersPerRound The maximum number of players in the round.
     * @param currentNumberOfPlayers The current number of players in the round.
     */
    function _cancellable(
        Round storage round,
        RoundStatus roundStatus,
        uint8 playersPerRound,
        uint256 currentNumberOfPlayers
    ) private view returns (bool) {
        return
            _isExpiredOpenRound(roundStatus, round.cutoffTime, currentNumberOfPlayers, playersPerRound) ||
            _pendingVRFOrRevealForTooLong(roundStatus, round);
    }

    /**
     * @param _protocolFeeRecipient The new protocol fee recipient address
     */
    function _updateProtocolFeeRecipient(address _protocolFeeRecipient) internal {
        if (_protocolFeeRecipient == address(0)) {
            revert InvalidValue();
        }
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    /**
     * @notice Calculates the prize amount.
     * @param cave The cave to calculate the prize amount.
     */
    function _prizeAmount(Cave storage cave) private view returns (uint256) {
        return
            (cave.enterAmount * (_unsafeSubtract(ONE_HUNDRED_PERCENT_IN_BASIS_POINTS, cave.protocolFeeBp))) /
            ONE_HUNDRED_PERCENT_IN_BASIS_POINTS /
            _unsafeSubtract(cave.playersPerRound, 1);
    }

    /**
     * Unsafe math functions.
     */

    function _unsafeAdd(uint256 a, uint256 b) private pure returns (uint256) {
        unchecked {
            return a + b;
        }
    }

    function _unsafeSubtract(uint256 a, uint256 b) private pure returns (uint256) {
        unchecked {
            return a - b;
        }
    }

    function _validateIsOwner() private view {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NotOwner();
        }
    }

    function _validateIsOperator() private view {
        if (!hasRole(OPERATOR_ROLE, msg.sender)) {
            revert NotOperator();
        }
    }
}
