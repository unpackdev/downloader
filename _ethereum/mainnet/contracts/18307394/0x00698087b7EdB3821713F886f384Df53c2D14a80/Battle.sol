// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./LowLevelWETH.sol";
import "./LowLevelERC20Transfer.sol";
import "./LowLevelERC721Transfer.sol";
import "./LowLevelERC1155Transfer.sol";
import "./OwnableTwoSteps.sol";
import "./PackableReentrancyGuard.sol";
import "./Pausable.sol";

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

import "./Arrays.sol";

import "./WinningEntrySearchLogic.sol";

import "./IBattle.sol";

/**
 * @title Battle v1.0
 * @notice This contract allows anyone to permissionlessly host battles on BadDogs.io
 * @author BadDogs team
 */
contract Battle is
    IBattle,
    LowLevelWETH,
    LowLevelERC20Transfer,
    LowLevelERC721Transfer,
    LowLevelERC1155Transfer,
    VRFConsumerBaseV2,
    OwnableTwoSteps,
    PackableReentrancyGuard,
    Pausable,
    WinningEntrySearchLogic
{
    using Arrays for uint256[];

    address public immutable WETH;

    uint256 public constant ONE_HOUR = 3_600 seconds;
    uint256 public constant ONE_WEEK = 604_800 seconds;

    /**
     * @notice 100% in basis points.
     */
    uint256 public constant ONE_HUNDRED_PERCENT_BP = 10_000;

    /**
     * @notice The number of battles created.
     */
    uint256 public battlesCount;

    /**
     * @notice The battles created.
     * @dev The key is the battle ID.
     */
    mapping(uint256 => Battle) public battles;

    /**
     * @notice The participants stats of the battles.
     * @dev The key is the battle ID and the nested key is the participant address.
     */
    mapping(uint256 => mapping(address => ParticipantStats))
        public battlesParticipantsStats;

    /**
     * @notice It checks whether the currency is allowed.
     */
    mapping(address => bool) public isCurrencyAllowed;

    /**
     * @notice The maximum number of prizes per battle.
     *         Each individual ERC-721 counts as one prize.
     *         Each ETH/ERC-20/ERC-1155 with winnersCount > 1 counts as one prize.
     */
    uint256 public constant MAXIMUM_NUMBER_OF_PRIZES_PER_BATTLE = 20;

    /**
     * @notice The maximum number of winners per battle.
     */
    uint40 public constant MAXIMUM_NUMBER_OF_WINNERS_PER_BATTLE = 110;

    /**
     * @notice A Chainlink node should wait for 3 confirmations before responding.
     */
    uint16 public constant REQUEST_CONFIRMATIONS = 3;

    /**
     * @notice The key hash of the Chainlink VRF.
     */
    bytes32 public immutable KEY_HASH;

    /**
     * @notice The subscription ID of the Chainlink VRF.
     */
    uint64 public immutable SUBSCRIPTION_ID;

    /**
     * @notice The Chainlink VRF coordinator.
     */
    VRFCoordinatorV2Interface public immutable VRF_COORDINATOR;

    /**
     * @notice The randomness requests.
     * @dev The key is the request ID returned by Chainlink.
     */
    mapping(uint256 => RandomnessRequest) public randomnessRequests;

    /**
     * @notice The maximum protocol fee in basis points, which is 25%.
     */
    uint16 public constant MAXIMUM_PROTOCOL_FEE_BP = 2_500;

    /**
     * @notice The protocol fee recipient.
     */
    address public protocolFeeRecipient;

    /**
     * @notice The protocol fee in basis points.
     */
    uint16 public protocolFeeBp;

    /**
     * @notice The claimable fees of the protocol fee recipient.
     * @dev The key is the currency address.
     */
    mapping(address => uint256) public protocolFeeRecipientClaimableFees;

    /**
     * @notice The number of pricing options per battle.
     */
    uint256 public constant PRICING_OPTIONS_PER_BATTLE = 5;

    /**
     * @param _weth The WETH address
     * @param _keyHash Chainlink VRF key hash
     * @param _subscriptionId Chainlink VRF subscription ID
     * @param _vrfCoordinator Chainlink VRF coordinator address
     * @param _owner The owner of the contract
     * @param _protocolFeeRecipient The recipient of the protocol fees
     * @param _protocolFeeBp The protocol fee in basis points
     */
    constructor(
        address _weth,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address _owner,
        address _protocolFeeRecipient,
        uint16 _protocolFeeBp
    ) VRFConsumerBaseV2(_vrfCoordinator) OwnableTwoSteps(_owner) {
        _setProtocolFeeBp(_protocolFeeBp);
        _setProtocolFeeRecipient(_protocolFeeRecipient);

        WETH = _weth;
        KEY_HASH = _keyHash;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        SUBSCRIPTION_ID = _subscriptionId;
    }

    /**
     * @inheritdoc IBattle
     * @dev This function can still be called when the contract is paused because the battle creator
     *      would not be able to deposit prizes and open the battle anyway. The restriction to disallow
     *      battles creation when the contract is paused will be enforced in the frontend.
     */
    function createBattle(
        CreateBattleCalldata calldata params
    ) external payable nonReentrant whenNotPaused returns (uint256 battleId) {
        uint40 cutoffTime = params.cutoffTime;
        if (
            _unsafeAdd(block.timestamp, ONE_HOUR) > cutoffTime ||
            cutoffTime > _unsafeAdd(block.timestamp, ONE_WEEK)
        ) {
            revert InvalidCutoffTime();
        }

        uint16 agreedProtocolFeeBp = params.protocolFeeBp;
        if (agreedProtocolFeeBp != protocolFeeBp) {
            revert InvalidProtocolFeeBp();
        }

        address feeTokenAddress = params.feeTokenAddress;
        if (feeTokenAddress != address(0)) {
            if (!isCurrencyAllowed[feeTokenAddress]) {
                revert InvalidCurrency();
            }
        }

        unchecked {
            battleId = ++battlesCount;
        }

        uint256 prizesCount = params.prizes.length;
        if (
            prizesCount == 0 ||
            prizesCount > MAXIMUM_NUMBER_OF_PRIZES_PER_BATTLE
        ) {
            revert InvalidPrizesCount();
        }

        Battle storage battle = battles[battleId];

        uint40 cumulativeWinnersCount;
        uint8 currentPrizeTier;
        for (uint256 i; i < prizesCount; ) {
            Prize memory prize = params.prizes[i];
            if (prize.prizeTier < currentPrizeTier) {
                revert InvalidPrize();
            }
            _validatePrize(prize);

            uint256 expectedEthValue;

            TokenType prizeType = prize.prizeType;
            if (prizeType == TokenType.ERC721) {
                _executeERC721TransferFrom(
                    prize.prizeAddress,
                    msg.sender,
                    address(this),
                    prize.prizeId
                );
            } else if (prizeType == TokenType.ERC20) {
                _executeERC20TransferFrom(
                    prize.prizeAddress,
                    msg.sender,
                    address(this),
                    prize.prizeAmount * prize.winnersCount
                );
            } else if (prizeType == TokenType.ETH) {
                expectedEthValue += (prize.prizeAmount * prize.winnersCount);
            } else {
                _executeERC1155SafeTransferFrom(
                    prize.prizeAddress,
                    msg.sender,
                    address(this),
                    prize.prizeId,
                    prize.prizeAmount * prize.winnersCount
                );
            }
            cumulativeWinnersCount += prize.winnersCount;
            prize.cumulativeWinnersCount = cumulativeWinnersCount;
            currentPrizeTier = prize.prizeTier;
            battle.prizes.push(prize);

            unchecked {
                ++i;
            }
            _validateExpectedEthValueOrRefund(expectedEthValue);
        }

        uint40 minimumEntries = params.minimumEntries;
        if (
            cumulativeWinnersCount > minimumEntries ||
            cumulativeWinnersCount > MAXIMUM_NUMBER_OF_WINNERS_PER_BATTLE
        ) {
            revert InvalidWinnersCount();
        }

        _validateAndSetPricingOptions(battleId, params.pricingOptions);

        battle.owner = msg.sender;
        battle.isMinimumEntriesFixed = params.isMinimumEntriesFixed;
        battle.cutoffTime = cutoffTime;
        battle.minimumEntries = minimumEntries;
        battle.maximumEntriesPerParticipant = params
            .maximumEntriesPerParticipant;
        battle.protocolFeeBp = agreedProtocolFeeBp;
        battle.feeTokenAddress = feeTokenAddress;

        _setBattleStatus(battle, battleId, BattleStatus.Open);
    }

    /**
     * @dev This function is required in order for the contract to receive ERC-1155 tokens.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @inheritdoc IBattle
     */
    function enterBattles(
        EntryCalldata[] calldata entries
    ) external payable nonReentrant whenNotPaused {
        uint256 entriesCount = entries.length;
        uint208 expectedEthValue;
        for (uint256 i; i < entriesCount; ) {
            EntryCalldata calldata entry = entries[i];

            if (entry.pricingOptionIndex >= PRICING_OPTIONS_PER_BATTLE) {
                revert InvalidIndex();
            }

            uint256 battleId = entry.battleId;
            Battle storage battle = battles[battleId];

            _validateBattleStatus(battle, BattleStatus.Open);

            if (block.timestamp >= battle.cutoffTime) {
                revert CutoffTimeReached();
            }

            PricingOption memory pricingOption = battle.pricingOptions[
                entry.pricingOptionIndex
            ];

            uint40 newParticipantEntriesCount = battlesParticipantsStats[
                battleId
            ][msg.sender].entriesCount + pricingOption.entriesCount;
            if (
                newParticipantEntriesCount > battle.maximumEntriesPerParticipant
            ) {
                revert MaximumEntriesPerParticipantReached();
            }
            battlesParticipantsStats[battleId][msg.sender]
                .entriesCount = newParticipantEntriesCount;

            uint208 price = pricingOption.price;

            if (battle.feeTokenAddress == address(0)) {
                expectedEthValue += price;
            } else {
                _executeERC20TransferFrom(
                    battle.feeTokenAddress,
                    msg.sender,
                    address(this),
                    price
                );
            }

            uint40 currentEntryIndex;
            uint256 battleEntriesCount = battle.entries.length;
            if (battleEntriesCount == 0) {
                currentEntryIndex = uint40(
                    _unsafeSubtract(pricingOption.entriesCount, 1)
                );
            } else {
                currentEntryIndex =
                    battle
                        .entries[_unsafeSubtract(battleEntriesCount, 1)]
                        .currentEntryIndex +
                    pricingOption.entriesCount;
            }

            if (battle.isMinimumEntriesFixed) {
                if (currentEntryIndex >= battle.minimumEntries) {
                    revert MaximumEntriesReached();
                }
            }

            battle.entries.push(
                Entry({
                    currentEntryIndex: currentEntryIndex,
                    participant: msg.sender
                })
            );
            battle.claimableFees += price;

            battlesParticipantsStats[battleId][msg.sender].amountPaid += price;

            emit EntrySold(
                battleId,
                msg.sender,
                pricingOption.entriesCount,
                price
            );

            if (
                currentEntryIndex >= _unsafeSubtract(battle.minimumEntries, 1)
            ) {
                _drawWinners(battleId, battle);
            }

            unchecked {
                ++i;
            }
        }

        _validateExpectedEthValueOrRefund(expectedEthValue);
    }

    /**
     * @param _requestId The ID of the request
     * @param _randomWords The random words returned by Chainlink
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        if (randomnessRequests[_requestId].exists) {
            uint256 battleId = randomnessRequests[_requestId].battleId;
            Battle storage battle = battles[battleId];

            if (battle.status == BattleStatus.Drawing) {
                _setBattleStatus(
                    battle,
                    battleId,
                    BattleStatus.RandomnessFulfilled
                );
                // We ignore the most significant byte to pack the random word with `exists`
                randomnessRequests[_requestId].randomWord = uint248(
                    _randomWords[0]
                );
            }
        }
    }

    /**
     * @inheritdoc IBattle
     */
    function selectWinners(uint256 requestId) external {
        RandomnessRequest memory randomnessRequest = randomnessRequests[
            requestId
        ];
        if (!randomnessRequest.exists) {
            revert RandomnessRequestDoesNotExist();
        }

        uint256 battleId = randomnessRequest.battleId;
        Battle storage battle = battles[battleId];
        _validateBattleStatus(battle, BattleStatus.RandomnessFulfilled);

        _setBattleStatus(battle, battleId, BattleStatus.Drawn);

        Prize[] storage prizes = battle.prizes;
        uint256 prizesCount = prizes.length;
        uint256 winnersCount = prizes[prizesCount - 1].cumulativeWinnersCount;

        Entry[] memory entries = battle.entries;
        uint256 entriesCount = entries.length;
        uint256 currentEntryIndex = uint256(
            entries[entriesCount - 1].currentEntryIndex
        );

        uint256[] memory winningEntriesBitmap = new uint256[](
            (currentEntryIndex >> 8) + 1
        );

        uint256[] memory currentEntryIndexArray = new uint256[](entriesCount);
        for (uint256 i; i < entriesCount; ) {
            currentEntryIndexArray[i] = entries[i].currentEntryIndex;
            unchecked {
                ++i;
            }
        }

        uint256[] memory cumulativeWinnersCountArray = new uint256[](
            prizesCount
        );
        for (uint256 i; i < prizesCount; ) {
            cumulativeWinnersCountArray[i] = prizes[i].cumulativeWinnersCount;
            unchecked {
                ++i;
            }
        }

        uint256 randomWord = randomnessRequest.randomWord;

        for (uint256 i; i < winnersCount; ) {
            uint256 winningEntry = randomWord % (currentEntryIndex + 1);
            (
                winningEntry,
                winningEntriesBitmap
            ) = _incrementWinningEntryUntilThereIsNotADuplicate(
                currentEntryIndex,
                winningEntry,
                winningEntriesBitmap
            );

            battle.winners.push(
                Winner({
                    participant: entries[
                        currentEntryIndexArray.findUpperBound(winningEntry)
                    ].participant,
                    claimed: false,
                    prizeIndex: uint8(
                        cumulativeWinnersCountArray.findUpperBound(
                            _unsafeAdd(i, 1)
                        )
                    ),
                    entryIndex: uint40(winningEntry)
                })
            );

            randomWord = uint256(keccak256(abi.encodePacked(randomWord)));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IBattle
     */
    function claimPrizes(
        ClaimPrizesCalldata[] calldata claimPrizesCalldata
    ) external nonReentrant whenNotPaused {
        uint256 claimsCount = claimPrizesCalldata.length;
        for (uint256 i; i < claimsCount; ) {
            _claimPrizesPerBattle(claimPrizesCalldata[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IBattle
     */
    function claimProtocolFees(address currency) external onlyOwner {
        uint256 claimableFees = protocolFeeRecipientClaimableFees[currency];
        protocolFeeRecipientClaimableFees[currency] = 0;
        _transferFungibleTokens(currency, protocolFeeRecipient, claimableFees);
    }

    /**
     * @inheritdoc IBattle
     */
    function claimFees(uint256 battleId) external nonReentrant whenNotPaused {
        Battle storage battle = battles[battleId];
        _validateBattleStatus(battle, BattleStatus.Drawn);

        address battleOwner = battle.owner;
        if (msg.sender != battleOwner) {
            _validateCaller(owner);
        }

        uint208 claimableFees = battle.claimableFees;
        uint208 protocolFees = (claimableFees * uint208(battle.protocolFeeBp)) /
            uint208(ONE_HUNDRED_PERCENT_BP);
        unchecked {
            claimableFees -= protocolFees;
        }

        _setBattleStatus(battle, battleId, BattleStatus.Complete);

        battle.claimableFees = 0;

        address feeTokenAddress = battle.feeTokenAddress;
        _transferFungibleTokens(feeTokenAddress, battleOwner, claimableFees);

        if (protocolFees != 0) {
            protocolFeeRecipientClaimableFees[feeTokenAddress] += protocolFees;
        }

        emit FeesClaimed(battleId, claimableFees);
    }

    /**
     * @inheritdoc IBattle
     */
    function cancel(uint256 battleId) external nonReentrant whenNotPaused {
        Battle storage battle = battles[battleId];
        bool isOpen = battle.status == BattleStatus.Open;

        if (isOpen) {
            if (battle.cutoffTime > block.timestamp) {
                revert CutoffTimeNotReached();
            }
        } else {
            _validateBattleStatus(battle, BattleStatus.Created);
        }

        _setBattleStatus(
            battle,
            battleId,
            isOpen ? BattleStatus.Refundable : BattleStatus.Cancelled
        );
    }

    /**
     * @inheritdoc IBattle
     */
    function cancelAfterRandomnessRequest(
        uint256 battleId
    ) external onlyOwner nonReentrant {
        Battle storage battle = battles[battleId];

        _validateBattleStatus(battle, BattleStatus.Drawing);

        if (block.timestamp < battle.drawnAt + ONE_HOUR) {
            revert DrawExpirationTimeNotReached();
        }

        _setBattleStatus(battle, battleId, BattleStatus.Refundable);
    }

    /**
     * @inheritdoc IBattle
     */
    function withdrawPrizes(
        uint256 battleId
    ) external nonReentrant whenNotPaused {
        Battle storage battle = battles[battleId];
        _validateBattleStatus(battle, BattleStatus.Refundable);

        _setBattleStatus(battle, battleId, BattleStatus.Cancelled);

        uint256 prizesCount = battle.prizes.length;
        address battleOwner = battle.owner;
        for (uint256 i; i < prizesCount; ) {
            Prize storage prize = battle.prizes[i];
            _transferPrize({
                prize: prize,
                recipient: battleOwner,
                multiplier: uint256(prize.winnersCount)
            });

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IBattle
     * @dev Refundable and Cancelled are the only statuses that allow refunds.
     */
    function claimRefund(
        uint256[] calldata battleIds
    ) external nonReentrant whenNotPaused {
        uint256 count = battleIds.length;

        for (uint256 i; i < count; ) {
            uint256 battleId = battleIds[i];
            Battle storage battle = battles[battleId];

            if (battle.status < BattleStatus.Refundable) {
                revert InvalidStatus();
            }

            ParticipantStats storage stats = battlesParticipantsStats[battleId][
                msg.sender
            ];

            if (stats.refunded) {
                revert AlreadyRefunded();
            }

            stats.refunded = true;

            uint208 amountPaid = stats.amountPaid;
            _transferFungibleTokens(
                battle.feeTokenAddress,
                msg.sender,
                amountPaid
            );

            emit EntryRefunded(battleId, msg.sender, amountPaid);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IBattle
     */
    function setProtocolFeeRecipient(
        address _protocolFeeRecipient
    ) external onlyOwner {
        _setProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @inheritdoc IBattle
     */
    function setProtocolFeeBp(uint16 _protocolFeeBp) external onlyOwner {
        _setProtocolFeeBp(_protocolFeeBp);
    }

    /**
     * @inheritdoc IBattle
     */
    function updateCurrenciesStatus(
        address[] calldata currencies,
        bool isAllowed
    ) external onlyOwner {
        uint256 count = currencies.length;
        for (uint256 i; i < count; ) {
            isCurrencyAllowed[currencies[i]] = isAllowed;
            unchecked {
                ++i;
            }
        }
        emit CurrenciesStatusUpdated(currencies, isAllowed);
    }

    /**
     * @inheritdoc IBattle
     */
    function togglePaused() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /**
     * @inheritdoc IBattle
     */
    function getWinners(
        uint256 battleId
    ) external view returns (Winner[] memory winners) {
        winners = battles[battleId].winners;
    }

    /**
     * @inheritdoc IBattle
     */
    function getPrizes(
        uint256 battleId
    ) external view returns (Prize[] memory prizes) {
        prizes = battles[battleId].prizes;
    }

    /**
     * @inheritdoc IBattle
     */
    function getEntries(
        uint256 battleId
    ) external view returns (Entry[] memory entries) {
        entries = battles[battleId].entries;
    }

    /**
     * @inheritdoc IBattle
     */
    function getPricingOptions(
        uint256 battleId
    )
        external
        view
        returns (
            PricingOption[PRICING_OPTIONS_PER_BATTLE] memory pricingOptions
        )
    {
        pricingOptions = battles[battleId].pricingOptions;
    }

    /**
     * @param _protocolFeeRecipient The new protocol fee recipient address
     */
    function _setProtocolFeeRecipient(address _protocolFeeRecipient) private {
        if (_protocolFeeRecipient == address(0)) {
            revert InvalidProtocolFeeRecipient();
        }
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    /**
     * @param _protocolFeeBp The new protocol fee in basis points
     */
    function _setProtocolFeeBp(uint16 _protocolFeeBp) private {
        if (_protocolFeeBp > MAXIMUM_PROTOCOL_FEE_BP) {
            revert InvalidProtocolFeeBp();
        }
        protocolFeeBp = _protocolFeeBp;
        emit ProtocolFeeBpUpdated(_protocolFeeBp);
    }

    /**
     * @param battleId The ID of the battle.
     * @param pricingOptions The pricing options for the battle.
     */
    function _validateAndSetPricingOptions(
        uint256 battleId,
        PricingOption[PRICING_OPTIONS_PER_BATTLE] calldata pricingOptions
    ) private {
        for (uint256 i; i < PRICING_OPTIONS_PER_BATTLE; ) {
            PricingOption memory pricingOption = pricingOptions[i];

            uint40 entriesCount = pricingOption.entriesCount;
            uint208 price = pricingOption.price;

            if (i == 0) {
                if (entriesCount != 1 || price == 0) {
                    revert InvalidPricingOption();
                }
            } else {
                PricingOption memory lastPricingOption = pricingOptions[
                    _unsafeSubtract(i, 1)
                ];
                uint208 lastPrice = lastPricingOption.price;
                uint40 lastEntriesCount = lastPricingOption.entriesCount;

                if (
                    price % entriesCount != 0 ||
                    entriesCount <= lastEntriesCount ||
                    price <= lastPrice ||
                    price / entriesCount > lastPrice / lastEntriesCount
                ) {
                    revert InvalidPricingOption();
                }
            }

            battles[battleId].pricingOptions[i] = pricingOption;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @param prize The prize.
     */
    function _validatePrize(Prize memory prize) private view {
        if (prize.prizeType == TokenType.ERC721) {
            if (prize.prizeAmount != 1 || prize.winnersCount != 1) {
                revert InvalidPrize();
            }
        } else {
            if (prize.prizeType == TokenType.ERC20) {
                if (!isCurrencyAllowed[prize.prizeAddress]) {
                    revert InvalidCurrency();
                }
            }

            if (prize.prizeAmount == 0 || prize.winnersCount == 0) {
                revert InvalidPrize();
            }
        }
    }

    /**
     * @param prize The prize to transfer.
     * @param recipient The recipient of the prize.
     * @param multiplier The multiplier to apply to the prize amount.
     */
    function _transferPrize(
        Prize storage prize,
        address recipient,
        uint256 multiplier
    ) private {
        TokenType prizeType = prize.prizeType;
        address prizeAddress = prize.prizeAddress;
        if (prizeType == TokenType.ERC721) {
            _executeERC721TransferFrom(
                prizeAddress,
                address(this),
                recipient,
                prize.prizeId
            );
        } else if (prizeType == TokenType.ERC1155) {
            _executeERC1155SafeTransferFrom(
                prizeAddress,
                address(this),
                recipient,
                prize.prizeId,
                prize.prizeAmount * multiplier
            );
        } else {
            _transferFungibleTokens(
                prizeAddress,
                recipient,
                prize.prizeAmount * multiplier
            );
        }
    }

    /**
     * @param currency The currency to transfer.
     * @param recipient The recipient of the currency.
     * @param amount The amount of currency to transfer.
     */
    function _transferFungibleTokens(
        address currency,
        address recipient,
        uint256 amount
    ) private {
        if (currency == address(0)) {
            _transferETHAndWrapIfFailWithGasLimit(
                WETH,
                recipient,
                amount,
                gasleft()
            );
        } else {
            _executeERC20DirectTransfer(currency, recipient, amount);
        }
    }

    /**
     * @param claimPrizesCalldata The calldata for claiming prizes.
     */
    function _claimPrizesPerBattle(
        ClaimPrizesCalldata calldata claimPrizesCalldata
    ) private {
        uint256 battleId = claimPrizesCalldata.battleId;
        Battle storage battle = battles[battleId];
        BattleStatus status = battle.status;
        if (status != BattleStatus.Drawn) {
            _validateBattleStatus(battle, BattleStatus.Complete);
        }

        Winner[] storage winners = battle.winners;
        uint256[] calldata winnerIndices = claimPrizesCalldata.winnerIndices;
        uint256 winnersCount = winners.length;
        uint256 claimsCount = winnerIndices.length;
        for (uint256 i; i < claimsCount; ) {
            uint256 winnerIndex = winnerIndices[i];

            if (winnerIndex >= winnersCount) {
                revert InvalidIndex();
            }

            Winner storage winner = winners[winnerIndex];
            if (winner.claimed) {
                revert PrizeAlreadyClaimed();
            }
            _validateCaller(winner.participant);
            winner.claimed = true;

            Prize storage prize = battle.prizes[winner.prizeIndex];
            _transferPrize({
                prize: prize,
                recipient: msg.sender,
                multiplier: 1
            });

            unchecked {
                ++i;
            }
        }

        emit PrizesClaimed(battleId, winnerIndices);
    }

    /**
     * @param battleId The ID of the battle to draw winners for.
     * @param battle The battle to draw winners for.
     */
    function _drawWinners(uint256 battleId, Battle storage battle) private {
        _setBattleStatus(battle, battleId, BattleStatus.Drawing);
        battle.drawnAt = uint40(block.timestamp);

        uint256 requestId = VRF_COORDINATOR.requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            REQUEST_CONFIRMATIONS,
            uint32(500_000),
            uint32(1)
        );

        if (randomnessRequests[requestId].exists) {
            revert RandomnessRequestAlreadyExists();
        }

        randomnessRequests[requestId].exists = true;
        randomnessRequests[requestId].battleId = battleId;

        emit RandomnessRequested(battleId, requestId);
    }

    /**
     * @param battle The battle to check the status of.
     * @param status The expected status of the battle
     */
    function _validateBattleStatus(
        Battle storage battle,
        BattleStatus status
    ) private view {
        if (battle.status != status) {
            revert InvalidStatus();
        }
    }

    /**
     * @param caller The expected caller.
     */
    function _validateCaller(address caller) private view {
        if (msg.sender != caller) {
            revert InvalidCaller();
        }
    }

    /**
     * @param expectedEthValue The expected ETH value to be sent by the caller.
     */
    function _validateExpectedEthValueOrRefund(
        uint256 expectedEthValue
    ) private {
        if (expectedEthValue > msg.value) {
            revert InsufficientNativeTokensSupplied();
        } else if (msg.value > expectedEthValue) {
            _transferETHAndWrapIfFailWithGasLimit(
                WETH,
                msg.sender,
                _unsafeSubtract(msg.value, expectedEthValue),
                gasleft()
            );
        }
    }

    /**
     * @param battle The battle to set the status of.
     * @param battleId The ID of the battle to set the status of.
     * @param status The status to set.
     */
    function _setBattleStatus(
        Battle storage battle,
        uint256 battleId,
        BattleStatus status
    ) private {
        battle.status = status;
        emit BattleStatusUpdated(battleId, status);
    }

    function _unsafeAdd(uint256 a, uint256 b) private pure returns (uint256) {
        unchecked {
            return a + b;
        }
    }

    function _unsafeSubtract(
        uint256 a,
        uint256 b
    ) private pure returns (uint256) {
        unchecked {
            return a - b;
        }
    }
}
