// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IBattle {
    enum BattleStatus {
        None,
        Created,
        Open,
        Drawing,
        RandomnessFulfilled,
        Drawn,
        Complete,
        Refundable,
        Cancelled
    }

    enum TokenType {
        ERC721,
        ERC1155,
        ETH,
        ERC20
    }

    /**
     * @param entriesCount The number of entries that can be purchased for the given price.
     * @param price The price of the entries.
     */
    struct PricingOption {
        uint40 entriesCount;
        uint208 price;
    }

    /**
     * @param currentEntryIndex The cumulative number of entries in the battle.
     * @param participant The address of the participant.
     */
    struct Entry {
        uint40 currentEntryIndex;
        address participant;
    }

    /**
     * @param participant The address of the winner.
     * @param claimed Whether the winner has claimed the prize.
     * @param prizeIndex The index of the prize that was won.
     * @param entryIndex The index of the entry that won.
     */
    struct Winner {
        address participant;
        bool claimed;
        uint8 prizeIndex;
        uint40 entryIndex;
    }

    /**
     * @param winnersCount The number of winners.
     * @param cumulativeWinnersCount The cumulative number of winners in the battle.
     * @param prizeType The type of the prize.
     * @param prizeTier The tier of the prize.
     * @param prizeAddress The address of the prize.
     * @param prizeId The id of the prize.
     * @param prizeAmount The amount of the prize.
     */
    struct Prize {
        uint40 winnersCount;
        uint40 cumulativeWinnersCount;
        TokenType prizeType;
        uint8 prizeTier;
        address prizeAddress;
        uint256 prizeId;
        uint256 prizeAmount;
    }

    /**
     * @param owner The address of the battle owner.
     * @param status The status of the battle.
     * @param isMinimumEntriesFixed Whether the minimum number of entries is fixed.
     * @param cutoffTime The time after which the battle cannot be entered.
     * @param drawnAt The time at which the battle was drawn. It is still pending Chainlink to fulfill the randomness request.
     * @param minimumEntries The minimum number of entries required to draw the battle.
     * @param maximumEntriesPerParticipant The maximum number of entries allowed per participant.
     * @param feeTokenAddress The address of the token to be used as a fee. If the fee token type is ETH, then this address is ignored.
     * @param protocolFeeBp The protocol fee in basis points. It must be equal to the protocol fee basis points when the battle was created.
     * @param claimableFees The amount of fees collected from selling entries.
     * @param pricingOptions The pricing options for the battle.
     * @param prizes The prizes to be distributed.
     * @param entries The entries that have been sold.
     * @param winners The winners of the battle.
     */
    struct Battle {
        address owner;
        BattleStatus status;
        bool isMinimumEntriesFixed;
        uint40 cutoffTime;
        uint40 drawnAt;
        uint40 minimumEntries;
        uint40 maximumEntriesPerParticipant;
        address feeTokenAddress;
        uint16 protocolFeeBp;
        uint208 claimableFees;
        PricingOption[5] pricingOptions;
        Prize[] prizes;
        Entry[] entries;
        Winner[] winners;
    }

    /**
     * @param amountPaid The amount paid by the participant.
     * @param entriesCount The number of entries purchased by the participant.
     * @param refunded Whether the participant has been refunded.
     */
    struct ParticipantStats {
        uint208 amountPaid;
        uint40 entriesCount;
        bool refunded;
    }

    /**
     * @param battleId The id of the battle.
     * @param pricingOptionIndex The index of the selected pricing option.
     */
    struct EntryCalldata {
        uint256 battleId;
        uint256 pricingOptionIndex;
    }

    /**
     * @param cutoffTime The time at which the battle will be closed.
     * @param minimumEntries The minimum number of entries required to draw the battle.
     * @param isMinimumEntriesFixed Whether the minimum number of entries is fixed.
     * @param maximumEntriesPerParticipant The maximum number of entries allowed per participant.
     * @param protocolFeeBp The protocol fee in basis points. It must be equal to the protocol fee basis points when the battle was created.
     * @param feeTokenAddress The address of the token to be used as a fee. If the fee token type is ETH, then this address is ignored.
     * @param prizes The prizes to be distributed.
     * @param pricingOptions The pricing options for the battle.
     */
    struct CreateBattleCalldata {
        uint40 cutoffTime;
        bool isMinimumEntriesFixed;
        uint40 minimumEntries;
        uint40 maximumEntriesPerParticipant;
        uint16 protocolFeeBp;
        address feeTokenAddress;
        Prize[] prizes;
        PricingOption[5] pricingOptions;
    }

    struct ClaimPrizesCalldata {
        uint256 battleId;
        uint256[] winnerIndices;
    }

    /**
     * @param exists Whether the request exists.
     * @param battleId The id of the battle.
     * @param randomWord The random words returned by Chainlink VRF.
     *                   If randomWord == 0, then the request is still pending.
     */
    struct RandomnessRequest {
        bool exists;
        uint248 randomWord;
        uint256 battleId;
    }

    event CurrenciesStatusUpdated(address[] currencies, bool isAllowed);
    event EntryRefunded(uint256 battleId, address buyer, uint208 amount);
    event EntrySold(
        uint256 battleId,
        address buyer,
        uint40 entriesCount,
        uint208 price
    );
    event FeesClaimed(uint256 battleId, uint256 amount);
    event PrizesClaimed(uint256 battleId, uint256[] winnerIndex);
    event ProtocolFeeBpUpdated(uint16 protocolFeeBp);
    event ProtocolFeeRecipientUpdated(address protocolFeeRecipient);
    event BattleStatusUpdated(uint256 battleId, BattleStatus status);
    event RandomnessRequested(uint256 battleId, uint256 requestId);

    error AlreadyRefunded();
    error CutoffTimeNotReached();
    error CutoffTimeReached();
    error DrawExpirationTimeNotReached();
    error InsufficientNativeTokensSupplied();
    error InvalidCaller();
    error InvalidCurrency();
    error InvalidCutoffTime();
    error InvalidIndex();
    error InvalidPricingOption();
    error InvalidPrize();
    error InvalidPrizesCount();
    error InvalidProtocolFeeBp();
    error InvalidProtocolFeeRecipient();
    error InvalidStatus();
    error InvalidWinnersCount();
    error MaximumEntriesPerParticipantReached();
    error MaximumEntriesReached();
    error PrizeAlreadyClaimed();
    error RandomnessRequestAlreadyExists();
    error RandomnessRequestDoesNotExist();

    /**
     * @notice Creates a new battle.
     * @param params The parameters of the battle.
     * @return battleId The id of the newly created battle.
     */
    function createBattle(
        CreateBattleCalldata calldata params
    ) external payable returns (uint256 battleId);

    function enterBattles(EntryCalldata[] calldata entries) external payable;

    /**
     * @notice Select the winners for a battle based on the random words returned by Chainlink.
     * @param requestId The request id returned by Chainlink.
     */
    function selectWinners(uint256 requestId) external;

    /**
     * @notice Claims the prizes for a winner. A winner can claim multiple prizes
     *         from multiple battles in a single transaction.
     * @param claimPrizesCalldata The calldata for claiming prizes.
     */
    function claimPrizes(
        ClaimPrizesCalldata[] calldata claimPrizesCalldata
    ) external;

    /**
     * @notice Claims the fees collected for a battle.
     * @param battleId The id of the battle.
     */
    function claimFees(uint256 battleId) external;

    /**
     * @notice Cancels a battle beyond cut-off time without meeting minimum entries.
     * @param battleId The id of the battle.
     */
    function cancel(uint256 battleId) external;

    /**
     * @notice Cancels a battle after randomness request if the randomness request
     *         does not arrive after a certain amount of time.
     *         Only callable by contract owner.
     * @param battleId The id of the battle.
     */
    function cancelAfterRandomnessRequest(uint256 battleId) external;

    /**
     * @notice Withdraws the prizes for a battle after it has been marked as refundable.
     * @param battleId The id of the battle.
     */
    function withdrawPrizes(uint256 battleId) external;

    /**
     * @notice Claims the refund for a cancelled battle.
     * @param battleIds The ids of the battles.
     */
    function claimRefund(uint256[] calldata battleIds) external;

    /**
     * @notice Claims the protocol fees collected for a battle.
     * @param currency The currency of the fees to be claimed.
     */
    function claimProtocolFees(address currency) external;

    /**
     * @notice Sets the protocol fee in basis points. Only callable by contract owner.
     * @param protocolFeeBp The protocol fee in basis points.
     */
    function setProtocolFeeBp(uint16 protocolFeeBp) external;

    /**
     * @notice Sets the protocol fee recipient. Only callable by contract owner.
     * @param protocolFeeRecipient The protocol fee recipient.
     */
    function setProtocolFeeRecipient(address protocolFeeRecipient) external;

    /**
     * @notice This function allows the owner to update currency statuses.
     * @param currencies Currency addresses (address(0) for ETH)
     * @param isAllowed Whether the currencies should be allowed for trading
     * @dev Only callable by owner.
     */
    function updateCurrenciesStatus(
        address[] calldata currencies,
        bool isAllowed
    ) external;

    /**
     * @notice Toggle the contract's paused status. Only callable by contract owner.
     */
    function togglePaused() external;

    /**
     * @notice Gets the winners for a battle.
     * @param battleId The id of the battle.
     * @return winners The winners of the battle.
     */
    function getWinners(
        uint256 battleId
    ) external view returns (Winner[] memory);

    /**
     * @notice Gets the pricing options for a battle.
     * @param battleId The id of the battle.
     * @return pricingOptions The pricing options for the battle.
     */
    function getPricingOptions(
        uint256 battleId
    ) external view returns (PricingOption[5] memory);

    /**
     * @notice Gets the prizes for a battle.
     * @param battleId The id of the battle.
     * @return prizes The prizes to be distributed.
     */
    function getPrizes(uint256 battleId) external view returns (Prize[] memory);

    /**
     * @notice Gets the entries for a battle.
     * @param battleId The id of the battle.
     * @return entries The entries entered for the battle.
     */
    function getEntries(
        uint256 battleId
    ) external view returns (Entry[] memory);
}
