// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PausableUpgradeable.sol";
import "./Proxied.sol";

import "./IERC20.sol";

import "./VRFLibrary.sol";

import "./IEgg.sol";
import "./ITraits.sol";
import "./IChickenNoodle.sol";
import "./IFarm.sol";
import "./IRandomnessConsumer.sol";

contract ChickenNoodleSoup is
    IRandomnessConsumer,
    Proxied,
    PausableUpgradeable
{
    using VRFLibrary for VRFLibrary.VRFData;

    // number of tokens have been processed so far
    uint16 public processed;

    // mint price
    uint256 public constant MINT_PRICE = .069420 ether;

    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    // list of probabilities for each trait type
    // 0 - 5 are common, 6 is place holder for Chicken Tier, 7 is Noodles tier
    uint8[][10] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 5 are common, 6 is place holder for Chicken Tier, 7 is Noodles tier
    uint8[][10] public aliases;

    // reference to the Farm for choosing random Noodle thieves
    IFarm public farm;
    // reference to $EGG for burning on mint
    IEgg public egg;
    // reference to ChickenNoodle for minting
    IChickenNoodle public chickenNoodle;

    VRFLibrary.VRFData private vrf;

    mapping(uint256 => bytes32) internal mintBlockhash;

    uint256 randomnessInterval;
    uint256 randomnessMintsNeeded;
    uint256 randomnessMintsMinimum;

    // /**
    //  * initializes contract and rarity tables
    //  */
    // constructor(address _egg, address _chickenNoodle) {
    //     initialize(_egg, _chickenNoodle);
    // }

    /**
     * initializes contract and rarity tables
     */
    function initialize(address _egg, address _chickenNoodle) public proxied {
        __Pausable_init();

        egg = IEgg(_egg);
        chickenNoodle = IChickenNoodle(_chickenNoodle);

        randomnessInterval = 1 hours;
        randomnessMintsNeeded = 500;
        randomnessMintsMinimum = 0;

        // I know this looks weird but it saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm

        // Common
        // backgrounds
        rarities[0] = [
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            183,
            236,
            252,
            224,
            254,
            255
        ]; //[15, 50, 200, 250, 255];
        aliases[0] = [
            1,
            2,
            5,
            0,
            1,
            7,
            1,
            10,
            5,
            10,
            11,
            12,
            13,
            14,
            16,
            11,
            17,
            23,
            13,
            14,
            17,
            23,
            23,
            24,
            27,
            27,
            28,
            28,
            28
        ];
        // mouthAccessories
        rarities[1] = [
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            170,
            183,
            236,
            252,
            224,
            250,
            254,
            255
        ];
        aliases[1] = [
            1,
            2,
            5,
            0,
            1,
            7,
            1,
            10,
            5,
            10,
            11,
            12,
            13,
            14,
            16,
            11,
            17,
            23,
            13,
            14,
            17,
            20,
            23,
            23,
            24,
            27,
            27,
            28,
            28,
            29,
            29
        ];

        // pupils
        rarities[2] = [
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            90,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            180,
            200,
            183,
            236,
            252,
            224,
            254,
            255
        ];
        aliases[2] = [
            1,
            2,
            5,
            0,
            1,
            7,
            1,
            10,
            5,
            10,
            11,
            12,
            13,
            14,
            16,
            11,
            17,
            23,
            13,
            14,
            17,
            23,
            23,
            24,
            27,
            27,
            28,
            28,
            29,
            29,
            30,
            31
        ];

        // hats
        rarities[3] = [
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            170,
            183,
            236,
            252,
            224,
            250,
            254,
            255,
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            154
        ];
        aliases[3] = [
            1,
            2,
            5,
            0,
            1,
            7,
            1,
            10,
            5,
            10,
            11,
            12,
            13,
            14,
            16,
            11,
            17,
            23,
            13,
            14,
            17,
            20,
            23,
            23,
            24,
            27,
            27,
            28,
            28,
            29,
            29,
            31,
            32,
            35,
            30,
            31,
            37,
            31,
            40,
            35,
            40,
            41,
            42,
            43,
            44,
            46,
            41,
            47
        ];

        // bodyAccessories
        rarities[4] = [
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            170,
            183,
            236,
            252,
            224,
            250,
            254,
            255,
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            170,
            183,
            236,
            252,
            224,
            250,
            254,
            255,
            60,
            120,
            185,
            210,
            194,
            103,
            209,
            100,
            169,
            178
        ];
        aliases[4] = [
            1,
            2,
            5,
            0,
            1,
            7,
            1,
            10,
            5,
            10,
            11,
            12,
            13,
            14,
            16,
            11,
            17,
            23,
            13,
            14,
            17,
            20,
            23,
            23,
            24,
            27,
            27,
            28,
            28,
            29,
            29,
            31,
            32,
            35,
            30,
            31,
            37,
            31,
            40,
            35,
            40,
            41,
            42,
            43,
            44,
            46,
            41,
            47,
            53,
            43,
            44,
            47,
            50,
            53,
            53,
            54,
            57,
            57,
            58,
            58,
            59,
            59,
            60,
            69,
            64,
            61,
            70,
            67,
            66,
            68,
            65,
            71
        ];

        // tier
        rarities[5] = [8, 160, 73, 255];
        aliases[5] = [2, 3, 3, 3];

        // snakeBodies Tier 0:5-1:4
        rarities[6] = [185, 215, 240, 190];
        aliases[6] = [1, 2, 2, 0];

        // snakeBodies Tier 0:4-1:3
        rarities[7] = [135, 215, 240, 185];
        aliases[7] = [1, 2, 1, 0];

        // snakeBodies Tier 0:3-1:2
        rarities[8] = [190, 215, 240, 100, 110, 135, 160, 185];
        aliases[8] = [1, 2, 4, 0, 5, 6, 7, 7];

        // snakeBodies Tier 0:2-1:1
        rarities[9] = [190, 215, 240, 100, 110, 135, 160, 185];
        aliases[9] = [1, 2, 4, 0, 5, 6, 7, 7];
    }

    /** EXTERNAL */
    function processingStats()
        public
        view
        returns (
            bool requestPending,
            uint256 maxIdAvailableToProcess,
            uint256 readyForProcessing,
            uint256 waitingToBeProcessed,
            uint256 timeTellNextRandomnessRequest
        )
    {
        return
            vrf.processingStats(
                chickenNoodle.totalSupply(),
                processed,
                randomnessInterval
            );
    }

    /**
     * mint a token - 90% Chicken, 10% Noodles
     * The first 20% cost ETHER to claim, the remaining cost $EGG
     */
    function mint(uint256 amount) external payable whenNotPaused {
        uint16 supply = uint16(chickenNoodle.totalSupply());
        uint256 maxTokens = chickenNoodle.MAX_TOKENS();
        uint256 paidTokens = chickenNoodle.PAID_TOKENS();

        require(tx.origin == _msgSender(), 'Only EOA');
        require(supply + amount <= maxTokens, 'All tokens minted');
        require(amount > 0 && amount <= 10, 'Invalid mint amount');
        if (supply < paidTokens) {
            require(
                supply + amount <= paidTokens,
                'All tokens on-sale already sold'
            );
            require(amount * MINT_PRICE == msg.value, 'Invalid payment amount');
        } else {
            require(msg.value == 0, 'Egg needed not ETHER');
        }

        uint256 totalEggCost = 0;
        for (uint256 i = 0; i < amount; i++) {
            totalEggCost += mintCost(supply + 1 + i);
        }

        if (totalEggCost > 0) {
            egg.burn(_msgSender(), totalEggCost);
            egg.mint(address(this), totalEggCost / 100);
        }

        for (uint256 i = 0; i < amount; i++) {
            _processNext();

            supply++;
            mintBlockhash[supply] = blockhash(block.number - 1);
            chickenNoodle.mint(_msgSender(), supply);
        }

        checkRandomness(false);
    }

    /**
     * the first 20% are paid in ETH
     * the next 20% are 20000 $EGG
     * the next 40% are 40000 $EGG
     * the final 20% are 80000 $EGG
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= chickenNoodle.PAID_TOKENS()) return 0;
        if (tokenId <= (chickenNoodle.MAX_TOKENS() * 2) / 5) return 20000 ether;
        if (tokenId <= (chickenNoodle.MAX_TOKENS() * 4) / 5) return 40000 ether;
        return 80000 ether;
    }

    function checkRandomness(bool force) public {
        force = force && _msgSender() == _proxyAdmin();

        if (force) {
            vrf.newRequest();
        } else {
            vrf.checkRandomness(
                chickenNoodle.totalSupply(),
                processed,
                randomnessInterval,
                randomnessMintsNeeded,
                randomnessMintsMinimum
            );
        }
    }

    function process(uint256 amount) external override {
        for (uint256 i = 0; i < amount; i++) {
            if (!_processNext()) break;
        }
    }

    function setRandomnessResult(bytes32 requestId, uint256 randomness)
        external
        override
    {
        vrf.setRequestResults(
            requestId,
            randomness,
            chickenNoodle.totalSupply()
        );
    }

    function processNext() external override returns (bool) {
        return _processNext();
    }

    /** INTERNAL */

    function _processNext() internal returns (bool) {
        uint16 tokenId = processed + 1;

        (bool available, uint256 randomness) = vrf.randomnessForId(tokenId);

        if (available) {
            uint256 seed = random(tokenId, mintBlockhash[tokenId], randomness);
            IChickenNoodle.ChickenNoodleTraits memory t = generate(
                tokenId,
                seed
            );

            address recipient = selectRecipient(tokenId, seed);

            delete mintBlockhash[tokenId];
            processed++;

            chickenNoodle.finalize(tokenId, t, recipient);
            return true;
        }

        return false;
    }

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param tokenId the id of the token to generate traits for
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t - a struct of traits for the given token ID
     */
    function generate(uint16 tokenId, uint256 seed)
        internal
        returns (IChickenNoodle.ChickenNoodleTraits memory t)
    {
        t = selectTraits(tokenId, seed);

        if (existingCombinations[structToHash(t)] == 0) {
            existingCombinations[structToHash(t)] = tokenId;
            return t;
        }

        return generate(tokenId, random(tokenId, mintBlockhash[tokenId], seed));
    }

    /** ADMIN */

    /**
     * called after deployment so that the contract can get random values
     * @param _randomnessProvider the address of the new RandomnessProvider
     */
    function setRandomnessProvider(address _randomnessProvider)
        external
        override
        onlyProxyAdmin
    {
        vrf.setRandomnessProvider(_randomnessProvider);
    }

    /**
     * called to upoate fee to get randomness
     * @param _fee the fee required for getting randomness
     */
    function updateRandomnessFee(uint256 _fee)
        external
        override
        onlyProxyAdmin
    {
        vrf.updateFee(_fee);
    }

    /**
     * allows owner to rescue LINK tokens
     */
    function rescueLINK(uint256 amount) external override onlyProxyAdmin {
        vrf.rescueLINK(_proxyAdmin(), amount);
    }

    /**
     * called after deployment so that the contract can get random noodle thieves
     * @param _farm the address of the HenHouse
     */
    function setFarm(address _farm) external onlyProxyAdmin {
        farm = IFarm(_farm);
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyProxyAdmin {
        payable(_proxyAdmin()).transfer(address(this).balance);
    }

    /**
     * allows owner to rescue tokens
     */
    function rescue(IERC20 token, uint256 amount) external onlyProxyAdmin {
        token.transfer(_proxyAdmin(), amount);
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyProxyAdmin {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
     * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
     * probability & alias tables are generated off-chain beforehand
     * @param seed portion of the 256 bit seed to remove trait correlation
     * @param traitType the trait type to select a trait for
     * @return the ID of the randomly selected trait
     */
    function selectTrait(uint16 seed, uint8 traitType)
        internal
        view
        returns (uint8)
    {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);

        if (seed >> 8 < rarities[traitType][trait]) {
            return trait;
        }

        return aliases[traitType][trait];
    }

    /**
     * the first 20% (ETH purchases) go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked noodle
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the Noodle thief's owner)
     */
    function selectRecipient(uint256 tokenId, uint256 seed)
        internal
        view
        returns (address)
    {
        if (
            tokenId <= chickenNoodle.PAID_TOKENS() || ((seed >> 245) % 10) != 0
        ) {
            // top 10 bits haven't been used
            return chickenNoodle.ownerOf(tokenId);
        }
        address thief = farm.randomNoodleOwner(seed >> 144); // 144 bits reserved for trait selection

        if (thief == address(0x0)) {
            return chickenNoodle.ownerOf(tokenId);
        }

        return thief;
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */
    function selectTraits(uint256 tokenId, uint256 seed)
        internal
        view
        returns (IChickenNoodle.ChickenNoodleTraits memory t)
    {
        t.minted = true;

        t.isChicken = (seed & 0xFFFF) % 10 != 0;

        seed >>= 16;
        t.backgrounds = selectTrait(uint16(seed & 0xFFFF), 0);

        seed >>= 16;
        t.mouthAccessories = selectTrait(uint16(seed & 0xFFFF), 1);

        seed >>= 16;
        t.pupils = selectTrait(uint16(seed & 0xFFFF), 2);

        seed >>= 16;
        t.hats = selectTrait(uint16(seed & 0xFFFF), 3);

        seed >>= 16;
        t.bodyAccessories = t.isChicken
            ? 0
            : selectTrait(uint16(seed & 0xFFFF), 4);

        seed >>= 16;
        uint8 tier = selectTrait(uint16(seed & 0xFFFF), 5);

        uint8 snakeBodiesPlacement = 0;

        if (tier == 1) {
            snakeBodiesPlacement = 4;
        } else if (tier == 2) {
            snakeBodiesPlacement = 8;
        } else if (tier == 3) {
            snakeBodiesPlacement = 16;
        }

        seed >>= 16;
        t.snakeBodies =
            snakeBodiesPlacement +
            selectTrait(uint16(seed & 0xFFFF), 6 + t.tier);

        t.tier = t.isChicken
            ? 0
            : (tokenId <= chickenNoodle.PAID_TOKENS() ? 5 : 4) - tier;
    }

    /**
     * converts a struct to a 256 bit hash to check for uniqueness
     * @param s the struct to pack into a hash
     * @return the 256 bit hash of the struct
     */
    function structToHash(IChickenNoodle.ChickenNoodleTraits memory s)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(
                bytes32(
                    abi.encodePacked(
                        s.minted,
                        s.isChicken,
                        s.backgrounds,
                        s.snakeBodies,
                        s.mouthAccessories,
                        s.pupils,
                        s.bodyAccessories,
                        s.hats,
                        s.tier
                    )
                )
            );
    }

    /**
     * generates a pseudorandom number
     * @param tokenId a value ensure different outcomes for different sources in the same block
     * @param mintHash minthash stored at time of initial mint
     * @param seed vrf random value
     * @return a pseudorandom value
     */
    function random(
        uint16 tokenId,
        bytes32 mintHash,
        uint256 seed
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tokenId, mintHash, seed)));
    }
}
