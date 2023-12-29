// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./IInfiltration.sol";

import "./OwnableTwoSteps.sol";
import "./IERC20.sol";

import "./ProtocolFee.sol";
import "./PackableReentrancyGuard.sol";
import "./LowLevelERC20Transfer.sol";
import "./LowLevelWETH.sol";
import "./ITransferManager.sol";

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./ERC721A.sol";

import "./UnsafeMathUint256.sol";

//                                            .:^^^^^^:::::::::::::::::::::::::::::::::::::::::::::.
//                                          :~7777!!!77?JJ??????!?YYYYYYYYJ?7~~!!!!!!!!!7???7~~~!~~^:.
//                                        :~!!!~~77JYYYJJYJJJJJ7J5PPPPP55?!!!!!!!7!!~~~~~~!77??7?!7!!~^.
//                                      .^~!!!7JYYYYYYJJJJJJJJJ7Y5PPPY?!!!!!!~~~~~~!7!!~~~~~~!????J??7!!^.
//                                   .:^!!?JYYYYYYYYJJJJJJJYJJ!J55YJ?!!!!!~~~~~~~~~~~!!7!!!!!7!!!!!77?JJ?!~:.
//                                 .:^~?YYYYYYYYYJJJJJJJJJJJJ??YYJ?!!!77!!!!!!!!!!!!!!~~!!!77!!!!!!!!!!!7?J7~:.
//                               .^~~!~JYYYYYYYYYJJJJJJJJ???~^??7^.........:::::::^^^^!!!!!77!!!!!!!!!!~~!!7?7!^.
//                             :^!!!!!~~JYYYYYYJJJJJJJ7!~^:::!????~....    ...:::::::::::^^~77!!!!!!!!!~~~!!!77!!^.
//                           :~77~!7!!~!JYJJJJJJJJJ!^^^^^^^:^JJ???7!^^::::::::..::::::::::::.:~!!!!!~7?!~~~~!!!!~~!^.
//                         :!?7!!!77!~~JJJJJJJJ?!^^^^^^^^^::J???5PPG##GPPP5555?77!::::::::.....::^!!!J5Y?!~~~~!77~~~!~:
//                      .:7J?!~!77!~~~!JJJJJ?~^^^^^^^^^^^::~?5##&@@@@@&BGBGPPPP555YJ!^::......:::...^?55YJ?!~~!!!!~~!!!~:
//                    .^7J?7!!!!!!~~~~JJJJ7~^^^^^^^^^^^^:^J##@@@@@@@@@@@&#GGPPP555PPP55?:...::::::.. :!?JJJJ7!~~!77!~!!~!~:.
//                  .:!?77!!!!!!~~~~~7JJ7~^^^^^^^^^^^^::~J#@@@@@@@@@@@@@@@#BGP55PPPPPGGGJ^......:::. ^~:^7???7!!!!!!~~!!!~!~:.
//                .:!7!~~!!!!!!!~~~~!J7~^^^^^^^^^^^^^::7PB&@@@@@@@@&&B55555YGGPPPPPPGGBBBG7......:::..:^::^!7777!!!!!~~!!!!~!~^.
//              .:^~!?J!~!7!!!!!~~~!~~^^~^^^^^:::::::.7PGB&&&&@@@&G?~~~!!!!~~~75GBBBBBBBB#B?  ......   .... :~!7!!!!~~!!!!!7!~7?~.
//            .:^~!?5PPJ!~!!!!!~!!^::!~!!!^:....... .^JPB&&&&&&&G?~~!!7?JJ7!~^:^!5###&#####P~       :^^:      .^!!~~!7777!!!!~7Y5J!.
//          .:^~!JY5PPPPY!~~~~!!^.   .:^!!^.       ::YBB####&&&P~^~!~~~^^^^:::::.^P&&&&&#&&&5    .:!????7!^::.  .^!!77777777!~!J5PPY!:
//        .:~~~?Y5555PP5Y?~~!!^.        .^:..^^^!77?!5BB######B~:^^^::::::::......^#&&&&&&&&5  .:!???????????7!!^::~7?7?77777777?Y555J~.
//       .:^~!!7?J??????7!!!7~.       .......:^77?JJ!5BBBBBBB#B^:::::....::::::::.~&@@@@&&&&5...^^^^^^^^^^^~^^^^^^:.~7!!~~~~~!!!!!77?7~:.
//         .:^~!~!77!!!!!~~~!!!^:..... .::~~:....:^^:?GBBBGPPP5~.....:::::::::::.:7&&&&&&&&&P:::^:^^^^^:. .:.    .^~~~~~~~~~~~~~!77!~:.
//           .:^~!!!77!!!~~~~~~!!^.   .::!77~^:......!Y555555555!:..::::::::::..:?#&&&&&&@@&5!7???????!. :~:.. .^!!~~~~~~~~~~~!!7!~:.
//            ..:^~!!7?!!~~~~~~~~!!~:.:^!7!^.:^: .....755PPPPPPGG57:..::::::..:7P#&&&&&&@@@P!7????JJJ!. :^::.:~!!~~~~~~~~!!!!!7!~:..
//           .....:^~!!77!~~~~~~~!!!!!^!7!:....^^  .. :?PPGGGGGBBBBPYJ^^^^^^JYG####&&&#&@@G?7????JJJ~. :^:.:!777!!!!!!!!!!!!7!~:.....
//         .........:^~!!77!~~~~~~!??JY?!:...  .^^  .. :?PGBBBB####&@&######&&&#######&&#P?7????JJ7~. :^:^!?77777777777!!!7!^:.........
//        ..........:::^~!!77!!~~~~!JJ5J7!:.    .^^. ....~PBB#####&&@@@@@@@@&&########&#J77????J?7:  :^^!?77777777??7!!!7!^:::...........
//      ..........:::::::^~~!7?7~~~~~7JY7!~~^.   .^^. .   ^7?G###&&&@@@@@@@@&&######GJY?77????J?7:  :!!!J?777777??7!!!!~^:::::::..........
//    ..........::::::::^^^^~~?J7!~~~~~??7^757^^. .^^.       :7?PBB#&&&&&&&&&&#BBP?7^!777????J?7..~~?5?!????????7!!!!~^^^^::::::::..........
//   ..........:::::::^^^^^^^^^!???!~~~~!?77J?:~~^^:^:  .       .::!JJJJJJJJJJ!^^^:..777??????!~^7J!JY77JJJJ??7!!!!~^^^^^^^^:::::::..........
//  .........:::::::^^^^^^~~~~^^^!7J?!!~~~77!^:~~!~~~~:...    .  .. .::::::::::::::.^777?77??7~~7J5!!7?JJJJ?7!!!!~^^~~~~^^^^^^:::::::.........
// .........:::::::^^^^^~~~~~~!~~^^!JJ?7!~!!!~^^^~~~~!??!^~^.... .. .:::::::::::::::77???Y5Y7~~?Y5YJJJJJJ??7~!!~~~!!~~~~~~^^^^^:::::::.........
// ........::::::^^^^^^~~~~~!!!!!!!~~!??77!!!~~~~:^~~~!?J???7777~^~^~~~~!!~~~~~~~!7JYYP5PG57^!?Y55YYYJJJJ7!!!~~!!!!!!!~~~~~^^^^^^::::::........
// ......:::::::^^^^^~~~~~~!!!!!7777!~~!??7777!~!~^^~!^!??J??????????555PP5555555J?55P5PP57^!?Y55P5YYYJ?!!!~~!7777!!!!!~~~~~~^^^^^:::::::......
// .....:::::::^^^^^~~~~~!!!!!!77777??7~~!???7?777!^~!!7???77???????JY55GG555555Y??5555PY?77JY55PPP5Y?!!!~!7??777777!!!!!~~~~~^^^^^^::::::.....
// ....::::::^^^^^^~~~~~!!!!!77777??????!^^!?YY??!!!^~!777!^!??7!!!!!7Y5PP5YYYYJ7~Y5P55?7?JJY5555PPY7!!^^!??????77777!!!!!~~~~~^^^^^^::::::....
// ...::::::^^^^^~~~~~!!!!!!77777??77!~~~~^:~7JP5J7^~~!!!7!7??!7777?JJ5YYYYPPP5J77555PJ77?JY555PP5J?7~^^~~~~!77??77777!!!!!!~~~~~^^^^^::::::...
// ..::::::^^^^^~~~~~!!!!!777777!!~~~~~!!!!!~^~?5PY7~~!77!!?7!!7????JJ55555555Y?7JP5YJ?7JJY55555Y?7~^~!!!!!~~~~~!!777777!!!!!~~~~~^^^^^::::::..
// ..::::::^^^^~~~~~!!!!!77!!~~~~~~~~7?JJJ?77!^:~?Y5Y!~!7!^7J7~~!7777?YYYYYYYYJ7?55J7JJ7J55555Y?!^:^!77?JJJ?7~~~~~~~~!!77!!!!!~~~~~^^^^^:::::..
// .::::::^^^^^~~~~!!!!!!!^^^^^^~!!7777JJY?77!!~^.^7YY?~^!!^?J7~^^!77?YYYYYYYY7~75Y7JJ?JY555Y?!^:^~!!77?YJJ7777!!~^^^^^^!!!!!!!~~~~^^^^^::::::.
// ::::::^^^^^~~~~~!!!!7!:!!^:^~~!!!7!777?JJ?77!~.::^7JJ7^^~~~????77?Y5PP5P55Y7?5Y?J???Y55Y?!^:::~!77?JJ?777!7!!!~~^:^!!^!7!!!!~~~~~^^^^^::::::
// :::::^^^^^~~~~~!!!!77!:J?!^^^~~~!!!!!777??777~.^^::^7YJ!^^!!77!!7JJY555555J7!!77J??JYY?!^::^^:!777??777!!!!!~~~^^^!?J^!77!!!!~~~~~^^^^^:::::
// :::::^^^^^~~~~!!!!!777~^!???7~^~~~!!!!!777777!.^~~~^^~?J!~^~~~!7??JJ55555Y?77!!???J?~^^:^~~~^:!777777!!!!!~~~^~7???!^~777!!!!!~~~~^^^^^:::::
// ::::^^^^^~~~~~!!!!77777~^^~!??7~^~~~~~!!!!!777!.^!!~!!^^!?7!77!~!?JJ5555YJ7~^7JJJ!~:.:!!~!!^:!777!!!!!~~~~~^~7??!~^^~77777!!!!~~~~~^^^^^::::
// ::::^^^^^~~~~!!!!!7777??7!^^^!??7~^~~~~~~!!!!!!.^~!!7??^.^!????????YPPPPJ~^~7JJ?!^:.^??7!!~^:!!!!!!~~~~~~^~7??!^^^!7??7777!!!!!~~~~^^^^^::::
// ::::^^^^~~~~~!!!!77777777??~^^^~7?7~^~^~~~~!~!~.:!!7!75J::::!7????7?PPP5!^~7777~::::J57!7!!^:!!~!~~~~^~^~7?7~^^^~??77777777!!!!~~~~~^^^^::::
// :::^^^^^~~~~!!!!!~~~^:::^^~7^:^^^~7?7!^^^^~~~~~..!!!77?5J:^^::~7?J?7JPPJ:~77!^::^^:J5?77!!!..~~~~~^^^^!7?7~^^^^~7~^^:::^~~~!!!!!~~~~^^^^^:::
// ::::^^^^~~~~!!!~^^^^~^^^^:.::::^~^:~7??!^::^^^: :~!!!77?5J:^~~::~?JJ?P5~!??~::~~^:J5?77!!!~: :^^^::^!??7~:^~^::::.:^^^^~^^^^~!!!~~~~^^^^::::
// ::::::^^~~~~!!~^^^~~~~^^^^:.::::^~^::~7??!^::::.::!7!!!7?5J^^~!!~^~?YPP?7~^~!!~^^J5?7!!!7!::.::::^!??7~::^~^::::.:^^^^~~~~^^^~!!~~~~^^::::::
// ^^^^~~^^^^~~!~:^^~~!~~~^^^^:.::^~~^^:::^!??!:~!~::^!!!!!7?5J^^~!77~^~??~^~77!~^^J5?7!!!!!^::~!~:!??!^:::^^~~^::.:^^^^~~~!~~^^:~!~~^^^^~~^^^^
// ^^^~~^:^^^^^~:^^~~!!!!!!!~~~^::~^^^^^^:::!J?!^!7!^::~!!!!7?5Y!^~!!7!~^^~!7!!~^!Y5?7!!!!~::^!7!^!?J!:::^^^^^^~::^~~~!!!!!!!~~^^:~^^^^::^~~^^^
// !!~!7^.::^^::.^~~!!!!!77?JJJJ?!~^::^^^^^^~7?~:!!77!^^~~!!!7?J5Y7~^^~!~~!~^^~7Y5J?7!!!~~^^!77!!:~?7~^^^^^^::^~!?JJJJ?77!!!!!~~^.::^^::.^7!~!!
// 777J?:.:^^^...:^~!!!7Y??7?777???!.:^~^^^~!~~!!!!!!7?7~^^^~~!77?JJ??~~~~~~??JJ?77!~~^^^~7?7!!!!!!~~!~^^^~^:.!??7777?7??Y7!!!~^:...^^^:.:?J777
// !!7Y?::!77~:^^:.:^~7J??!!!7^~!!77~.:~7~~~~^^?J?!^^~~!7??!~^^^~~!!7????????7!!~~^^^~!??7!~~^^!?J?^^~~~~7~:.~777~^~~7!!??J7~^:.:^^:~77!::?Y7!!
// !!7Y?::!!~:~?7~^:::^~~7!!7!^~~~7!!~.:~!!~~~^^^~: .:^^^^~~!7!~~~^:^^^^^^^^^^:^~~~!7!~~^^^^:. :~^^^~~~!!~:.~!!7!^~!~~7!7~~^:::^~7?~:~!!::?Y7!!
// ?77?Y7^:^:~!??J?7!^::^~!!!~~~~!!!!~^.:^7?!~~^^^^::.:^^~!!~~~~~~^^^^^^^^^^^^^^~~~~~~!!~^^:.::^^^^~~!?7^:.^~!!!!~~~~!!!~^::^!7?J??!~:^:^7Y?77?
// ??!7YJ^.:^!7???YYJ?7~~^^~~7!!!~~~~~~^::^~7??777!~!^^^^:::^~~~!!!!!!!!!!!!!!!!!!~~~^:::^^^^!~!777??7~^::^~~~~~~!!!7~~^^~~7?JYY???7!^:.^JY7!??
// ??77YJ~.^~!77?JJJYYYYJ7!^^^~!777!!~~~~^::^^~!77????77?7!!~~~~^::::::::::::::::^~~~~!!7?77????77!~^^::^~~~~!!777!~^^^!7JYYYYJJJ?77!~^.~JY77??
// J??77YJ~.^!!!JJ??777??YYJJ7!~^^~!77!~~~~~~~^^^^^~~!7777??????777777777777777777??????7777!~~^^^^^~~~~~~~!77!~^^~!7JJYY??777??JJ!!!^.~JY77??J
// YY?77JY!:^!!!YJ?7!!!~~!!??JYJJ7!~^~~!!!~!!!!7777~~~~^^^~~~~~!777777777777777777!~~~~~^^^~~~~7777!!!!~!!!~~^~!7JJYJ??!!~~!!!7?JY!!!^:!YJ77?YY
// YYJ?77JY!:~!!?Y?7!!!~~~~~~!!7?JYJ?7~^^~~!!!!7????????777777~~~~~~~~~~~~~~~~~~~~~~777777????????7!!!!~~^^~7?JYJ?7!!~~~~~~!!!7?Y?!!~:!YJ77?JYY
// YJYJJ?7?J?^:!!?J?!!!~~~~~~~~~~~!7JJYY?~^^~!!77!7777?????????JJJJJJJJJJJJJJJJJJJJ?????????7777!77!!~^^~?YYJJ7!~~~~~~~~~~~!!!?J?!!:^?J?7?JJYJY
contract Infiltration is
    IInfiltration,
    OwnableTwoSteps,
    ERC721A,
    VRFConsumerBaseV2,
    LowLevelERC20Transfer,
    LowLevelWETH,
    ProtocolFee,
    PackableReentrancyGuard
{
    using UnsafeMathUint256 for uint256;

    /**
     * @notice When the frontrun lock is unlocked, agents can escape or heal.
     */
    uint8 private constant FRONTRUN_LOCK__UNLOCKED = 1;

    /**
     * @notice When the frontrun lock is locked, agents cannot escape or heal.
     */
    uint8 private constant FRONTRUN_LOCK__LOCKED = 2;

    /**
     * @notice When VRF is being requested, agents cannot escape or heal. It unlocks when the randomness is fulfilled.
     * @dev frontrunLock is initially set as locked so that agents cannot escape or heal before the game starts.
     *      It is unlocked when the first round's randomness is fulfilled.
     */
    uint8 private frontrunLock = FRONTRUN_LOCK__LOCKED;

    /**
     * @notice 100% in basis points.
     */
    uint256 private constant ONE_HUNDRED_PERCENT_IN_BASIS_POINTS = 10_000;

    /**
     * @notice 100% in basis points squared.
     */
    uint256 private constant ONE_HUNDRED_PERCENT_IN_BASIS_POINTS_SQUARED = 10_000 ** 2;

    /**
     * @notice The number of secondary prize pool winners. Their entitled shares are based on their placements.
     *         When the number of active agents is less than or equal to this number, 1 agent is instantly killed
     *         in each round.
     */
    uint256 private constant NUMBER_OF_SECONDARY_PRIZE_POOL_WINNERS = 50;

    uint256 private constant PROBABILITY_PRECISION = 100_000_000;

    /**
     * @notice Max agent supply.
     */
    uint256 public immutable MAX_SUPPLY;

    /**
     * @notice Max mint per address.
     */
    uint256 public immutable MAX_MINT_PER_ADDRESS;

    /**
     * @notice The price of minting 1 agent.
     */
    uint256 public immutable PRICE;

    /**
     * @notice The number of blocks per round.
     */
    uint256 public immutable BLOCKS_PER_ROUND;

    /**
     * @notice The percentage of agents to wound per round in basis points.
     */
    uint256 public immutable AGENTS_TO_WOUND_PER_ROUND_IN_BASIS_POINTS;

    /**
     * @notice The number of rounds for agents to be wounded before getting killed.
     */
    uint256 public immutable ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD;

    /**
     * @notice This value is used as the denominator in healProbability.
     */
    uint256 private immutable ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD_MINUS_ONE;

    /**
     * @notice This value is used as the minuend in healProbability.
     */
    uint256 private immutable HEAL_PROBABILITY_MINUEND;

    /**
     * @notice The base cost of healing an agent. The cost increases for each successful heal.
     */
    uint256 public immutable HEAL_BASE_COST;

    /**
     * @notice WETH address.
     */
    address private immutable WETH;

    /**
     * @notice LOOKS address.
     */
    address private immutable LOOKS;

    /**
     * @notice Chainlink VRF key hash.
     */

    bytes32 private immutable KEY_HASH;

    /**
     * @notice Chainlink VRF coordinator.
     */
    VRFCoordinatorV2Interface private immutable VRF_COORDINATOR;

    /**
     * @notice Chainlink VRF subscription ID.
     */
    uint64 private immutable SUBSCRIPTION_ID;

    /**
     * @notice The transfer manager contract that manages LOOKS approvals.
     */
    ITransferManager private immutable TRANSFER_MANAGER;

    /**
     * @notice The timestamp at which the mint period starts.
     */
    uint40 public mintStart;

    /**
     * @notice The timestamp at which the mint period ends.
     */
    uint40 public mintEnd;

    /**
     * @notice The bitmap of the placements of the secondary prize pool winners.
     * @dev Only bit 1 to 50 are used. Bit 0 is not used.
     */
    uint56 private prizesClaimedBitmap;

    /**
     * @notice The base URI of the collection.
     */
    string private baseURI;

    /**
     * @notice Amount of agents minted per address.
     */
    mapping(address minter => uint256 amount) public amountMintedPerAddress;

    /**
     * @notice Chainlink randomness requests.
     */
    mapping(uint256 requestId => RandomnessRequest) public randomnessRequests;

    /**
     * @notice The mapping agents acts as an "array". In the beginning of the game, the "length" of the "array"
     *         is the total supply. As the game progresses, the "length" of the "array" decreases
     *         as agents are killed. The function agentsAlive() returns the "length" of the "array".
     *
     *         When an Agent struct has 0 value for every field with its index within the total supply,
     *         it means that the agent is active.
     *
     *         Index 0 is not used as agent ID starts from 1.
     */
    mapping(uint256 index => Agent) private agents;

    /**
     * @notice It is used to find the index of an agent in the agents mapping given its agent ID.
     *         If the index is 0, it means the agent's index is the same as its agent ID as no swaps
     *         have been made.
     */
    mapping(uint256 agentId => uint256 index) private agentIdToIndex;

    /**
     * @notice The maximum healing or wounded agents allowed per round.
     */
    uint256 private constant MAXIMUM_HEALING_OR_WOUNDED_AGENTS_PER_ROUND = 30;

    /**
     * @notice The maximum healing or wounded agents allowed per round + 1 for storing the array length.
     */
    uint256 private constant MAXIMUM_HEALING_OR_WOUNDED_AGENTS_PER_ROUND_AND_LENGTH = 31;

    /**
     * @notice The first element of the array is the length of the array.
     */
    mapping(uint256 roundId => uint16[MAXIMUM_HEALING_OR_WOUNDED_AGENTS_PER_ROUND_AND_LENGTH] agentIds)
        private woundedAgentIdsPerRound;

    /**
     * @notice The first element of the array is the length of the array.
     */
    mapping(uint256 roundId => uint16[MAXIMUM_HEALING_OR_WOUNDED_AGENTS_PER_ROUND_AND_LENGTH] agentIds)
        private healingAgentIdsPerRound;

    /**
     * @notice Game information.
     */
    GameInfo public gameInfo;

    /**
     * @dev Agent struct status offset for bitwise operations.
     */
    uint256 private constant AGENT__STATUS_OFFSET = 16;

    /**
     * @dev Agent struct wounded at offset for bitwise operations.
     */
    uint256 private constant AGENT__WOUNDED_AT_OFFSET = 24;

    /**
     * @dev Agent struct heal count offset for bitwise operations.
     */
    uint256 private constant AGENT__HEAL_COUNT_OFFSET = 64;

    /**
     * @dev GameInfo struct wounded agents offset for bitwise operations.
     */
    uint256 private constant GAME_INFO__WOUNDED_AGENTS_OFFSET = 16;

    /**
     * @dev GameInfo struct healing agents offset for bitwise operations.
     */
    uint256 private constant GAME_INFO__HEALING_AGENTS_OFFSET = 32;

    /**
     * @dev GameInfo struct dead agents offset for bitwise operations.
     */
    uint256 private constant GAME_INFO__DEAD_AGENTS_OFFSET = 48;

    /**
     * @dev GameInfo struct escaped agents offset for bitwise operations.
     */
    uint256 private constant GAME_INFO__ESCAPED_AGENTS_OFFSET = 64;

    /**
     * @dev GameInfo struct current round ID offset for bitwise operations.
     */
    uint256 private constant GAME_INFO__CURRENT_ROUND_ID_OFFSET = 80;

    /**
     * @dev GameInfo struct current round block number offset for bitwise operations.
     */
    uint256 private constant GAME_INFO__CURRENT_ROUND_BLOCK_NUMBER_OFFSET = 120;

    /**
     * @dev RandomnessRequest struct exists offset for bitwise operations.
     */
    uint256 private constant RANDOMNESS_REQUESTS__EXISTS_OFFSET = 8;

    /**
     * @dev 2 bytes bitmask.
     */
    uint256 private constant TWO_BYTES_BITMASK = 0xffff;

    /**
     * @dev 5 bytes bitmask.
     */
    uint256 private constant FIVE_BYTES_BITMASK = 0xffffffffff;

    /**
     * @param constructorCalldata Constructor calldata. See IInfiltration.ConstructorCalldata for its key values.
     */
    constructor(
        ConstructorCalldata memory constructorCalldata
    )
        OwnableTwoSteps(constructorCalldata.owner)
        ERC721A(constructorCalldata.name, constructorCalldata.symbol)
        VRFConsumerBaseV2(constructorCalldata.vrfCoordinator)
    {
        if (
            constructorCalldata.maxSupply <= NUMBER_OF_SECONDARY_PRIZE_POOL_WINNERS ||
            constructorCalldata.maxSupply > type(uint16).max
        ) {
            revert InvalidMaxSupply();
        }

        if (
            (constructorCalldata.maxSupply * constructorCalldata.agentsToWoundPerRoundInBasisPoints) >
            MAXIMUM_HEALING_OR_WOUNDED_AGENTS_PER_ROUND * ONE_HUNDRED_PERCENT_IN_BASIS_POINTS
        ) {
            revert WoundedAgentIdsPerRoundExceeded();
        }

        if (constructorCalldata.roundsToBeWoundedBeforeDead < 3) {
            revert RoundsToBeWoundedBeforeDeadTooLow();
        }

        PRICE = constructorCalldata.price;
        MAX_SUPPLY = constructorCalldata.maxSupply;
        MAX_MINT_PER_ADDRESS = constructorCalldata.maxMintPerAddress;
        BLOCKS_PER_ROUND = constructorCalldata.blocksPerRound;
        AGENTS_TO_WOUND_PER_ROUND_IN_BASIS_POINTS = constructorCalldata.agentsToWoundPerRoundInBasisPoints;
        ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD = constructorCalldata.roundsToBeWoundedBeforeDead;

        // The next 2 values are used in healProbability
        ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD_MINUS_ONE = ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD.unsafeSubtract(1);
        HEAL_PROBABILITY_MINUEND =
            ((ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD * 99 - 80) * PROBABILITY_PRECISION) /
            ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD_MINUS_ONE;

        LOOKS = constructorCalldata.looks;
        HEAL_BASE_COST = constructorCalldata.healBaseCost;

        KEY_HASH = constructorCalldata.keyHash;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(constructorCalldata.vrfCoordinator);
        SUBSCRIPTION_ID = constructorCalldata.subscriptionId;

        TRANSFER_MANAGER = ITransferManager(constructorCalldata.transferManager);
        WETH = constructorCalldata.weth;

        baseURI = constructorCalldata.baseURI;

        _updateProtocolFeeRecipient(constructorCalldata.protocolFeeRecipient);
        _updateProtocolFeeBp(constructorCalldata.protocolFeeBp);
    }

    /**
     * @dev updateProtocolFeeBp is not implemented in this contract.
     */
    function updateProtocolFeeBp(uint16) external pure override {
        revert Immutable();
    }

    /**
     * @dev updateProtocolFeeRecipient is not implemented in this contract.
     */
    function updateProtocolFeeRecipient(address) external pure override {
        revert Immutable();
    }

    /**
     * @inheritdoc IInfiltration
     */
    function setMintPeriod(uint40 newMintStart, uint40 newMintEnd) external onlyOwner {
        if (newMintStart >= newMintEnd) {
            revert InvalidMintPeriod();
        }

        if (newMintStart != 0) {
            if (block.timestamp > newMintStart) {
                revert MintStartIsInThePast();
            }

            uint256 currentMintStart = mintStart;
            if (currentMintStart != 0) {
                if (block.timestamp >= currentMintStart) {
                    revert MintAlreadyStarted();
                }
            }

            mintStart = newMintStart;
        }

        if (block.timestamp > newMintEnd || newMintEnd < mintEnd) {
            revert MintCanOnlyBeExtended();
        }

        mintEnd = newMintEnd;

        emit MintPeriodUpdated(newMintStart == 0 ? mintStart : newMintStart, newMintEnd);
    }

    /**
     * @inheritdoc IInfiltration
     * @notice As long as the game has not started (after mint end), the owner can still mint.
     */
    function premint(address to, uint256 quantity) external payable onlyOwner {
        _assertExactNativeTokensSupplied(quantity);
        _assertTotalSupplyNotBreached(quantity);
        _assertGameNotYetBegun();
        _mintERC2309(to, quantity);
    }

    /**
     * @inheritdoc IInfiltration
     */
    function mint(uint256 quantity) external payable nonReentrant {
        if (block.timestamp < mintStart || block.timestamp > mintEnd) {
            revert NotInMintPeriod();
        }

        _assertGameNotYetBegun();

        uint256 amountMinted = amountMintedPerAddress[msg.sender] + quantity;
        if (amountMinted > MAX_MINT_PER_ADDRESS) {
            revert TooManyMinted();
        }

        _assertExactNativeTokensSupplied(quantity);
        _assertTotalSupplyNotBreached(quantity);

        amountMintedPerAddress[msg.sender] = amountMinted;
        _mintERC2309(msg.sender, quantity);
    }

    /**
     * @inheritdoc IInfiltration
     * @dev If Chainlink randomness callback does not come back after 1 day, we can call
     *      startNewRound to trigger a new randomness request.
     */
    function startGame() external onlyOwner {
        uint256 numberOfAgents = totalSupply();
        if (numberOfAgents < MAX_SUPPLY) {
            if (block.timestamp < mintEnd) {
                revert StillMinting();
            }
        }
        if (numberOfAgents < NUMBER_OF_SECONDARY_PRIZE_POOL_WINNERS) {
            revert NotEnoughMinted();
        }

        _assertGameNotYetBegun();

        gameInfo.currentRoundId = 1;
        gameInfo.activeAgents = uint16(numberOfAgents);
        uint256 balance = address(this).balance;
        uint256 protocolFee = balance.unsafeMultiply(protocolFeeBp).unsafeDivide(ONE_HUNDRED_PERCENT_IN_BASIS_POINTS);
        unchecked {
            gameInfo.prizePool = balance - protocolFee;
        }

        emit RoundStarted(1);

        _transferETHAndWrapIfFailWithGasLimit(WETH, protocolFeeRecipient, protocolFee, gasleft());
        _requestForRandomness();
    }

    /**
     * @inheritdoc IInfiltration
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 activeAgents;
        uint256 woundedAgents;
        uint256 healingAgents;
        uint256 escapedAgents;
        uint256 deadAgents;
        uint256 currentRoundId;
        uint256 currentRoundBlockNumber;

        assembly {
            let gameInfoSlot0Value := sload(gameInfo.slot)
            activeAgents := and(gameInfoSlot0Value, TWO_BYTES_BITMASK)
            woundedAgents := and(shr(GAME_INFO__WOUNDED_AGENTS_OFFSET, gameInfoSlot0Value), TWO_BYTES_BITMASK)
            healingAgents := and(shr(GAME_INFO__HEALING_AGENTS_OFFSET, gameInfoSlot0Value), TWO_BYTES_BITMASK)
            escapedAgents := and(shr(GAME_INFO__ESCAPED_AGENTS_OFFSET, gameInfoSlot0Value), TWO_BYTES_BITMASK)
            deadAgents := and(shr(GAME_INFO__DEAD_AGENTS_OFFSET, gameInfoSlot0Value), TWO_BYTES_BITMASK)
            currentRoundId := and(shr(GAME_INFO__CURRENT_ROUND_ID_OFFSET, gameInfoSlot0Value), FIVE_BYTES_BITMASK)
            currentRoundBlockNumber := and(
                shr(GAME_INFO__CURRENT_ROUND_BLOCK_NUMBER_OFFSET, gameInfoSlot0Value),
                FIVE_BYTES_BITMASK
            )
        }

        bool conditionOne = currentRoundId != 0 &&
            activeAgents + woundedAgents + healingAgents + escapedAgents + deadAgents != totalSupply();

        // 50 blocks per round * 216 = 10,800 blocks which is roughly 36 hours
        // Prefer not to hard code this number as BLOCKS_PER_ROUND is not always 50
        bool conditionTwo = currentRoundId != 0 &&
            activeAgents > 1 &&
            block.number > currentRoundBlockNumber + BLOCKS_PER_ROUND * 216;

        // Just in case startGame reverts, we can withdraw the ETH balance and redistribute to addresses that participated in the mint.
        bool conditionThree = currentRoundId == 0 && block.timestamp > uint256(mintEnd).unsafeAdd(36 hours);

        if (conditionOne || conditionTwo || conditionThree) {
            uint256 ethBalance = address(this).balance;
            _transferETHAndWrapIfFailWithGasLimit(WETH, msg.sender, ethBalance, gasleft());

            uint256 looksBalance = IERC20(LOOKS).balanceOf(address(this));
            _executeERC20DirectTransfer(LOOKS, msg.sender, looksBalance);

            emit EmergencyWithdrawal(ethBalance, looksBalance);
        }
    }

    /**
     * @inheritdoc IInfiltration
     * @dev If Chainlink randomness callback does not come back after 1 day, we can try by calling
     *      startNewRound again.
     */
    function startNewRound() external nonReentrant {
        uint256 currentRoundId = gameInfo.currentRoundId;
        if (currentRoundId == 0) {
            revert GameNotYetBegun();
        }

        if (block.number < uint256(gameInfo.currentRoundBlockNumber).unsafeAdd(BLOCKS_PER_ROUND)) {
            revert TooEarlyToStartNewRound();
        }

        if (block.timestamp < uint256(gameInfo.randomnessLastRequestedAt).unsafeAdd(1 days)) {
            revert TooEarlyToRetryRandomnessRequest();
        }

        uint256 agentsRemaining = agentsAlive();
        uint256 activeAgents = gameInfo.activeAgents;
        if (agentsRemaining == 1) {
            if (activeAgents == 1) {
                revert GameOver();
            }
        }

        if (activeAgents <= NUMBER_OF_SECONDARY_PRIZE_POOL_WINNERS) {
            uint256 woundedAgents = gameInfo.woundedAgents;

            if (woundedAgents != 0) {
                uint256 killRoundId = currentRoundId > ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD
                    ? currentRoundId.unsafeSubtract(ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD)
                    : 1;
                uint256 totalDeadAgentsFromKilling;
                while (woundedAgentIdsPerRound[killRoundId][0] != 0) {
                    uint256 deadAgentsFromKilling = _killWoundedAgents({
                        currentRoundId: currentRoundId,
                        roundId: killRoundId,
                        currentRoundAgentsAlive: agentsRemaining
                    });
                    unchecked {
                        totalDeadAgentsFromKilling += deadAgentsFromKilling;
                        agentsRemaining -= deadAgentsFromKilling;
                        ++killRoundId;
                    }
                }

                // This is equivalent to
                // unchecked {
                //     gameInfo.deadAgents += uint16(totalDeadAgentsFromKilling);
                // }
                // gameInfo.woundedAgents = 0;
                assembly {
                    let gameInfoSlot0Value := sload(gameInfo.slot)
                    let deadAgents := and(shr(GAME_INFO__DEAD_AGENTS_OFFSET, gameInfoSlot0Value), TWO_BYTES_BITMASK)

                    gameInfoSlot0Value := and(
                        gameInfoSlot0Value,
                        // This is equivalent to
                        // not(
                        //     or(
                        //         shl(GAME_INFO__WOUNDED_AGENTS_OFFSET, TWO_BYTES_BITMASK),
                        //         shl(GAME_INFO__DEAD_AGENTS_OFFSET, TWO_BYTES_BITMASK)
                        //     )
                        // )
                        0xffffffffffffffffffffffffffffffffffffffffffffffff0000ffff0000ffff
                    )

                    gameInfoSlot0Value := or(
                        gameInfoSlot0Value,
                        shl(GAME_INFO__DEAD_AGENTS_OFFSET, add(deadAgents, totalDeadAgentsFromKilling))
                    )

                    sstore(gameInfo.slot, gameInfoSlot0Value)
                }
            }

            if (agentsRemaining > 1) {
                _requestForRandomness();
            } else {
                _emitWonEventIfOnlyOneAgentRemaining(agentsRemaining, activeAgents);
            }
        } else {
            _requestForRandomness();
        }
    }

    /**
     * @inheritdoc IInfiltration
     */
    function claimGrandPrize() external nonReentrant {
        _assertGameOver();
        uint256 agentId = _agentIndexToId(agents[1], 1);
        _assertAgentOwnership(agentId);

        uint256 prizePool = gameInfo.prizePool;

        if (prizePool == 0) {
            revert NothingToClaim();
        }

        gameInfo.prizePool = 0;

        _transferETHAndWrapIfFailWithGasLimit(WETH, msg.sender, prizePool, gasleft());

        emit PrizeClaimed(agentId, address(0), prizePool);
    }

    /**
     * @inheritdoc IInfiltration
     */
    function claimSecondaryPrizes(uint256 agentId) external nonReentrant {
        _assertGameOver();
        _assertAgentOwnership(agentId);

        uint256 placement = agentIndex(agentId);
        _assertValidPlacement(placement);

        uint56 _prizesClaimedBitmap = prizesClaimedBitmap;
        if ((_prizesClaimedBitmap >> placement) & 1 != 0) {
            revert NothingToClaim();
        }

        prizesClaimedBitmap = _prizesClaimedBitmap | uint56(1 << placement);

        uint256 ethAmount = secondaryPrizePoolShareAmount(gameInfo.secondaryPrizePool, placement);
        if (ethAmount != 0) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, msg.sender, ethAmount, gasleft());
            emit PrizeClaimed(agentId, address(0), ethAmount);
        }

        uint256 secondaryLooksPrizePool = gameInfo.secondaryLooksPrizePool;
        if (secondaryLooksPrizePool == 0) {
            secondaryLooksPrizePool = IERC20(LOOKS).balanceOf(address(this));
            if (secondaryLooksPrizePool == 0) {
                return;
            }
            gameInfo.secondaryLooksPrizePool = secondaryLooksPrizePool;
        }

        uint256 looksAmount = secondaryPrizePoolShareAmount(secondaryLooksPrizePool, placement);
        if (looksAmount != 0) {
            _executeERC20DirectTransfer(LOOKS, msg.sender, looksAmount);
            emit PrizeClaimed(agentId, LOOKS, looksAmount);
        }
    }

    /**
     * @inheritdoc IInfiltration
     */
    function escape(uint256[] calldata agentIds) external nonReentrant {
        _assertFrontrunLockIsOff();

        uint256 agentIdsCount = agentIds.length;
        _assertNotEmptyAgentIdsArrayProvided(agentIdsCount);

        uint256 activeAgents = gameInfo.activeAgents;
        uint256 activeAgentsAfterEscape = activeAgents - agentIdsCount;
        _assertGameIsNotOverAfterEscape(activeAgentsAfterEscape);

        uint256 currentRoundAgentsAlive = agentsAlive();

        uint256 prizePool = gameInfo.prizePool;
        uint256 secondaryPrizePool = gameInfo.secondaryPrizePool;
        uint256 reward;
        uint256[] memory rewards = new uint256[](agentIdsCount);

        for (uint256 i; i < agentIdsCount; ) {
            uint256 agentId = agentIds[i];
            _assertAgentOwnership(agentId);

            uint256 index = agentIndex(agentId);
            _assertAgentStatus(agents[index], agentId, AgentStatus.Active);

            uint256 totalEscapeValue = prizePool / currentRoundAgentsAlive;
            uint256 rewardForPlayer = (totalEscapeValue * _escapeMultiplier(currentRoundAgentsAlive)) /
                ONE_HUNDRED_PERCENT_IN_BASIS_POINTS;
            rewards[i] = rewardForPlayer;
            reward += rewardForPlayer;

            uint256 rewardToSecondaryPrizePool = (totalEscapeValue.unsafeSubtract(rewardForPlayer) *
                _escapeRewardSplitForSecondaryPrizePool(currentRoundAgentsAlive)) / ONE_HUNDRED_PERCENT_IN_BASIS_POINTS;

            unchecked {
                prizePool = prizePool - rewardForPlayer - rewardToSecondaryPrizePool;
            }
            secondaryPrizePool += rewardToSecondaryPrizePool;

            _swap({
                currentAgentIndex: index,
                lastAgentIndex: currentRoundAgentsAlive,
                agentId: agentId,
                newStatus: AgentStatus.Escaped
            });

            unchecked {
                --currentRoundAgentsAlive;
                ++i;
            }
        }

        // This is equivalent to
        // unchecked {
        //     gameInfo.activeAgents = uint16(activeAgentsAfterEscape);
        //     gameInfo.escapedAgents += uint16(agentIdsCount);
        // }
        assembly {
            let gameInfoSlot0Value := sload(gameInfo.slot)
            let escapedAgents := add(
                and(shr(GAME_INFO__ESCAPED_AGENTS_OFFSET, gameInfoSlot0Value), TWO_BYTES_BITMASK),
                agentIdsCount
            )

            gameInfoSlot0Value := and(
                gameInfoSlot0Value,
                // This is the equivalent of not(or(TWO_BYTES_BITMASK, shl(GAME_INFO__ESCAPED_AGENTS_OFFSET, TWO_BYTES_BITMASK)))
                0xffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffff0000
            )
            gameInfoSlot0Value := or(gameInfoSlot0Value, activeAgentsAfterEscape)
            gameInfoSlot0Value := or(gameInfoSlot0Value, shl(GAME_INFO__ESCAPED_AGENTS_OFFSET, escapedAgents))
            sstore(gameInfo.slot, gameInfoSlot0Value)
        }

        gameInfo.prizePool = prizePool;
        gameInfo.secondaryPrizePool = secondaryPrizePool;

        _transferETHAndWrapIfFailWithGasLimit(WETH, msg.sender, reward, gasleft());
        emit Escaped(gameInfo.currentRoundId, agentIds, rewards);

        _emitWonEventIfOnlyOneAgentRemaining(currentRoundAgentsAlive, activeAgentsAfterEscape);
    }

    /**
     * @inheritdoc IInfiltration
     */
    function heal(uint256[] calldata agentIds) external nonReentrant {
        _assertFrontrunLockIsOff();

        if (gameInfo.activeAgents <= NUMBER_OF_SECONDARY_PRIZE_POOL_WINNERS) {
            revert HealingDisabled();
        }

        uint256 agentIdsCount = agentIds.length;
        _assertNotEmptyAgentIdsArrayProvided(agentIdsCount);

        uint256 currentRoundId = gameInfo.currentRoundId;
        uint16[MAXIMUM_HEALING_OR_WOUNDED_AGENTS_PER_ROUND_AND_LENGTH]
            storage healingAgentIds = healingAgentIdsPerRound[currentRoundId];
        uint256 currentHealingAgentIdsCount = healingAgentIds[0];

        uint256 newHealingAgentIdsCount = currentHealingAgentIdsCount.unsafeAdd(agentIdsCount);

        if (newHealingAgentIdsCount > MAXIMUM_HEALING_OR_WOUNDED_AGENTS_PER_ROUND) {
            revert MaximumHealingRequestPerRoundExceeded();
        }

        uint256 cost;
        uint256[] memory costs = new uint256[](agentIdsCount);

        for (uint256 i; i < agentIdsCount; ) {
            uint256 agentId = agentIds[i];

            uint256 index = agentIndex(agentId);
            _assertAgentStatus(agents[index], agentId, AgentStatus.Wounded);

            bytes32 agentSlot = _getAgentStorageSlot(index);
            uint256 agentSlotValue;
            uint256 woundedAt;

            // This is equivalent to
            // uint256 woundedAt = agent.woundedAt;
            assembly {
                agentSlotValue := sload(agentSlot)
                woundedAt := and(shr(AGENT__WOUNDED_AT_OFFSET, agentSlotValue), FIVE_BYTES_BITMASK)
            }

            // This is equivalent to
            // healCount = agent.healCount;
            // agent.status = AgentStatus.Healing;
            uint256 healCount;
            assembly {
                healCount := and(shr(AGENT__HEAL_COUNT_OFFSET, agentSlotValue), TWO_BYTES_BITMASK)

                agentSlotValue := and(
                    agentSlotValue,
                    // This is the equivalent of not(shl(AGENT__STATUS_OFFSET, 0xff))
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffff
                )
                agentSlotValue := or(
                    agentSlotValue,
                    // AgentStatus.Healing is 2
                    // This is equivalent to shl(AGENT__STATUS_OFFSET, 2)
                    0x20000
                )
                sstore(agentSlot, agentSlotValue)
            }

            costs[i] = _costToHeal(healCount);
            cost += costs[i];

            unchecked {
                ++i;
                healingAgentIds[currentHealingAgentIdsCount + i] = uint16(agentId);
            }
        }

        healingAgentIds[0] = uint16(newHealingAgentIdsCount);

        // This is equivalent to
        // unchecked {
        //     gameInfo.healingAgents += uint16(agentIdsCount);
        //     gameInfo.woundedAgents -= uint16(agentIdsCount);
        // }
        assembly {
            let gameInfoSlot0Value := sload(gameInfo.slot)
            let healingAgents := add(
                and(shr(GAME_INFO__HEALING_AGENTS_OFFSET, gameInfoSlot0Value), TWO_BYTES_BITMASK),
                agentIdsCount
            )
            let woundedAgents := sub(
                and(shr(GAME_INFO__WOUNDED_AGENTS_OFFSET, gameInfoSlot0Value), TWO_BYTES_BITMASK),
                agentIdsCount
            )

            gameInfoSlot0Value := and(
                gameInfoSlot0Value,
                // This is equivalent to
                // not(
                //     or(
                //         shl(GAME_INFO__HEALING_AGENTS_OFFSET, TWO_BYTES_BITMASK),
                //         shl(GAME_INFO__WOUNDED_AGENTS_OFFSET, TWO_BYTES_BITMASK)
                //     )
                // )
                0xffffffffffffffffffffffffffffffffffffffffffffffffffff00000000ffff
            )
            gameInfoSlot0Value := or(gameInfoSlot0Value, shl(GAME_INFO__HEALING_AGENTS_OFFSET, healingAgents))
            gameInfoSlot0Value := or(gameInfoSlot0Value, shl(GAME_INFO__WOUNDED_AGENTS_OFFSET, woundedAgents))
            sstore(gameInfo.slot, gameInfoSlot0Value)
        }

        TRANSFER_MANAGER.transferERC20(LOOKS, msg.sender, address(this), cost);
        _executeERC20DirectTransfer(LOOKS, 0x000000000000000000000000000000000000dEaD, cost / 4);

        emit HealRequestSubmitted(currentRoundId, agentIds, costs);
    }

    /**
     * @notice Only active and wounded agents are allowed to be transferred or traded.
     * @param from The current owner of the token.
     * @param to The new owner of the token.
     * @param tokenId The token ID.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        AgentStatus status = agents[agentIndex(tokenId)].status;
        if (status > AgentStatus.Wounded) {
            revert InvalidAgentStatus(tokenId, status);
        }
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IInfiltration
     */
    function getAgent(uint256 index) external view returns (Agent memory agent) {
        agent = agents[index];
        agent.agentId = uint16(_agentIndexToId(agents[index], index));
    }

    /**
     * @inheritdoc IInfiltration
     * @dev Unlike the actual heal function, this function does not revert if duplicated agent IDs are provided.
     */
    function costToHeal(uint256[] calldata agentIds) external view returns (uint256 cost) {
        uint256 agentIdsCount = agentIds.length;

        for (uint256 i; i < agentIdsCount; ) {
            uint256 agentId = agentIds[i];
            Agent storage agent = agents[agentIndex(agentId)];
            _assertAgentStatus(agent, agentId, AgentStatus.Wounded);

            cost += _costToHeal(agent.healCount);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IInfiltration
     * @dev Unlike the actual escape function, this function does not revert if duplicated agent IDs are provided.
     */
    function escapeReward(uint256[] calldata agentIds) external view returns (uint256 reward) {
        uint256 agentIdsCount = agentIds.length;
        _assertGameIsNotOverAfterEscape(gameInfo.activeAgents - agentIdsCount);

        uint256 currentRoundAgentsAlive = agentsAlive();

        uint256 prizePool = gameInfo.prizePool;
        uint256 secondaryPrizePool = gameInfo.secondaryPrizePool;

        for (uint256 i; i < agentIdsCount; ) {
            uint256 agentId = agentIds[i];

            uint256 index = agentIndex(agentId);
            _assertAgentStatus(agents[index], agentId, AgentStatus.Active);

            uint256 totalEscapeValue = prizePool / currentRoundAgentsAlive;
            uint256 rewardForPlayer = (totalEscapeValue * _escapeMultiplier(currentRoundAgentsAlive)) /
                ONE_HUNDRED_PERCENT_IN_BASIS_POINTS;
            reward += rewardForPlayer;

            uint256 rewardToSecondaryPrizePool = (totalEscapeValue.unsafeSubtract(rewardForPlayer) *
                _escapeRewardSplitForSecondaryPrizePool(currentRoundAgentsAlive)) / ONE_HUNDRED_PERCENT_IN_BASIS_POINTS;

            secondaryPrizePool += rewardToSecondaryPrizePool;

            unchecked {
                prizePool = prizePool - rewardForPlayer - rewardToSecondaryPrizePool;
                --currentRoundAgentsAlive;
                ++i;
            }
        }
    }

    /**
     * @notice
     *
     * Variables:
     * Attempted_Heal_Round - the round at which a user attempts to heal - this is x
     * Heal_Rounds_Maximum - the maximum number of rounds after a user is wounded in which they can heal (ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD) - this is x2
     * Heal_Rounds_Minimum - the minimum number of rounds after a user is wounded until they can heal (a user cannot heal the same round as wound, so we select one round after wound hence 1) - this is x1
     * Maximum_Heal_Percentage - the maximum % chance a user can heal for, this will be if they heal in Heal_Rounds_Minimum (we have set this to 99% of a successful healing) - this is y1
     * Minimum_Heal_Percentage - the minimum % chance a user can heal for, this will be if they heal in Heal_Rounds_Maximum (we have set this to 80% of a successful healing) - this is y2
     *
     * Equation:

     * If you substitute all of these into the following equation:
     * y = (( x * (y2-y1)) / (x2-x1)) + ((x2 * y1 - x1 * y2) / (x2 - x1))

     * You will get an equation for y which is the PercentageChanceToHealSuccessfully given an Attempted_Heal_Round number.

     * Explanation:
     * i.e if a user is wounded in round 2, and they try to heal in round 4, their Attempted_Heal_Round relative to themselves is 2, hence by subsituting 2 into the place of x in the above equation, their PercentageChanceToHealSuccessfully will be 98.59574468%.
     *
     * @param healingRoundsDelay The number of rounds elapsed since the agent was wounded.
     */
    function healProbability(uint256 healingRoundsDelay) public view returns (uint256 y) {
        if (healingRoundsDelay == 0 || healingRoundsDelay > ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD) {
            revert InvalidHealingRoundsDelay();
        }

        y =
            HEAL_PROBABILITY_MINUEND -
            ((healingRoundsDelay * 19) * PROBABILITY_PRECISION) /
            ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD_MINUS_ONE;
    }

    /**
     * @notice The formula is 80 - 50 * PercentageOfAgentsRemaining ** 2.
     */
    function escapeMultiplier() public view returns (uint256 multiplier) {
        multiplier = _escapeMultiplier(agentsAlive());
    }

    /**
     * @notice The formula is the lesser of (9,980 / 99) - (UsersRemaining / TotalUsers) * (8,000 / 99) and 100.
     */
    function escapeRewardSplitForSecondaryPrizePool() public view returns (uint256 split) {
        split = _escapeRewardSplitForSecondaryPrizePool(agentsAlive());
    }

    /**
     * @notice An agent's secondary prize pool share amount. The formula is 1.31487 * 995 / (placement * 49) - 15 / 49.
     * @param secondaryPrizePoolAmount The secondary prize pool amount.
     * @param placement The agent's rank in the leaderboard. This is not meant to be called with placement that is not between 1 and NUMBER_OF_SECONDARY_PRIZE_POOL_WINNERS.
     */
    function secondaryPrizePoolShareAmount(
        uint256 secondaryPrizePoolAmount,
        uint256 placement
    ) public pure returns (uint256 shareAmount) {
        shareAmount =
            (secondaryPrizePoolAmount * secondaryPrizePoolShareBp(placement)) /
            ONE_HUNDRED_PERCENT_IN_BASIS_POINTS;
    }

    /**
     * @notice An agent's secondary prize pool share in basis points. The formula is 1.31817 * 995 / (placement * 49) - 15 / 49.
     * @param placement The agent's rank in the leaderboard. This is not meant to be called with placement that is not between 1 and NUMBER_OF_SECONDARY_PRIZE_POOL_WINNERS.
     */
    function secondaryPrizePoolShareBp(uint256 placement) public pure returns (uint256 share) {
        share = (1_31817 * (995_000_000 / (placement * 49) - uint256(15_000_000) / 49)) / 1_000_000_000;
    }

    /**
     * @inheritdoc IInfiltration
     */
    function agentsAlive() public view returns (uint256) {
        return totalSupply() - gameInfo.deadAgents - gameInfo.escapedAgents;
    }

    /**
     * @inheritdoc IInfiltration
     */
    function agentIndex(uint256 agentId) public view returns (uint256 index) {
        index = agentIdToIndex[agentId];
        if (index == 0) {
            index = agentId;
        }
    }

    /**
     * @inheritdoc IInfiltration
     */
    function getRoundInfo(
        uint256 roundId
    ) external view returns (uint256[] memory woundedAgentIds, uint256[] memory healingAgentIds) {
        woundedAgentIds = _buildAgentIdsPerRoundArray(woundedAgentIdsPerRound[roundId]);
        healingAgentIds = _buildAgentIdsPerRoundArray(healingAgentIdsPerRound[roundId]);
    }

    /**
     * @param requestId The VRF request ID.
     * @param randomWords The random words returned from Chainlink. We only request 1 random word.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        RandomnessRequest storage randomnessRequest = randomnessRequests[requestId];

        uint256 currentRoundId = gameInfo.currentRoundId;
        uint256 randomnessRequestRoundId = randomnessRequest.roundId;
        if (
            randomnessRequestRoundId != currentRoundId || randomnessRequest.status != RandomnessRequestStatus.Requested
        ) {
            emit InvalidRandomnessFulfillment(requestId, randomnessRequestRoundId, currentRoundId);
            return;
        }

        randomnessRequest.randomWord = randomWords[0];
        randomnessRequest.status = RandomnessRequestStatus.Fulfilled;

        emit RandomnessFulfilled(randomnessRequest.roundId, requestId);
    }

    /**
     * @inheritdoc IInfiltration
     */
    function closeRound(uint256 requestId) external {
        uint256 currentRoundId = gameInfo.currentRoundId;
        RandomnessRequest storage randomnessRequest = randomnessRequests[requestId];
        if (
            randomnessRequest.roundId != currentRoundId || randomnessRequest.status != RandomnessRequestStatus.Fulfilled
        ) {
            revert InvalidRandomnessRequestId();
        }

        uint256 currentRandomWord = randomnessRequest.randomWord;

        uint256 currentRoundAgentsAlive = agentsAlive();
        uint256 activeAgents = gameInfo.activeAgents;
        uint256 healingAgents = gameInfo.healingAgents;

        uint256 deadAgentsFromHealing;

        if (healingAgents != 0) {
            uint256 healedAgents;
            (healedAgents, deadAgentsFromHealing, currentRandomWord) = _healRequestFulfilled(
                currentRoundId,
                currentRoundAgentsAlive,
                currentRandomWord
            );
            unchecked {
                currentRoundAgentsAlive -= deadAgentsFromHealing;
                activeAgents += healedAgents;
                gameInfo.healingAgents = uint16(healingAgents - healedAgents - deadAgentsFromHealing);
            }
        }

        if (activeAgents > NUMBER_OF_SECONDARY_PRIZE_POOL_WINNERS) {
            uint256 woundedAgents = _woundRequestFulfilled(
                currentRoundId,
                currentRoundAgentsAlive,
                activeAgents,
                currentRandomWord
            );

            uint256 deadAgentsFromKilling;
            if (currentRoundId > ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD) {
                deadAgentsFromKilling = _killWoundedAgents({
                    currentRoundId: currentRoundId,
                    roundId: currentRoundId.unsafeSubtract(ROUNDS_TO_BE_WOUNDED_BEFORE_DEAD),
                    currentRoundAgentsAlive: currentRoundAgentsAlive
                });
            }

            // We only need to deduct wounded agents from active agents, dead agents from killing are already inactive.

            // This is equivalent to
            // unchecked {
            //     gameInfo.activeAgents = activeAgents - woundedAgents;
            //     gameInfo.woundedAgents = gameInfo.woundedAgents + woundedAgents - deadAgentsFromKilling;
            //     gameInfo.deadAgents += (deadAgentsFromHealing + deadAgentsFromKilling);
            // }
            // SSTORE is called in _incrementRound
            uint256 gameInfoSlot0Value;
            assembly {
                gameInfoSlot0Value := sload(gameInfo.slot)

                let currentWoundedAgents := and(
                    shr(GAME_INFO__WOUNDED_AGENTS_OFFSET, gameInfoSlot0Value),
                    TWO_BYTES_BITMASK
                )
                let currentDeadAgents := and(shr(GAME_INFO__DEAD_AGENTS_OFFSET, gameInfoSlot0Value), TWO_BYTES_BITMASK)

                gameInfoSlot0Value := and(
                    gameInfoSlot0Value,
                    // This is equivalent to
                    // not(
                    //     or(
                    //         TWO_BYTES_BITMASK,
                    //         or(
                    //             shl(GAME_INFO__WOUNDED_AGENTS_OFFSET, TWO_BYTES_BITMASK),
                    //             shl(GAME_INFO__DEAD_AGENTS_OFFSET, TWO_BYTES_BITMASK)
                    //         )
                    //     )
                    // )
                    0xffffffffffffffffffffffffffffffffffffffffffffffff0000ffff00000000
                )
                gameInfoSlot0Value := or(gameInfoSlot0Value, sub(activeAgents, woundedAgents))

                gameInfoSlot0Value := or(
                    gameInfoSlot0Value,
                    shl(
                        GAME_INFO__WOUNDED_AGENTS_OFFSET,
                        sub(add(currentWoundedAgents, woundedAgents), deadAgentsFromKilling)
                    )
                )

                gameInfoSlot0Value := or(
                    gameInfoSlot0Value,
                    shl(
                        GAME_INFO__DEAD_AGENTS_OFFSET,
                        add(currentDeadAgents, add(deadAgentsFromHealing, deadAgentsFromKilling))
                    )
                )
            }
            _incrementRound(currentRoundId, gameInfoSlot0Value);
        } else {
            bool shouldKillOneAgent = activeAgents > 1;
            if (shouldKillOneAgent) {
                uint256 killedAgentIndex = (currentRandomWord % activeAgents).unsafeAdd(1);
                Agent storage agentToKill = agents[killedAgentIndex];
                uint256 agentId = _agentIndexToId(agentToKill, killedAgentIndex);
                _swap({
                    currentAgentIndex: killedAgentIndex,
                    lastAgentIndex: currentRoundAgentsAlive,
                    agentId: agentId,
                    newStatus: AgentStatus.Dead
                });

                uint256[] memory killedAgentId = new uint256[](1);
                killedAgentId[0] = agentId;
                emit Killed(currentRoundId, killedAgentId);

                unchecked {
                    --activeAgents;
                    --currentRoundAgentsAlive;
                }
            }

            // This is equivalent to
            // unchecked {
            //     gameInfo.activeAgents = activeAgents;
            //     gameInfo.deadAgents = gameInfo.deadAgents + deadAgentsFromHealing + 1;
            // }
            // SSTORE is called in _incrementRound
            uint256 gameInfoSlot0Value;
            assembly {
                gameInfoSlot0Value := sload(gameInfo.slot)
                let deadAgents := and(shr(GAME_INFO__DEAD_AGENTS_OFFSET, gameInfoSlot0Value), TWO_BYTES_BITMASK)

                gameInfoSlot0Value := and(
                    gameInfoSlot0Value,
                    // This is equivalent to not(or(TWO_BYTES_BITMASK, shl(GAME_INFO__DEAD_AGENTS_OFFSET, TWO_BYTES_BITMASK)))
                    0xffffffffffffffffffffffffffffffffffffffffffffffff0000ffffffff0000
                )
                gameInfoSlot0Value := or(gameInfoSlot0Value, activeAgents)
                // If shouldKillOneAgent is true, then add 1. If false, then add 0.
                gameInfoSlot0Value := or(
                    gameInfoSlot0Value,
                    shl(GAME_INFO__DEAD_AGENTS_OFFSET, add(add(deadAgents, deadAgentsFromHealing), shouldKillOneAgent))
                )
            }

            _emitWonEventIfOnlyOneAgentRemaining(currentRoundAgentsAlive, activeAgents);
            _incrementRound(currentRoundId, gameInfoSlot0Value);
        }

        frontrunLock = FRONTRUN_LOCK__UNLOCKED;

        unchecked {
            emit RoundStarted(currentRoundId + 1);
        }
    }

    /**
     * @dev This function doesn't check currentRoundId to be <= type(uint40).max but it's fine as
     *      it's practically impossible to reach this number of rounds.
     * @param currentRoundId The current round ID.
     * @param gameInfoSlot0Value The value of gameInfo.slot.
     */
    function _incrementRound(uint256 currentRoundId, uint256 gameInfoSlot0Value) private {
        // This is equivalent to
        // unchecked {
        //     uint256 newRoundId = currentRoundId + 1;
        //     gameInfo.currentRoundId = newRoundId;
        //     gameInfo.currentRoundBlockNumber = uint40(block.number);
        //     gameInfo.randomnessLastRequestedAt = 0;
        // }
        assembly {
            gameInfoSlot0Value := and(
                gameInfoSlot0Value,
                // This is equivalent to
                // let gameInfoRandomnessLastRequestedAtOffset := 160
                // not(
                //     or(
                //         or(
                //             shl(GAME_INFO__CURRENT_ROUND_ID_OFFSET, FIVE_BYTES_BITMASK),
                //             shl(GAME_INFO__CURRENT_ROUND_BLOCK_NUMBER_OFFSET, FIVE_BYTES_BITMASK)
                //         ),
                //         shl(gameInfoRandomnessLastRequestedAtOffset, FIVE_BYTES_BITMASK)
                //     )
                // )
                0xffffffffffffff000000000000000000000000000000ffffffffffffffffffff
            )
            gameInfoSlot0Value := or(
                gameInfoSlot0Value,
                shl(GAME_INFO__CURRENT_ROUND_ID_OFFSET, add(currentRoundId, 1))
            )
            gameInfoSlot0Value := or(gameInfoSlot0Value, shl(GAME_INFO__CURRENT_ROUND_BLOCK_NUMBER_OFFSET, number()))
            sstore(gameInfo.slot, gameInfoSlot0Value)
        }
    }

    /**
     * @dev This function requests for a random word from Chainlink VRF for wounding and healing.
     */
    function _requestForRandomness() private {
        uint256 requestId = VRF_COORDINATOR.requestRandomWords({
            keyHash: KEY_HASH,
            subId: SUBSCRIPTION_ID,
            minimumRequestConfirmations: uint16(3),
            callbackGasLimit: uint32(2_500_000),
            numWords: uint32(1)
        });

        if (randomnessRequests[requestId].status != RandomnessRequestStatus.None) {
            revert RandomnessRequestAlreadyExists();
        }

        uint40 currentRoundId = gameInfo.currentRoundId;

        gameInfo.randomnessLastRequestedAt = uint40(block.timestamp);

        // This is equivalent to
        // randomnessRequests[requestId].status = RandomnessRequestStatus.Requested;
        // randomnessRequests[requestId].roundId = currentRoundId;
        assembly {
            // 1 is RandomnessRequestStatus.Requested
            let randomnessRequest := or(1, shl(RANDOMNESS_REQUESTS__EXISTS_OFFSET, currentRoundId))
            mstore(0x00, requestId)
            mstore(0x20, randomnessRequests.slot)
            let randomnessRequestStoragSlot := keccak256(0x00, 0x40)
            sstore(randomnessRequestStoragSlot, randomnessRequest)
        }

        frontrunLock = FRONTRUN_LOCK__LOCKED;

        emit RandomnessRequested(currentRoundId, requestId);
    }

    /**
     * @param roundId The current round ID.
     * @param currentRoundAgentsAlive The number of agents alive currently.
     * @param randomWord The random word returned from Chainlink.
     * @return healedAgentsCount The number of agents that were healed.
     * @return deadAgentsCount The number of agents that were killed.
     * @return currentRandomWord The current random word after running the function.
     */
    function _healRequestFulfilled(
        uint256 roundId,
        uint256 currentRoundAgentsAlive,
        uint256 randomWord
    ) private returns (uint256 healedAgentsCount, uint256 deadAgentsCount, uint256 currentRandomWord) {
        uint16[MAXIMUM_HEALING_OR_WOUNDED_AGENTS_PER_ROUND_AND_LENGTH]
            storage healingAgentIds = healingAgentIdsPerRound[roundId];
        uint256 healingAgentIdsCount = healingAgentIds[0];

        if (healingAgentIdsCount != 0) {
            HealResult[] memory healResults = new HealResult[](healingAgentIdsCount);

            for (uint256 i; i < healingAgentIdsCount; ) {
                uint256 healingAgentId = healingAgentIds[i.unsafeAdd(1)];
                uint256 index = agentIndex(healingAgentId);
                Agent storage agent = agents[index];

                healResults[i].agentId = healingAgentId;

                // 1. An agent's "healing at" round ID is always equal to the current round ID
                //    as it immediately settles upon randomness fulfillment.
                //
                // 2. 10_000_000_000 == 100 * PROBABILITY_PRECISION
                if (randomWord % 10_000_000_000 <= healProbability(roundId.unsafeSubtract(agent.woundedAt))) {
                    // This line is not needed as HealOutcome.Healed is 0. It is here for clarity.
                    // healResults[i].outcome = HealOutcome.Healed;
                    _healAgent(agent);
                } else {
                    healResults[i].outcome = HealOutcome.Killed;
                    _swap({
                        currentAgentIndex: index,
                        lastAgentIndex: currentRoundAgentsAlive - deadAgentsCount,
                        agentId: healingAgentId,
                        newStatus: AgentStatus.Dead
                    });
                    unchecked {
                        ++deadAgentsCount;
                    }
                }

                randomWord = _nextRandomWord(randomWord);

                unchecked {
                    ++i;
                }
            }

            unchecked {
                healedAgentsCount = healingAgentIdsCount - deadAgentsCount;
            }

            emit HealRequestFulfilled(roundId, healResults);
        }

        currentRandomWord = randomWord;
    }

    /**
     * @param roundId The current round ID.
     * @param currentRoundAgentsAlive The number of agents alive currently.
     * @param activeAgents The number of currently active agents.
     * @param randomWord The random word returned from Chainlink.
     * @return woundedAgentsCount The number of agents that were wounded.
     */
    function _woundRequestFulfilled(
        uint256 roundId,
        uint256 currentRoundAgentsAlive,
        uint256 activeAgents,
        uint256 randomWord
    ) private returns (uint256 woundedAgentsCount) {
        woundedAgentsCount =
            (activeAgents * AGENTS_TO_WOUND_PER_ROUND_IN_BASIS_POINTS) /
            ONE_HUNDRED_PERCENT_IN_BASIS_POINTS;
        // At some point the number of agents to wound will be 0 due to round down, so we set it to 1.
        if (woundedAgentsCount == 0) {
            woundedAgentsCount = 1;
        }

        uint256[] memory woundedAgentIds = new uint256[](woundedAgentsCount);
        uint16[MAXIMUM_HEALING_OR_WOUNDED_AGENTS_PER_ROUND_AND_LENGTH]
            storage currentRoundWoundedAgentIds = woundedAgentIdsPerRound[roundId];

        for (uint256 i; i < woundedAgentsCount; ) {
            uint256 woundedAgentIndex = (randomWord % currentRoundAgentsAlive).unsafeAdd(1);
            Agent storage agentToWound = agents[woundedAgentIndex];

            if (agentToWound.status == AgentStatus.Active) {
                // This is equivalent to
                // agentToWound.status = AgentStatus.Wounded;
                // agentToWound.woundedAt = roundId;
                assembly {
                    let agentSlotValue := sload(agentToWound.slot)
                    agentSlotValue := and(
                        agentSlotValue,
                        // This is equivalent to
                        // or(
                        //     TWO_BYTES_BITMASK,
                        //     shl(64, TWO_BYTES_BITMASK)
                        // )
                        0x00000000000000000000000000000000000000000000ffff000000000000ffff
                    )
                    // AgentStatus.Wounded is 1
                    agentSlotValue := or(agentSlotValue, shl(AGENT__STATUS_OFFSET, 1))
                    agentSlotValue := or(agentSlotValue, shl(AGENT__WOUNDED_AT_OFFSET, roundId))
                    sstore(agentToWound.slot, agentSlotValue)
                }

                uint256 woundedAgentId = _agentIndexToId(agentToWound, woundedAgentIndex);
                woundedAgentIds[i] = woundedAgentId;

                unchecked {
                    ++i;
                    currentRoundWoundedAgentIds[i] = uint16(woundedAgentId);
                }
            }

            randomWord = _nextRandomWord(randomWord);
        }

        currentRoundWoundedAgentIds[0] = uint16(woundedAgentsCount);

        emit Wounded(roundId, woundedAgentIds);
    }

    /**
     * @dev This function emits the Killed event but some agent IDs in the array can be 0 because
     *      they might have been healed or are dead already.
     * @param currentRoundId The current round ID.
     * @param roundId The round ID in which the wounded agents should be killed.
     * @param currentRoundAgentsAlive The number of agents alive currently.
     * @return deadAgentsCount The number of agents that were killed.
     */
    function _killWoundedAgents(
        uint256 currentRoundId,
        uint256 roundId,
        uint256 currentRoundAgentsAlive
    ) private returns (uint256 deadAgentsCount) {
        uint16[MAXIMUM_HEALING_OR_WOUNDED_AGENTS_PER_ROUND_AND_LENGTH]
            storage woundedAgentIdsInRound = woundedAgentIdsPerRound[roundId];
        uint256 woundedAgentIdsCount = woundedAgentIdsInRound[0];
        uint256[] memory woundedAgentIds = new uint256[](woundedAgentIdsCount);
        for (uint256 i; i < woundedAgentIdsCount; ) {
            uint256 woundedAgentId = woundedAgentIdsInRound[i.unsafeAdd(1)];
            uint256 index = agentIndex(woundedAgentId);
            Agent storage agent = agents[index];
            if (agent.status == AgentStatus.Wounded) {
                if (agent.woundedAt == roundId) {
                    woundedAgentIds[i] = woundedAgentId;
                    _swap({
                        currentAgentIndex: index,
                        lastAgentIndex: currentRoundAgentsAlive - deadAgentsCount,
                        agentId: woundedAgentId,
                        newStatus: AgentStatus.Dead
                    });
                    unchecked {
                        ++deadAgentsCount;
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        emit Killed(currentRoundId, woundedAgentIds);
    }

    /**
     * @param agent The agent to check.
     * @param index The agent's index in the agents mapping.
     * @return agentId The agent's ID.
     */
    function _agentIndexToId(Agent storage agent, uint256 index) private view returns (uint256 agentId) {
        agentId = agent.agentId;
        agentId = agentId == 0 ? index : agentId;
    }

    /**
     * @param healCount The number of times the agent has been successfully healed.
     * @return cost The cost to heal the agent based on the agent's successful heal count.
     */
    function _costToHeal(uint256 healCount) private view returns (uint256 cost) {
        cost = HEAL_BASE_COST * (2 ** healCount);
    }

    /**
     * @param agent The agent to heal.
     */
    function _healAgent(Agent storage agent) private {
        // This is equivalent to
        // agent.status = AgentStatus.Active;
        // agent.woundedAt = 0;
        // lastHealCount = agent.healCount;
        // ++agent.healCount;
        assembly {
            let agentSlotValue := sload(agent.slot)
            let lastHealCount := and(shr(AGENT__HEAL_COUNT_OFFSET, agentSlotValue), TWO_BYTES_BITMASK)
            agentSlotValue := and(agentSlotValue, TWO_BYTES_BITMASK)
            agentSlotValue := or(agentSlotValue, shl(AGENT__HEAL_COUNT_OFFSET, add(lastHealCount, 1)))
            sstore(agent.slot, agentSlotValue)
        }
    }

    /**
     * @notice An agent is killed by swapping it with the last agent in the agents mapping and decrementing `agentsAlive`
     *         by adding 1 to `gameInfo.deadAgents`.
     * @notice An agent escapes by swapping it with the last agent in the agents mapping and decrementing `agentsAlive`
     *         by adding 1 to `gameInfo.escapedAgents`.
     * @param currentAgentIndex The agent (whose status is being updated)'s index in the agents mapping.
     * @param lastAgentIndex Last agent's index in the agents mapping.
     * @param agentId The agent (whose status is being updated) 's ID.
     * @param newStatus The new status of the agent.
     */
    function _swap(uint256 currentAgentIndex, uint256 lastAgentIndex, uint256 agentId, AgentStatus newStatus) private {
        Agent storage lastAgent = agents[lastAgentIndex];
        uint256 lastAgentId = _agentIndexToId(lastAgent, lastAgentIndex);

        agentIdToIndex[agentId] = lastAgentIndex;
        agentIdToIndex[lastAgentId] = currentAgentIndex;

        /**
         * If last agent's agent ID is 0 that means it was never touched and is active.
         *
         * This is equivalent to
         *
         * agent.agentId = uint16(lastAgentId);
         * agent.status = lastAgent.status;
         * agent.woundedAt = lastAgent.woundedAt;
         * agent.healCount = lastAgent.healCount;

         * lastAgent.agentId = uint16(agentId);
         * lastAgent.status = newStatus;
         * lastAgent.woundedAt = 0;
         * lastAgent.healCount = 0;
         */
        bytes32 currentAgentSlot = _getAgentStorageSlot(currentAgentIndex);
        bytes32 lastAgentSlot = _getAgentStorageSlot(lastAgentIndex);

        assembly {
            let lastAgentCurrentValue := sload(lastAgentSlot)
            // The last agent's ID is either 0 or lastAgentId, so we do not need to clear the last 16 bits
            // as it can only be or(0, lastAgentId) or or(lastAgentId, lastAgentId) which both ends up being lastAgentId.
            lastAgentCurrentValue := or(lastAgentCurrentValue, lastAgentId)
            sstore(currentAgentSlot, lastAgentCurrentValue)

            let lastAgentNewValue := agentId
            lastAgentNewValue := or(lastAgentNewValue, shl(AGENT__STATUS_OFFSET, newStatus))
            sstore(lastAgentSlot, lastAgentNewValue)
        }
    }

    /**
     * @notice Returns the next random word by hashing.
     * @param randomWord The current random word.
     * @return nextRandomWord The next random word.
     */
    function _nextRandomWord(uint256 randomWord) private pure returns (uint256 nextRandomWord) {
        // This is equivalent to
        // randomWord = uint256(keccak256(abi.encode(randomWord)));
        assembly {
            mstore(0x00, randomWord)
            nextRandomWord := keccak256(0x00, 0x20)
        }
    }

    /**
     * @param index The agent's index in the agents mapping.
     * @return agentStorageSlot The agent's storage slot.
     */
    function _getAgentStorageSlot(uint256 index) private pure returns (bytes32 agentStorageSlot) {
        assembly {
            mstore(0x00, index)
            mstore(0x20, agents.slot)
            agentStorageSlot := keccak256(0x00, 0x40)
        }
    }

    /**
     * @dev ONE_HUNDRED_PERCENT_IN_BASIS_POINTS is used as an amplifier to prevent a loss of precision.
     * @param agentsRemaining The number of agents remaining including wounded and healing agents.
     * @return multiplier The escape multiplier in basis points. This portion of the reward goes to the owner of the escaping agent.
     */
    function _escapeMultiplier(uint256 agentsRemaining) private view returns (uint256 multiplier) {
        multiplier =
            ((80 *
                ONE_HUNDRED_PERCENT_IN_BASIS_POINTS_SQUARED -
                50 *
                (((agentsRemaining * ONE_HUNDRED_PERCENT_IN_BASIS_POINTS) / totalSupply()) ** 2)) * 100) /
            ONE_HUNDRED_PERCENT_IN_BASIS_POINTS_SQUARED;
    }

    /**
     * @dev ONE_HUNDRED_PERCENT_IN_BASIS_POINTS is used as an amplifier to prevent a loss of precision.
     * @param agentsRemaining The number of agents remaining including wounded and healing agents.
     * @return split The split of the remaining escape reward between the the secondary prize pool and the main prize pool in basis points.
     */
    function _escapeRewardSplitForSecondaryPrizePool(uint256 agentsRemaining) private view returns (uint256 split) {
        split =
            ((9_980 * ONE_HUNDRED_PERCENT_IN_BASIS_POINTS) /
                99 -
                (((agentsRemaining * ONE_HUNDRED_PERCENT_IN_BASIS_POINTS) / totalSupply()) * uint256(8_000)) /
                99) /
            100;
        if (split > ONE_HUNDRED_PERCENT_IN_BASIS_POINTS) {
            split = ONE_HUNDRED_PERCENT_IN_BASIS_POINTS;
        }
    }

    /**
     * @dev Emit the Won event if there is only 1 active agent remaining in the game.
     * @param agentsRemaining The number of alive agents.
     * @param activeAgentsRemaining The number of active agents remaining.
     */
    function _emitWonEventIfOnlyOneAgentRemaining(uint256 agentsRemaining, uint256 activeAgentsRemaining) private {
        if (agentsRemaining == 1) {
            if (activeAgentsRemaining == 1) {
                emit Won(gameInfo.currentRoundId, _agentIndexToId(agents[1], 1));
            }
        }
    }

    /**
     * @notice Validate max supply is not breached after minting "quantity" amount of agents
     * @param quantity The quantity of agents to mint.
     */
    function _assertTotalSupplyNotBreached(uint256 quantity) private view {
        if (totalSupply() + quantity > MAX_SUPPLY) {
            revert ExceededTotalSupply();
        }
    }

    /**
     * @notice Validate the game has not begun.
     */
    function _assertGameNotYetBegun() private view {
        if (gameInfo.currentRoundId != 0) {
            revert GameAlreadyBegun();
        }
    }

    /**
     * @notice Validate exact ETH amount has been paid for the mint.
     * @param quantity The quantity of agents to mint.
     */
    function _assertExactNativeTokensSupplied(uint256 quantity) private view {
        if (quantity * PRICE != msg.value) {
            revert InexactNativeTokensSupplied();
        }
    }

    /**
     * @notice Validate the msg.sender is the owner of the agent ID.
     * @param agentId The agent ID to validate.
     */
    function _assertAgentOwnership(uint256 agentId) private view {
        if (ownerOf(agentId) != msg.sender) {
            revert NotAgentOwner();
        }
    }

    /**
     * @notice Validate the agent's status is the expected status.
     * @param agent The agent to validate.
     * @param agentId The agent's ID.
     * @param status The expected status.
     */
    function _assertAgentStatus(Agent storage agent, uint256 agentId, AgentStatus status) private view {
        if (agent.status != status) {
            revert InvalidAgentStatus(agentId, status);
        }
    }

    /**
     * @notice Validate the placement is between 1 and 50.
     * @param placement The placement to validate.
     */
    function _assertValidPlacement(uint256 placement) private pure {
        if (placement == 0 || placement > NUMBER_OF_SECONDARY_PRIZE_POOL_WINNERS) {
            revert InvalidPlacement();
        }
    }

    /**
     * @notice Validate the game is over by checking there is only 1 active agent and 0 wounded/healing agents.
     */
    function _assertGameOver() private view {
        if (gameInfo.activeAgents != 1 || gameInfo.woundedAgents != 0 || gameInfo.healingAgents != 0) {
            revert GameIsStillRunning();
        }
    }

    /**
     * @notice Validate the frontrun lock is off.
     */
    function _assertFrontrunLockIsOff() private view {
        if (frontrunLock == FRONTRUN_LOCK__LOCKED) {
            revert FrontrunLockIsOn();
        }
    }

    /**
     * @notice Validate the agent IDs array is not empty.
     */
    function _assertNotEmptyAgentIdsArrayProvided(uint256 agentIdsCount) private pure {
        if (agentIdsCount == 0) {
            revert NoAgentsProvided();
        }
    }

    /**
     * @notice Validate the game's active agents to be greater than 0 after escape.
     */
    function _assertGameIsNotOverAfterEscape(uint256 activeAgentsAfterEscape) private pure {
        if (activeAgentsAfterEscape < 1) {
            revert NoAgentsLeft();
        }
    }

    /**
     * @notice The starting token ID is 1.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice The base URI of the collection.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @param agentIdsPerRound The storage pointer to either a round's woundedAgentIdsPerRound or healingAgentIdsPerRound.
     * @return agentIds The agent IDs (now dynamically sized) in the round with the length removed.
     */
    function _buildAgentIdsPerRoundArray(
        uint16[MAXIMUM_HEALING_OR_WOUNDED_AGENTS_PER_ROUND_AND_LENGTH] storage agentIdsPerRound
    ) private view returns (uint256[] memory agentIds) {
        uint256 count = agentIdsPerRound[0];
        agentIds = new uint256[](count);
        for (uint256 i; i < count; ) {
            unchecked {
                agentIds[i] = agentIdsPerRound[i + 1];
                ++i;
            }
        }
    }
}
