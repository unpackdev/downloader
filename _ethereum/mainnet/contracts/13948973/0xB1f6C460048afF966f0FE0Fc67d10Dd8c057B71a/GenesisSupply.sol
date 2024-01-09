//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./AccessControl.sol";
import "./VRFConsumerBase.sol";

contract GenesisSupply is VRFConsumerBase, AccessControl {
    using Counters for Counters.Counter;

    enum TokenType {
        NONE,
        GOD,
        DEMI_GOD,
        ELEMENTAL
    }
    enum TokenSubtype {
        NONE,
        CREATIVE,
        DESTRUCTIVE,
        AIR,
        EARTH,
        ELECTRICITY,
        FIRE,
        MAGMA,
        METAL,
        WATER
    }

    struct TokenTraits {
        TokenType tokenType;
        TokenSubtype tokenSubtype;
    }

    /**
     * Chainlink VRF
     */
    bytes32 private keyHash;
    uint256 private fee;
    uint256 private seed;
    bytes32 private randomizationRequestId;

    /**
     * Supply
     */

    uint256 public constant MAX_SUPPLY = 1001;
    uint256 public constant GODS_MAX_SUPPLY = 51;
    uint256 public constant DEMI_GODS_MAX_SUPPLY = 400;
    uint256 public constant DEMI_GODS_SUBTYPE_MAX_SUPPLY = 200;
    uint256 public constant ELEMENTALS_MAX_SUPPLY = 550;
    uint256 public constant ELEMENTALS_MAJOR_SUBTYPE_MAX_SUPPLY = 100;
    uint256 public constant ELEMENTALS_MINOR_SUBTYPE_MAX_SUPPLY = 50;
    uint256 public constant RESERVED_GODS_MAX_SUPPLY = 6;

    /**
     * Counters
     */
    Counters.Counter private tokenCounter;
    Counters.Counter private godsCounter;
    Counters.Counter private creativeDemiGodsCounter;
    Counters.Counter private destructiveDemiGodsCounter;
    Counters.Counter private earthElementalsCounter;
    Counters.Counter private waterElementalsCounter;
    Counters.Counter private fireElementalsCounter;
    Counters.Counter private airElementalsCounter;
    Counters.Counter private electricityElementalsCounter;
    Counters.Counter private metalElementalsCounter;
    Counters.Counter private magmaElementalsCounter;
    Counters.Counter private reservedGodsTransfered;

    /**
     * Minting properties
     */
    mapping(uint256 => TokenTraits) private tokenIdToTraits;

    /**
     * Utils
     */
    bool public isRevealed;
    bytes32 public constant GENESIS_ROLE = keccak256("GENESIS_ROLE");

    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 _keyhash,
        uint256 _fee
    ) VRFConsumerBase(vrfCoordinator, linkToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        keyHash = _keyhash;
        fee = _fee;
        isRevealed = false;
        // reserve 6 gods for owner
        for (uint256 i = 0; i < RESERVED_GODS_MAX_SUPPLY; i++) {
            godsCounter.increment();
            tokenCounter.increment();
        }
    }

    /**
     * Setters
     */
    function setIsRevealed(bool _isRevealed) external onlyRole(GENESIS_ROLE) {
        isRevealed = _isRevealed;
    }

    /**
     * Getters
     */
    /**
     * Returns the current index to mint
     * @return index current index of the collection
     */
    function currentIndex() public view returns (uint256 index) {
        return tokenCounter.current();
    }

    /**
     * Returns the number of reserved gods left with the supply
     * @return index current index of reserved gods
     * @return supply max supply of reserved gods
     */
    function reservedGodsCurrentIndexAndSupply()
        public
        view
        onlyRole(GENESIS_ROLE)
        returns (uint256 index, uint256 supply)
    {
        return (reservedGodsTransfered.current(), RESERVED_GODS_MAX_SUPPLY);
    }

    /**
     * Minting functions
     */

    /**
     * Mint a token
     * @param count the number of item to mint
     * @return startIndex index of first mint
     * @return endIndex index of last mint
     */
    function mint(uint256 count)
        public
        onlyRole(GENESIS_ROLE)
        seedGenerated
        returns (uint256 startIndex, uint256 endIndex)
    {
        require(
            tokenCounter.current() + count < MAX_SUPPLY + 1,
            "Not enough supply"
        );
        uint256 firstTokenId = tokenCounter.current();
        for (uint256 i = 0; i < count; i++) {
            uint256 nextTokenId = firstTokenId + i;
            tokenIdToTraits[nextTokenId] = generateRandomTraits(
                generateRandomNumber(nextTokenId)
            );
            tokenCounter.increment();
        }
        return (firstTokenId, firstTokenId + count);
    }

    /**
     * Mint reserved gods
     * This function needs to be ran BEFORE the mint is opened to avoid
     * @param count number of gods to transfer
     */
    function mintReservedGods(uint256 count) public onlyRole(GENESIS_ROLE) {
        uint256 nextIndex = reservedGodsTransfered.current();
        // Here we don't need to increment counter and god supply counter because we already do in the constructor
        // to not initialize the counters at 0
        for (uint256 i = nextIndex; i < count + nextIndex; i++) {
            tokenIdToTraits[i] = TokenTraits(TokenType.GOD, TokenSubtype.NONE);
            reservedGodsTransfered.increment();
        }
    }

    /**
     * Will request a random number from Chainlink to be stored privately in the contract
     */
    function generateSeed() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(seed == 0, "Seed already generated");
        require(randomizationRequestId == 0, "Randomization already started");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        randomizationRequestId = requestRandomness(keyHash, fee);
    }

    /**
     * Callback when a random number gets generated
     * @param requestId id of the request sent to Chainlink
     * @param randomNumber random number returned by Chainlink
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        require(requestId == randomizationRequestId, "Invalid requestId");
        require(seed == 0, "Seed already generated");
        seed = randomNumber;
    }

    /**
     * Metadata functions
     */

    /**
     * @dev Generates a uint256 random number from seed, nonce and transaction block
     * @param nonce The nonce to be used for the randomization
     * @return randomNumber random number generated
     */
    function generateRandomNumber(uint256 nonce)
        private
        view
        seedGenerated
        returns (uint256 randomNumber)
    {
        return
            uint256(keccak256(abi.encodePacked(block.timestamp, nonce, seed)));
    }

    /**
     * Generate and returns the token traits (type & subtype) given a random number.
     * Function will adjust supply based on the type and subtypes generated
     * @param randomNumber random number provided
     * @return tokenTraits randomly picked token traits
     */
    function generateRandomTraits(uint256 randomNumber)
        private
        returns (TokenTraits memory tokenTraits)
    {
        // GODS
        uint256 godsLeft = GODS_MAX_SUPPLY - godsCounter.current();

        // DEMI-GODS
        uint256 creativeDemiGodsLeft = DEMI_GODS_SUBTYPE_MAX_SUPPLY -
            creativeDemiGodsCounter.current();
        uint256 destructiveDemiGodsLeft = DEMI_GODS_SUBTYPE_MAX_SUPPLY -
            destructiveDemiGodsCounter.current();
        uint256 demiGodsLeft = creativeDemiGodsLeft + destructiveDemiGodsLeft;

        // ELEMENTALS
        uint256 elementalsLeft = ELEMENTALS_MAX_SUPPLY -
            earthElementalsCounter.current() -
            waterElementalsCounter.current() -
            fireElementalsCounter.current() -
            airElementalsCounter.current() -
            electricityElementalsCounter.current() -
            metalElementalsCounter.current() -
            magmaElementalsCounter.current();

        uint256 totalCountLeft = godsLeft + demiGodsLeft + elementalsLeft;

        // We add 1 to modulos because we use the counts to define the type. If a count is at 0, we ignore it.
        // That's why we don't ever want the modulo to return 0.
        uint256 randomTypeIndex = (randomNumber % totalCountLeft) + 1;
        if (randomTypeIndex <= godsLeft) {
            godsCounter.increment();
            return TokenTraits(TokenType.GOD, TokenSubtype.NONE);
        } else if (randomTypeIndex <= godsLeft + demiGodsLeft) {
            uint256 randomSubtypeIndex = (randomNumber % demiGodsLeft) + 1;
            if (randomSubtypeIndex <= creativeDemiGodsLeft) {
                creativeDemiGodsCounter.increment();
                return TokenTraits(TokenType.DEMI_GOD, TokenSubtype.CREATIVE);
            } else {
                destructiveDemiGodsCounter.increment();
                return
                    TokenTraits(TokenType.DEMI_GOD, TokenSubtype.DESTRUCTIVE);
            }
        } else {
            return generateElementalSubtype(randomNumber);
        }
    }

    function generateElementalSubtype(uint256 randomNumber)
        private
        returns (TokenTraits memory traits)
    {
        // ELEMENTALS
        uint256 earthElementalsLeft = ELEMENTALS_MAJOR_SUBTYPE_MAX_SUPPLY -
            earthElementalsCounter.current();
        uint256 waterElementalsLeft = ELEMENTALS_MAJOR_SUBTYPE_MAX_SUPPLY -
            waterElementalsCounter.current();
        uint256 fireElementalsLeft = ELEMENTALS_MAJOR_SUBTYPE_MAX_SUPPLY -
            fireElementalsCounter.current();
        uint256 airElementalsLeft = ELEMENTALS_MAJOR_SUBTYPE_MAX_SUPPLY -
            airElementalsCounter.current();
        uint256 electricityElementalsLeft = ELEMENTALS_MINOR_SUBTYPE_MAX_SUPPLY -
                electricityElementalsCounter.current();
        uint256 metalElementalsLeft = ELEMENTALS_MINOR_SUBTYPE_MAX_SUPPLY -
            metalElementalsCounter.current();
        uint256 magmaElementalsLeft = ELEMENTALS_MINOR_SUBTYPE_MAX_SUPPLY -
            magmaElementalsCounter.current();
        uint256 elementalsLeft = earthElementalsLeft +
            waterElementalsLeft +
            fireElementalsLeft +
            airElementalsLeft +
            electricityElementalsLeft +
            metalElementalsLeft +
            magmaElementalsLeft;

        uint256 randomSubtypeIndex = (randomNumber % elementalsLeft) + 1;
        if (randomSubtypeIndex <= earthElementalsLeft) {
            earthElementalsCounter.increment();
            return TokenTraits(TokenType.ELEMENTAL, TokenSubtype.EARTH);
        } else if (
            randomSubtypeIndex <= earthElementalsLeft + waterElementalsLeft
        ) {
            waterElementalsCounter.increment();
            return TokenTraits(TokenType.ELEMENTAL, TokenSubtype.WATER);
        } else if (
            randomSubtypeIndex <=
            earthElementalsLeft + waterElementalsLeft + fireElementalsLeft
        ) {
            fireElementalsCounter.increment();
            return TokenTraits(TokenType.ELEMENTAL, TokenSubtype.FIRE);
        } else if (
            randomSubtypeIndex <=
            earthElementalsLeft +
                waterElementalsLeft +
                fireElementalsLeft +
                airElementalsLeft
        ) {
            airElementalsCounter.increment();
            return TokenTraits(TokenType.ELEMENTAL, TokenSubtype.AIR);
        } else if (
            randomSubtypeIndex <=
            earthElementalsLeft +
                waterElementalsLeft +
                fireElementalsLeft +
                airElementalsLeft +
                electricityElementalsLeft
        ) {
            electricityElementalsCounter.increment();
            return TokenTraits(TokenType.ELEMENTAL, TokenSubtype.ELECTRICITY);
        } else if (
            randomSubtypeIndex <=
            earthElementalsLeft +
                waterElementalsLeft +
                fireElementalsLeft +
                airElementalsLeft +
                electricityElementalsLeft +
                metalElementalsLeft
        ) {
            metalElementalsCounter.increment();
            return TokenTraits(TokenType.ELEMENTAL, TokenSubtype.METAL);
        } else {
            magmaElementalsCounter.increment();
            return TokenTraits(TokenType.ELEMENTAL, TokenSubtype.MAGMA);
        }
    }

    /**
     * Returns the metadata of a token
     * @param tokenId id of the token
     * @return traits metadata of the token
     */
    function getMetadataForTokenId(uint256 tokenId)
        public
        view
        validTokenId(tokenId)
        returns (TokenTraits memory traits)
    {
        require(isRevealed, "Not revealed yet");
        return tokenIdToTraits[tokenId];
    }

    /**
     *  Modifiers
     */

    /**
     * Modifier that checks for a valid tokenId
     * @param tokenId token id
     */
    modifier validTokenId(uint256 tokenId) {
        require(tokenId < MAX_SUPPLY, "Invalid tokenId");
        require(tokenId >= 0, "Invalid tokenId");
        _;
    }

    /**
     * Modifier that checks if seed is generated
     */
    modifier seedGenerated() {
        require(seed > 0, "Seed not generated");
        _;
    }
}
