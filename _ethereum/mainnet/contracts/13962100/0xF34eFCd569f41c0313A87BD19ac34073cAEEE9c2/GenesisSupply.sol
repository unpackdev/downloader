//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./State.sol";

contract GenesisSupply is Ownable, State {
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
     * Supply
     */
    uint256 public constant MAX_SUPPLY = 1077;
    uint256 public constant GODS_MAX_SUPPLY = 51;
    uint256 public constant DEMI_GODS_MAX_SUPPLY = 424;
    uint256 public constant DEMI_GODS_SUBTYPE_MAX_SUPPLY = 212;
    uint256 public constant ELEMENTALS_MAX_SUPPLY = 602;
    uint256 public constant ELEMENTALS_MAJOR_SUBTYPE_MAX_SUPPLY = 110;
    uint256 public constant ELEMENTALS_MINOR_SUBTYPE_MAX_SUPPLY = 54;
    uint256 public constant RESERVED_GODS_MAX_SUPPLY = 6;

    /**
     * Counters
     */
    uint256 private tokenCounter;
    uint256 private godsCounter;
    uint256 private creativeDemiGodsCounter;
    uint256 private destructiveDemiGodsCounter;
    uint256 private earthElementalsCounter;
    uint256 private waterElementalsCounter;
    uint256 private fireElementalsCounter;
    uint256 private airElementalsCounter;
    uint256 private electricityElementalsCounter;
    uint256 private metalElementalsCounter;
    uint256 private magmaElementalsCounter;
    uint256 private reservedGodsTransfered;

    /**
     * Minting properties
     */
    mapping(uint256 => TokenTraits) private tokenIdToTraits;

    /**
     * Utils
     */
    bool public isRevealed;
    address private genesisAddress;

    constructor() {
        isRevealed = false;
        // reserve 6 gods for owner
        for (uint256 i = 0; i < RESERVED_GODS_MAX_SUPPLY; i++) {
            godsCounter += 1;
            tokenCounter += 1;
        }
    }

    /**
     * Setters
     */
    function setIsRevealed(bool _isRevealed) external isGenesis {
        require(mintState == MintState.Maintenance, "Mint not maintenance");
        isRevealed = _isRevealed;
    }

    function setGenesis(address _genesisAddress) external onlyOwner closed {
        genesisAddress = _genesisAddress;
    }

    function setMintState(MintState _mintState) external isGenesis {
        require(_mintState > mintState, "State can't go back");
        mintState = _mintState;
    }

    /**
     * Getters
     */
    /**
     * Returns the current index to mint
     * @return index current index of the collection
     */
    function currentIndex() public view returns (uint256 index) {
        return tokenCounter;
    }

    /**
     * Returns the number of reserved gods left with the supply
     * @return index current index of reserved gods
     * @return supply max supply of reserved gods
     */
    function reservedGodsCurrentIndexAndSupply()
        public
        view
        isGenesis
        returns (uint256 index, uint256 supply)
    {
        return (reservedGodsTransfered, RESERVED_GODS_MAX_SUPPLY);
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
        isGenesis
        returns (uint256 startIndex, uint256 endIndex)
    {
        require(
            mintState == MintState.Closed || mintState == MintState.Active,
            "Mint not active or closed"
        );
        require(tokenCounter + count < MAX_SUPPLY + 1, "Not enough supply");
        uint256 firstTokenId = tokenCounter;
        for (uint256 i = 0; i < count; i++) {
            // On closed, we airdrop, we generate randomness with a moving nonce
            if (mintState == MintState.Closed) {
                tokenIdToTraits[firstTokenId + i] = generateRandomTraits(
                    generateRandomNumber(tokenCounter)
                );
            } else {
                // During WL we use a fix nonce
                tokenIdToTraits[firstTokenId + i] = generateRandomTraits(
                    generateRandomNumber(0)
                );
            }
            tokenCounter += 1;
        }
        return (firstTokenId, firstTokenId + count);
    }

    /**
     * Mint reserved gods
     * This function needs to be ran BEFORE the mint is opened to avoid
     * @param count number of gods to transfer
     */
    function mintReservedGods(uint256 count) public isGenesis closed {
        uint256 nextIndex = reservedGodsTransfered;
        // Here we don't need to increment counter and god supply counter because we already do in the constructor
        // to not initialize the counters at 0
        for (uint256 i = nextIndex; i < count + nextIndex; i++) {
            tokenIdToTraits[i] = TokenTraits(TokenType.GOD, TokenSubtype.NONE);
            reservedGodsTransfered += 1;
        }
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
        returns (uint256 randomNumber)
    {
        return
            uint256(
                keccak256(abi.encodePacked(msg.sender, block.timestamp, nonce))
            );
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
        uint256 godsLeft = GODS_MAX_SUPPLY - godsCounter;

        // DEMI-GODS
        uint256 creativeDemiGodsLeft = DEMI_GODS_SUBTYPE_MAX_SUPPLY -
            creativeDemiGodsCounter;
        uint256 destructiveDemiGodsLeft = DEMI_GODS_SUBTYPE_MAX_SUPPLY -
            destructiveDemiGodsCounter;
        uint256 demiGodsLeft = creativeDemiGodsLeft + destructiveDemiGodsLeft;

        // ELEMENTALS
        uint256 elementalsLeft = ELEMENTALS_MAX_SUPPLY -
            earthElementalsCounter -
            waterElementalsCounter -
            fireElementalsCounter -
            airElementalsCounter -
            electricityElementalsCounter -
            metalElementalsCounter -
            magmaElementalsCounter;

        uint256 totalCountLeft = godsLeft + demiGodsLeft + elementalsLeft;

        // We add 1 to modulos because we use the counts to define the type. If a count is at 0, we ignore it.
        // That's why we don't ever want the modulo to return 0.
        uint256 randomTypeIndex = (randomNumber % totalCountLeft) + 1;
        if (randomTypeIndex <= godsLeft) {
            godsCounter += 1;
            return TokenTraits(TokenType.GOD, TokenSubtype.NONE);
        } else if (randomTypeIndex <= godsLeft + demiGodsLeft) {
            uint256 randomSubtypeIndex = (randomNumber % demiGodsLeft) + 1;
            if (randomSubtypeIndex <= creativeDemiGodsLeft) {
                creativeDemiGodsCounter += 1;
                return TokenTraits(TokenType.DEMI_GOD, TokenSubtype.CREATIVE);
            } else {
                destructiveDemiGodsCounter += 1;
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
            earthElementalsCounter;
        uint256 waterElementalsLeft = ELEMENTALS_MAJOR_SUBTYPE_MAX_SUPPLY -
            waterElementalsCounter;
        uint256 fireElementalsLeft = ELEMENTALS_MAJOR_SUBTYPE_MAX_SUPPLY -
            fireElementalsCounter;
        uint256 airElementalsLeft = ELEMENTALS_MAJOR_SUBTYPE_MAX_SUPPLY -
            airElementalsCounter;
        uint256 electricityElementalsLeft = ELEMENTALS_MINOR_SUBTYPE_MAX_SUPPLY -
                electricityElementalsCounter;
        uint256 metalElementalsLeft = ELEMENTALS_MINOR_SUBTYPE_MAX_SUPPLY -
            metalElementalsCounter;
        uint256 magmaElementalsLeft = ELEMENTALS_MINOR_SUBTYPE_MAX_SUPPLY -
            magmaElementalsCounter;
        uint256 elementalsLeft = earthElementalsLeft +
            waterElementalsLeft +
            fireElementalsLeft +
            airElementalsLeft +
            electricityElementalsLeft +
            metalElementalsLeft +
            magmaElementalsLeft;

        uint256 randomSubtypeIndex = (randomNumber % elementalsLeft) + 1;
        if (randomSubtypeIndex <= earthElementalsLeft) {
            earthElementalsCounter += 1;
            return TokenTraits(TokenType.ELEMENTAL, TokenSubtype.EARTH);
        } else if (
            randomSubtypeIndex <= earthElementalsLeft + waterElementalsLeft
        ) {
            waterElementalsCounter += 1;
            return TokenTraits(TokenType.ELEMENTAL, TokenSubtype.WATER);
        } else if (
            randomSubtypeIndex <=
            earthElementalsLeft + waterElementalsLeft + fireElementalsLeft
        ) {
            fireElementalsCounter += 1;
            return TokenTraits(TokenType.ELEMENTAL, TokenSubtype.FIRE);
        } else if (
            randomSubtypeIndex <=
            earthElementalsLeft +
                waterElementalsLeft +
                fireElementalsLeft +
                airElementalsLeft
        ) {
            airElementalsCounter += 1;
            return TokenTraits(TokenType.ELEMENTAL, TokenSubtype.AIR);
        } else if (
            randomSubtypeIndex <=
            earthElementalsLeft +
                waterElementalsLeft +
                fireElementalsLeft +
                airElementalsLeft +
                electricityElementalsLeft
        ) {
            electricityElementalsCounter += 1;
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
            metalElementalsCounter += 1;
            return TokenTraits(TokenType.ELEMENTAL, TokenSubtype.METAL);
        } else {
            magmaElementalsCounter += 1;
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
     * Modifier that checks sender is Genesis
     */
    modifier isGenesis() {
        require(msg.sender == genesisAddress, "Not Genesis");
        _;
    }
}
