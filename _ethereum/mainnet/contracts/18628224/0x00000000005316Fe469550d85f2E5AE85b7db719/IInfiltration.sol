// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IInfiltration {
    /**
     * @notice Agent statuses.
     *         1. Active: The agent is active.
     *         2. Wounded: The agent is wounded. The agent can be healed for a number of blocks.
     *         3. Healing: The agent is healing. The outcome of the healing is not yet known.
     *         4. Escaped: The agent escaped from the game and took some rewards with him.
     *         5. Dead: The agent is dead. It can be due to the agent being wounded for too long or a failed healing.
     */
    enum AgentStatus {
        Active,
        Wounded,
        Healing,
        Escaped,
        Dead
    }

    /**
     * @notice Heal outcomes. The agent can either be healed or killed.
     */
    enum HealOutcome {
        Healed,
        Killed
    }

    /**
     * @notice Randomness request statuses.
     */
    enum RandomnessRequestStatus {
        None,
        Requested,
        Fulfilled
    }

    /**
     * @notice An agent.
     * @dev The storage layout of an agent is as follows:
     * |---------------------------------------------------------------------------------------------------|
     * | empty (176 bits) | healCount (16 bits) | woundedAt (40 bits) | status (8 bits) | agentId (16 bits)|
     * |---------------------------------------------------------------------------------------------------|
     * @param agentId The ID of the agent.
     * @param status The status of the agent.
     * @param woundedAt The round number when the agent was wounded.
     * @param healCount The number of times the agent has been successfully healed.
     */
    struct Agent {
        uint16 agentId;
        AgentStatus status;
        uint40 woundedAt;
        uint16 healCount;
    }

    /**
     * @notice The constructor calldata.
     * @param owner The owner of the contract.
     * @param name The name of the collection.
     * @param symbol The symbol of the collection.
     * @param price The mint price.
     * @param maxSupply The maximum supply of the collection.
     * @param maxMintPerAddress The maximum number of agents that can be minted per address.
     * @param blocksPerRound The number of blocks per round.
     * @param agentsToWoundPerRoundInBasisPoints The number of agents to wound per round in basis points.
     * @param roundsToBeWoundedBeforeDead The number of rounds for an agent to be wounded before getting killed.
     * @param looks The LOOKS token address.
     * @param vrfCoordinator The VRF coordinator address.
     * @param keyHash The VRF key hash.
     * @param subscriptionId The VRF subscription ID.
     * @param transferManager The transfer manager address.
     * @param healBaseCost The base cost to heal an agent.
     * @param protocolFeeRecipient The protocol fee recipient.
     * @param protocolFeeBp The protocol fee basis points.
     * @param weth The WETH address.
     * @param baseURI The base URI of the collection.
     */
    struct ConstructorCalldata {
        address owner;
        string name;
        string symbol;
        uint256 price;
        uint256 maxSupply;
        uint256 maxMintPerAddress;
        uint256 blocksPerRound;
        uint256 agentsToWoundPerRoundInBasisPoints;
        uint256 roundsToBeWoundedBeforeDead;
        address looks;
        address vrfCoordinator;
        bytes32 keyHash;
        uint64 subscriptionId;
        address transferManager;
        uint256 healBaseCost;
        address protocolFeeRecipient;
        uint16 protocolFeeBp;
        address weth;
        string baseURI;
    }

    /**
     * @notice Game info.
     * @dev The storage layout of game info is as follows:
     * |-------------------------------------------------------------------------------------------------------------------------------|
     * | empty (56 bits) | randomnessLastRequestedAt (40 bits) | currentRoundBlockNumber (40 bits) | currentRoundId (40 bits)          |
     * | escapedAgents (16 bits) | deadAgents (16 bits) | healingAgents (16 bits) | woundedAgents (16 bits) | activeAgents (16 bits)   |
     * |-------------------------------------------------------------------------------------------------------------------------------|
     * | prizePool (256 bits)                                                                                                          |
     * |-------------------------------------------------------------------------------------------------------------------------------|
     * | secondaryPrizePool (256 bits)                                                                                                 |
     * |-------------------------------------------------------------------------------------------------------------------------------|
     * | secondaryLooksPrizePool (256 bits)                                                                                            |
     * |-------------------------------------------------------------------------------------------------------------------------------|
     * @param activeAgents The number of active agents.
     * @param woundedAgents The number of wounded agents.
     * @param healingAgents The number of healing agents.
     * @param deadAgents The number of dead agents.
     * @param escapedAgents The number of escaped agents.
     * @param currentRoundId The current round ID.
     * @param currentRoundBlockNumber The current round block number.
     * @param randomnessLastRequestedAt The timestamp when the randomness was last requested.
     * @param prizePool The ETH prize pool for the final winner.
     * @param secondaryPrizePool The secondary ETH prize pool for the top X winners.
     * @param secondaryLooksPrizePool The secondary LOOKS prize pool for the top X winners.
     */
    struct GameInfo {
        uint16 activeAgents;
        uint16 woundedAgents;
        uint16 healingAgents;
        uint16 deadAgents;
        uint16 escapedAgents;
        uint40 currentRoundId;
        uint40 currentRoundBlockNumber;
        uint40 randomnessLastRequestedAt;
        uint256 prizePool;
        uint256 secondaryPrizePool;
        uint256 secondaryLooksPrizePool;
    }

    /**
     * @notice A Chainlink randomness request.
     * @param status The status of the randomness request.
     * @param roundId The round ID when the randomness request occurred.
     * @param randomWord The returned random word.
     */
    struct RandomnessRequest {
        RandomnessRequestStatus status;
        uint40 roundId;
        uint256 randomWord;
    }

    /**
     * @notice A heal result that is used to emit events.
     * @param agentId The agent ID.
     * @param outcome The outcome of the healing.
     */
    struct HealResult {
        uint256 agentId;
        HealOutcome outcome;
    }

    event EmergencyWithdrawal(uint256 ethAmount, uint256 looksAmount);
    event MintPeriodUpdated(uint256 mintStart, uint256 mintEnd);
    event HealRequestSubmitted(uint256 roundId, uint256[] agentIds, uint256[] costs);
    event HealRequestFulfilled(uint256 roundId, HealResult[] healResults);
    event RandomnessRequested(uint256 roundId, uint256 requestId);
    event RandomnessFulfilled(uint256 roundId, uint256 requestId);
    event InvalidRandomnessFulfillment(uint256 requestId, uint256 randomnessRequestRoundId, uint256 currentRoundId);
    event RoundStarted(uint256 roundId);
    event Escaped(uint256 roundId, uint256[] agentIds, uint256[] rewards);
    event PrizeClaimed(uint256 agentId, address currency, uint256 amount);
    event Wounded(uint256 roundId, uint256[] agentIds);
    event Killed(uint256 roundId, uint256[] agentIds);
    event Won(uint256 roundId, uint256 agentId);

    error ExceededTotalSupply();
    error FrontrunLockIsOn();
    error GameAlreadyBegun();
    error GameNotYetBegun();
    error GameIsStillRunning();
    error GameOver();
    error HealingDisabled();
    error InexactNativeTokensSupplied();
    error InvalidAgentStatus(uint256 agentId, AgentStatus expectedStatus);
    error InvalidHealingRoundsDelay();
    error InvalidMaxSupply();
    error InvalidMintPeriod();
    error InvalidPlacement();
    error MaximumHealingRequestPerRoundExceeded();
    error MintAlreadyStarted();
    error MintCanOnlyBeExtended();
    error MintStartIsInThePast();
    error NoAgentsLeft();
    error NoAgentsProvided();
    error NotEnoughMinted();
    error NothingToClaim();
    error NotInMintPeriod();
    error NotAgentOwner();
    error Immutable();
    error RandomnessRequestAlreadyExists();
    error InvalidRandomnessRequestId();
    error RoundsToBeWoundedBeforeDeadTooLow();
    error StillMinting();
    error TooEarlyToStartNewRound();
    error TooEarlyToRetryRandomnessRequest();
    error TooManyMinted();
    error WoundedAgentIdsPerRoundExceeded();

    /**
     * @notice Sets the mint period.
     * @dev If _mintStart is 0, the function call is just a mint end extension.
     * @param _mintStart The starting timestamp of the mint period.
     * @param _mintEnd The ending timestamp of the mint period.
     */
    function setMintPeriod(uint40 _mintStart, uint40 _mintEnd) external;

    /**
     * @notice Mints a number of agents.
     * @param to The recipient
     * @param quantity The number of agents to mint.
     */
    function premint(address to, uint256 quantity) external payable;

    /**
     * @notice Mints a number of agents.
     * @param quantity The number of agents to mint.
     */
    function mint(uint256 quantity) external payable;

    /**
     * @notice This function is here in case the game's invariant condition does not hold or the game is stuck.
     *         Only callable by the contract owner.
     */
    function emergencyWithdraw() external;

    /**
     * @notice Starts the game.
     * @dev Starting the game sets the current round ID to 1.
     */
    function startGame() external;

    /**
     * @notice Starts a new round.
     */
    function startNewRound() external;

    /**
     * @notice Close a round after randomness is fullfilled by Chainlink.
     * @param requestId The Chainlink request ID.
     */
    function closeRound(uint256 requestId) external;

    /**
     * @notice Claims the grand prize. Only callable by the winner.
     */
    function claimGrandPrize() external;

    /**
     * @notice Claims the secondary prizes. Only callable by top 50 agents.
     * @param agentId The agent ID.
     */
    function claimSecondaryPrizes(uint256 agentId) external;

    /**
     * @notice Escape from the game and take some rewards. 80% of the prize pool is distributed to
     *         the escaped agents and the rest to the secondary prize pool.
     * @param agentIds The agent IDs to escape.
     */
    function escape(uint256[] calldata agentIds) external;

    /**
     * @notice Submits a heal request for the specified agent IDs.
     * @param agentIds The agent IDs to heal.
     */
    function heal(uint256[] calldata agentIds) external;

    /**
     * @notice Get the agent at the specified index.
     * @return agent The agent at the specified index.
     */
    function getAgent(uint256 index) external view returns (Agent memory agent);

    /**
     * @notice Returns the cost to heal the specified agents
     * @dev The cost doubles for each time the agent is healed.
     * @param agentIds The agent IDs to heal.
     * @return cost The cost to heal the specified agents.
     */
    function costToHeal(uint256[] calldata agentIds) external view returns (uint256 cost);

    /**
     * @notice Returns the reward for escaping the game.
     * @param agentIds The agent IDs to escape.
     * @return reward The reward for escaping the game.
     */
    function escapeReward(uint256[] calldata agentIds) external view returns (uint256 reward);

    /**
     * @notice Returns the total number of agents alive.
     */
    function agentsAlive() external view returns (uint256);

    /**
     * @notice Returns the index of a specific agent ID inside the agents mapping.
     * @param agentId The agent ID.
     * @return index The index of the agent ID.
     */
    function agentIndex(uint256 agentId) external view returns (uint256 index);

    /**
     * @notice Returns a specific round's information.
     * @param roundId The round ID.
     * @return woundedAgentIds The agent IDs of the wounded agents in the specified round.
     * @return healingAgentIds The agent IDs of the healing agents in the specified round.
     */
    function getRoundInfo(
        uint256 roundId
    ) external view returns (uint256[] memory woundedAgentIds, uint256[] memory healingAgentIds);
}
