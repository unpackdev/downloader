// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Arrays.sol";

import "./VRFConsumerBase.sol";

import "./AllowList.sol";
import "./TokenTraits.sol";
import "./ITraits.sol";
import "./IVampireGame.sol";

/// @title The Vampire Game NFT contract
///
/// Note: The original Wolf Game's contract was used as insipiration, and a
/// few parts of the contract were taken directly, in particular the trait selection
/// and rarity using Walker's Alias method, and using a separate `Traits` contract
/// for getting the tokenURI.
///
/// Some info about how this contract works:
///
/// ### Allow-list
///
/// Using a merkle-tree based allow-list that caps the amount of nfts a wallet
/// can mint. This increases a bit the gas cost to mint on **presale**, but we
/// compensate this by paying half of the minting price when we reveal the NFTs.
///
/// ### On-chain vs Off-chain
///
/// What is on-chain here?
/// - The generated traits
/// - The revealed traits metadata
/// - The traits img data
///
/// What is off-chain?
/// - The random number we get for batch reveals. We use a neutral, trusted third party 
///   that is widely known in the community: Chainlink VRF.
/// - The non-revealed traits metadata (before your nft is revealed).
///
/// ### Minting and Revealing
///
/// 1. The user mints an NFT
/// 2. After a few mints, we request a random number to Chainlink VRF
/// 3. We use this random number to reveal the batch of NFTs that were minted
///    before we got the seed.
///
/// Why? We believe that as long as minting and revealing happens in the same 
/// transaction, people will be able to cheat.
///
/// ### Traits
///
/// The traits are all stored on-chain in another contract "Traits" similar to Wolf Game.
///
/// ### Game Controllers
///
/// For us to be able to expand on this game, future "game controller" contracts will be
/// able to freely call `mint` functions, and `transferFrom`, the logic to safeguard
/// those functions will be delegated to those contracts.
///
/// Unfortunatelly, to be able to expand, and to not fall into traps like Wolf Game did,
/// we had to leave a few things open that requires our users to _trust us_ for now. We
/// hope to make this trustless some day.
///
contract VampireGame is
    IVampireGame,
    IVampireGameControls,
    ERC721Enumerable,
    AllowList,
    Ownable,
    ReentrancyGuard,
    VRFConsumerBase
{
    /// @notice used to find seeds for token ids
    using Arrays for uint256[];

    /// ==== Immutable
    // Most of the immutable variables are initiated in the constructor
    // to make it easier to test

    /// @notice minting price in wei
    uint256 public immutable MINT_PRICE;
    /// @notice max amount of tokens that can be minted
    uint256 public immutable MAX_SUPPLY;
    /// @notice max mints per address
    uint256 public immutable MAX_PER_ADDRESS;
    /// @notice max mints per address in presale
    uint256 public immutable MAX_PER_ADDRESS_PRESALE;
    /// @notice price in $LINK to make VRF requests
    uint256 public LINK_VRF_PRICE;
    /// @notice number of tokens that can be bought with ether
    uint256 public PAID_TOKENS;
    /// @notice size of the batch that will be revealed by a single 
    uint256 public SEED_BATCH_SIZE;
    /// @notice random numbers generated from Chainlink VRF.
    uint256[] public seeds;
    /// @notice array of tokenIds in ascending order that matches the length of the `seeds` array.
    /// @dev using this to set which seeds are for which token, for example if let's say
    /// the array has the values [100, 1000], then tokens from 0~99 will use seed[0] and
    /// tokens from 100~999 will use seed[1].
    uint256[] public seedTokenBoundaries;
    /// @notice mapping from tokenId to tokenTraits
    mapping(uint256 => TokenTraits) public tokenTraits;
    /// @notice mapping from token hash to tokenId to prevent duplicated traits
    mapping(uint256 => uint256) public existingCombinations;
    /// @notice mapping from address to amount of tokens minted
    mapping(address => uint8) public amountMintedByAddress;
    /// @notice game controllers they can access special functions
    mapping(address => bool) public controllers;
    /// @notice chainlink key hash
    bytes32 public immutable KEY_HASH;
    /// @notice LINK token
    IERC20 public immutable LINK_TOKEN;
    /// @notice contract storing the traits data
    ITraits public traits;
    /// @notice address to withdraw the eth
    address private immutable splitter;
    /// @notice controls if mintWithEthPresale is paused
    bool public mintWithEthPresalePaused = true;
    /// @notice controls if mintWithEth is paused
    bool public mintWithEthPaused = true;
    /// @notice controls if mintFromController is paused
    bool public mintFromControllerPaused = true;
    /// @notice controls if token reveal is paused
    bool public revealPaused = true;
    /// @notice list of probabilities for each trait type  0 - 9 are associated with Sheep, 10 - 18 are associated with Wolves
    /// @dev won't mutate but can't make it immutable
    uint8[][18] public RARITIES;
    /// @notice list of aliases for Walker's Alias algorithm 0 - 9 are associated with Sheep, 10 - 18 are associated with Wolves
    /// @dev won't mutate but can't make it immutable
    uint8[][18] public ALIASES;

    /// === Constructor

    /// @dev constructor, most of the immutable props can be set here so it's easier to test
    /// @param _LINK_KEY_HASH Chainlink's VRF Key Hash
    /// @param _LINK_ADDRESS Chainlink's LINK contract address
    /// @param _LINK_VRF_COORDINATOR_ADDRESS Chainlink's coordinator contract address
    /// @param _LINK_VRF_PRICE Price in $LINK to request a random number from Chainlink VRF
    /// @param _MINT_PRICE price to mint one token in wei
    /// @param _MAX_SUPPLY maximum amount of available tokens to mint
    /// @param _MAX_PER_ADDRESS maximum amount of tokens one address can mint
    /// @param _MAX_PER_ADDRESS_PRESALE maximum amount of tokens one address can mint
    /// @param _SEED_BATCH_SIZE amount of tokens revealed by one seed
    /// @param _PAID_TOKENS maxiumum amount of tokens that can be bought with eth
    /// @param _splitter address to where the funds will go
    constructor(
        bytes32 _LINK_KEY_HASH,
        address _LINK_ADDRESS,
        address _LINK_VRF_COORDINATOR_ADDRESS,
        uint256 _LINK_VRF_PRICE,
        uint256 _MINT_PRICE,
        uint256 _MAX_SUPPLY,
        uint256 _MAX_PER_ADDRESS,
        uint256 _MAX_PER_ADDRESS_PRESALE,
        uint256 _SEED_BATCH_SIZE,
        uint256 _PAID_TOKENS,
        address _splitter
    )
        VRFConsumerBase(_LINK_VRF_COORDINATOR_ADDRESS, _LINK_ADDRESS)
        ERC721("The Vampire Game", "VGAME")
    {
        LINK_TOKEN = IERC20(_LINK_ADDRESS);
        KEY_HASH = _LINK_KEY_HASH;
        LINK_VRF_PRICE = _LINK_VRF_PRICE;
        MINT_PRICE = _MINT_PRICE;
        MAX_SUPPLY = _MAX_SUPPLY;
        MAX_PER_ADDRESS = _MAX_PER_ADDRESS;
        MAX_PER_ADDRESS_PRESALE = _MAX_PER_ADDRESS_PRESALE;
        SEED_BATCH_SIZE = _SEED_BATCH_SIZE;
        PAID_TOKENS = _PAID_TOKENS;
        splitter = _splitter;

        // Humans
        // Skin
        RARITIES[0] = [50, 15, 15, 250, 255];
        ALIASES[0] = [3, 4, 4, 0, 3];
        // Face
        RARITIES[1] = [
            133,
            189,
            57,
            255,
            243,
            133,
            114,
            135,
            168,
            38,
            222,
            57,
            95,
            57,
            152,
            114,
            57,
            133,
            189
        ];
        ALIASES[1] = [
            1,
            0,
            3,
            1,
            3,
            3,
            3,
            4,
            7,
            4,
            8,
            4,
            8,
            10,
            10,
            10,
            18,
            18,
            14
        ];
        // T-Shirt
        RARITIES[2] = [
            181,
            224,
            147,
            236,
            220,
            168,
            160,
            84,
            173,
            224,
            221,
            254,
            140,
            252,
            224,
            250,
            100,
            207,
            84,
            252,
            196,
            140,
            228,
            140,
            255,
            183,
            241,
            140
        ];
        ALIASES[2] = [
            1,
            0,
            3,
            1,
            3,
            3,
            4,
            11,
            11,
            4,
            9,
            10,
            13,
            11,
            13,
            14,
            15,
            15,
            20,
            17,
            19,
            24,
            20,
            24,
            22,
            26,
            24,
            26
        ];
        // Pants
        RARITIES[3] = [
            126,
            171,
            225,
            240,
            227,
            112,
            255,
            240,
            217,
            80,
            64,
            160,
            228,
            80,
            64,
            167
        ];
        ALIASES[3] = [2, 0, 1, 2, 3, 3, 4, 6, 7, 4, 6, 7, 8, 8, 15, 12];
        // Boots
        RARITIES[4] = [150, 30, 60, 255, 150, 60];
        ALIASES[4] = [0, 3, 3, 0, 3, 4];
        // Accessory
        RARITIES[5] = [
            210,
            135,
            80,
            245,
            235,
            110,
            80,
            100,
            190,
            100,
            255,
            160,
            215,
            80,
            100,
            185,
            250,
            240,
            240,
            100
        ];
        ALIASES[5] = [
            0,
            0,
            3,
            0,
            3,
            4,
            10,
            12,
            4,
            16,
            8,
            16,
            10,
            17,
            18,
            12,
            15,
            16,
            17,
            18
        ];
        // Hair
        RARITIES[6] = [250, 115, 100, 40, 175, 255, 180, 100, 175, 185];
        ALIASES[6] = [0, 0, 4, 6, 0, 4, 5, 9, 6, 8];
        // Cape
        RARITIES[7] = [255];
        ALIASES[7] = [0];
        // predatorIndex
        RARITIES[8] = [255];
        ALIASES[8] = [0];

        // Vampires
        // Skin
        RARITIES[9] = [
            234,
            239,
            234,
            234,
            255,
            234,
            244,
            249,
            130,
            234,
            234,
            247,
            234
        ];
        ALIASES[9] = [0, 0, 1, 2, 3, 4, 5, 6, 12, 7, 9, 10, 11];
        // Face
        RARITIES[10] = [
            45,
            255,
            165,
            60,
            195,
            195,
            45,
            120,
            75,
            75,
            105,
            120,
            255,
            180,
            150
        ];
        ALIASES[10] = [1, 0, 1, 4, 2, 4, 5, 12, 12, 13, 13, 14, 5, 12, 13];
        // Clothes
        RARITIES[11] = [
            147,
            180,
            246,
            201,
            210,
            252,
            219,
            189,
            195,
            156,
            177,
            171,
            165,
            225,
            135,
            135,
            186,
            135,
            150,
            243,
            135,
            255,
            231,
            141,
            183,
            150,
            135
        ];
        ALIASES[11] = [
            2,
            2,
            0,
            2,
            3,
            4,
            5,
            6,
            7,
            3,
            3,
            4,
            4,
            8,
            5,
            6,
            13,
            13,
            19,
            16,
            19,
            19,
            21,
            21,
            21,
            21,
            22
        ];
        // Pants
        RARITIES[12] = [255];
        ALIASES[12] = [0];
        // Boots
        RARITIES[13] = [255];
        ALIASES[13] = [0];
        // Accessory
        RARITIES[14] = [255];
        ALIASES[14] = [0];
        // Hair
        RARITIES[15] = [255];
        ALIASES[15] = [0];
        // Cape
        RARITIES[16] = [9, 9, 150, 90, 9, 210, 9, 9, 255];
        ALIASES[16] = [5, 5, 0, 2, 8, 3, 8, 8, 5];
        // predatorIndex
        RARITIES[17] = [255, 8, 160, 73];
        ALIASES[17] = [0, 0, 0, 2];
    }

    /// ==== Modifiers

    modifier onlyControllers() {
        require(controllers[_msgSender()], "ONLY_CONTROLLERS");
        _;
    }

    /// ==== Minting

    /// @notice mint an unrevealed token using eth
    /// @param amount amount to mint
    function mintWithETH(uint8 amount) external payable nonReentrant {
        require(!mintWithEthPaused, "MINT_WITH_ETH_PAUSED");
        uint8 addressMintedSoFar = amountMintedByAddress[_msgSender()];
        require(
            addressMintedSoFar + amount <= MAX_PER_ADDRESS,
            "MAX_TOKEN_PER_WALLET"
        );
        require(totalSupply() + amount <= PAID_TOKENS, "NOT_ENOUGH_TOKENS");
        require(amount > 0, "INVALID_AMOUNT");
        require(amount * MINT_PRICE == msg.value, "WRONG_VALUE");
        amountMintedByAddress[_msgSender()] = addressMintedSoFar + amount;
        _mintMany(_msgSender(), amount);
    }

    /// @notice mint an unrevealed token using eth
    /// @param amount amount to mint
    function mintWithETHPresale(uint8 amount, bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        require(!mintWithEthPresalePaused, "PRESALE_PAUSED");
        require(isAddressInAllowList(_msgSender(), proof), "NOT_IN_ALLOWLIST");
        uint8 addressMintedSoFar = amountMintedByAddress[_msgSender()];
        require(
            addressMintedSoFar + amount <= MAX_PER_ADDRESS_PRESALE,
            "MAX_TOKEN_PER_WALLET"
        );
        require(totalSupply() + amount <= PAID_TOKENS, "NOT_ENOUGH_TOKENS");
        require(amount > 0, "INVALID_AMOUNT");
        require(amount * MINT_PRICE == msg.value, "WRONG_VALUE");
        amountMintedByAddress[_msgSender()] = addressMintedSoFar + amount;
        _mintMany(_msgSender(), amount);
    }

    /// @dev mint any amount of tokens to an address
    /// common logic to many functions, the function calling
    /// this should do the guard checks
    function _mintMany(address to, uint8 amount) private {
        uint256 supply = totalSupply();
        for (uint8 i = 0; i < amount; i++) {
            uint256 tokenId = supply + i;
            _safeMint(to, tokenId);
            if ((tokenId + 1) % SEED_BATCH_SIZE == 0) {
                requestRandomness(KEY_HASH, LINK_VRF_PRICE);
            }
        }
    }

    /// ==== Revealing

    /// @notice reveal the metadata of multiple of tokenIds.
    /// @dev admin check if this won't fail
    function revealGenZeroTokens(uint256[] calldata tokenIds)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(canRevealToken(tokenId), "CANT_REVEAL");

            // Find seed index in the seedTokenBoundaries array
            uint256 seedIndex = seedTokenBoundaries.findUpperBound(tokenId);
            uint256 seed = uint256(keccak256(abi.encode(seeds[seedIndex], tokenId)));

            _revealToken(tokenId, seed);
        }
    }

    /// @dev returns true if a token can be revealed.
    /// Conditions for a token to be revealed:
    /// - Was not revealed yet
    /// - There is a seed that was added after the was already minted
    function canRevealToken(uint256 tokenId)
        private
        view
        returns (bool)
    {
        // Token already revealed
        if (tokenTraits[tokenId].exists) {
            return false;
        }

        // No seeds
        if (seedTokenBoundaries.length == 0) {
            return false;
        }

        // If the last element of the seedTokenBoundaries array is greater
        // than the tokenId it means that there is a seed available for that
        // token so the token can be revealed
        return seedTokenBoundaries[seedTokenBoundaries.length - 1] > tokenId;
    }

    /// @dev reveal one token given an id and a seed
    function _revealToken(uint256 tokenId, uint256 seed) private {
        (
            TokenTraits memory tt,
            uint256 ttHash
        ) = _generateNonDuplicatedTokenTraits(tokenId, seed);
        tokenTraits[tokenId] = tt;
        existingCombinations[ttHash] = tokenId;
    }

    /// @dev recursive function to generate a TokenTraits without colliding
    /// with other previously generated traits. It uses a seed from
    /// Chainlink VRF and if there is a collision, it keeps re-hashing the
    /// seed with the tokenId until it finds a unique set of traits.
    /// @param tokenId the id of the token to generate the traits for
    /// @param seed a value derived from a randomly generated value
    /// @return tt a TokenTraits struct
    function _generateNonDuplicatedTokenTraits(uint256 tokenId, uint256 seed)
        private
        returns (TokenTraits memory tt, uint256 ttHash)
    {
        // generate traits from seed
        tt = selectTraits(seed);

        // hash to check if the token is unique
        ttHash = structToHash(tt);
        if (existingCombinations[ttHash] == 0) {
            tokenTraits[tokenId] = tt;
            existingCombinations[ttHash] = tokenId;
            return (tt, ttHash);
        }

        // If it's here, then the generated traits collided with another
        // set of traits. Hopefully this won't happen.

        // generates a new seed combining the current seed and the tokenId
        uint256 newSeed = uint256(keccak256(abi.encode(seed, tokenId)));

        // recursive call D:
        return _generateNonDuplicatedTokenTraits(tokenId, newSeed);
    }

    /// @dev select traits based on the seed value.
    /// @param seed a uint256 to derive traits from
    /// @return tt the TokenTraits
    function selectTraits(uint256 seed)
        private
        view
        returns (TokenTraits memory tt)
    {
        tt.exists = true;
        tt.isVampire = (seed & 0xFFFF) % 10 == 0;
        uint8 shift = tt.isVampire ? 9 : 0;
        seed >>= 16;
        tt.skin = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
        seed >>= 16;
        tt.face = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        tt.clothes = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        tt.pants = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        seed >>= 16;
        tt.boots = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        seed >>= 16;
        tt.accessory = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        tt.hair = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
        seed >>= 16;
        tt.cape = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
        seed >>= 16;
        tt.predatorIndex = selectTrait(uint16(seed & 0xFFFF), 8 + shift);
    }

    /// @dev select a trait from the traitType
    /// @param seed a uint256 number to get the trait value from
    /// @param traitType the trait type
    function selectTrait(uint16 seed, uint8 traitType)
        private
        view
        returns (uint8)
    {
        uint8 trait = uint8(seed) % uint8(RARITIES[traitType].length);
        if (seed >> 8 < RARITIES[traitType][trait]) return trait;
        return ALIASES[traitType][trait];
    }

    /// @dev hash a TokenTraits struct
    /// @param tt the TokenTraits struct
    /// @return the uint256 hash
    function structToHash(TokenTraits memory tt)
        private
        pure
        returns (uint256)
    {
        return
            uint256(
                bytes32(
                    abi.encodePacked(
                        tt.isVampire,
                        tt.skin,
                        tt.face,
                        tt.clothes,
                        tt.pants,
                        tt.boots,
                        tt.accessory,
                        tt.hair,
                        tt.cape,
                        tt.predatorIndex
                    )
                )
            );
    }

    /// ==== State Control

    /// @notice set the new merkle tree root for allow-list
    function setMerkleTreeRoot(bytes32 newMerkleTreeRoot) external onlyOwner {
        _setMerkleTreeRoot(newMerkleTreeRoot);
    }

    /// @notice set the max amount of gen 0 tokens
    function setPaidTokens(uint256 _PAID_TOKENS) external onlyOwner {
        require(PAID_TOKENS != _PAID_TOKENS, "NO_CHANGES");
        PAID_TOKENS = _PAID_TOKENS;
    }

    /// @notice pause/unpause mintWithEthPresale function
    function setMintWithEthPresalePaused(bool paused) external onlyOwner {
        require(paused != mintWithEthPresalePaused, "NO_CHANGES");
        mintWithEthPresalePaused = paused;
    }

    /// @notice pause/unpause mintWithEth function
    function setMintWithEthPaused(bool paused) external onlyOwner {
        require(paused != mintWithEthPaused, "NO_CHANGES");
        mintWithEthPaused = paused;
    }

    /// @notice pause/unpause mintFromController function
    function setMintFromControllerPaused(bool paused) external onlyOwner {
        require(paused != mintFromControllerPaused, "NO_CHANGES");
        mintFromControllerPaused = paused;
    }

    /// @notice pause/unpause token reveal functions
    function setRevealPaused(bool paused) external onlyOwner {
        require(paused != revealPaused, "NO_CHANGES");
        revealPaused = paused;
    }

    /// @notice set the contract for the traits rendering
    /// @param _traits the contract address
    function setTraits(address _traits) external onlyOwner {
        traits = ITraits(_traits);
    }

    /// @notice add controller authority to an address
    /// @param _controller address to the game controller
    function addController(address _controller) external onlyOwner {
        controllers[_controller] = true;
    }

    /// @notice remove controller authority from an address
    /// @param _controller address to the game controller
    function removeController(address _controller) external onlyOwner {
        controllers[_controller] = false;
    }

    /// ==== Withdraw

    /// @notice withdraw the ether from the contract
    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = splitter.call{value: contractBalance}("");
        require(sent, "FAILED_TO_WITHDRAW");
    }

    /// @notice withdraw ERC20 tokens from the contract
    /// people always randomly transfer ERC20 tokens to the
    /// @param erc20TokenAddress the ERC20 token address
    /// @param recipient who will get the tokens
    /// @param amount how many tokens
    function withdrawERC20(
        address erc20TokenAddress,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        IERC20 erc20Contract = IERC20(erc20TokenAddress);
        bool sent = erc20Contract.transfer(recipient, amount);
        require(sent, "ERC20_WITHDRAW_FAILED");
    }

    /// @notice reserve some tokens for the team. Can only reserve gen 0 tokens
    /// we also need token 0 to so ssetup market places befor mint
    function reserve(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount < PAID_TOKENS);
        uint256 supply = totalSupply();
        for (uint8 i = 0; i < amount; i++) {
            uint256 tokenId = supply + i;
            _safeMint(to, tokenId);
        }
    }

    /// @notice delete all entries in the seeds and seedTokenBoundaries arrays
    /// just in case something weird happens
    function cleanSeeds() external onlyOwner {
        require(seeds.length > 0, "NO_SEEDS");
        for (uint256 i = 0; i < seeds.length; i++) {
            delete seeds[i];
            delete seedTokenBoundaries[i];
        }
    }

    /// @notice set the price for requesting a random number to Chainlink VRF
    /// Note that the base link token has 18 zeroes.
    function setVRFPrice(uint256 _LINK_VRF_PRICE) external onlyOwner {
        require(_LINK_VRF_PRICE != LINK_VRF_PRICE, "NO_CHANGES");
        LINK_VRF_PRICE = _LINK_VRF_PRICE;
    }

    /// @notice owner request reveal seed, just in case something goes wrong
    function requestRevealSeed() external onlyOwner {
        requestRandomness(KEY_HASH, LINK_VRF_PRICE);
    }

    /// ==== IVampireGameControls Overrides

    /// @notice see {IVampireGameControls.mintFromController(receiver, amount)}
    function mintFromController(address receiver, uint256 amount)
        external
        override
    {
        require(!mintFromControllerPaused, "MINT_FROM_CONTROLLER_PAUSED");
        require(controllers[_msgSender()], "NOT_AUTHORIZED");
        require(totalSupply() + amount <= MAX_SUPPLY, "NOT_ENOUGH_TOKENS");
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(receiver, tokenId);
        }
    }

    /// @notice for a game controller to reveal the metadata of multiple token ids
    function controllerRevealTokens(
        uint256[] calldata tokenIds,
        uint256[] calldata _seeds
    ) external override onlyControllers {
        require(!revealPaused, "REVEAL_PAUSED");
        require(
            tokenIds.length == seeds.length,
            "INPUTS_SHOULD_HAVE_SAME_LENGTH"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _revealToken(tokenIds[i], _seeds[i]);
        }
    }

    /// ==== IVampireGame Overrides

    /// @notice see {IVampireGame.getGenZeroSupply()}
    function getGenZeroSupply() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    /// @notice see {IVampireGame.getMaxSupply()}
    function getMaxSupply() external view override returns (uint256) {
        return MAX_SUPPLY;
    }

    /// @notice see {IVampireGame.getTokenTraits(tokenId)}
    function getTokenTraits(uint256 tokenId)
        external
        view
        override
        returns (TokenTraits memory)
    {
        return tokenTraits[tokenId];
    }

    /// @notice see {IVampireGame.isTokenRevealed(tokenId)}
    function isTokenRevealed(uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        return tokenTraits[tokenId].exists;
    }

    /// ==== ERC721 Overrides

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode approval of game controllers
        if (!controllers[_msgSender()])
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return traits.tokenURI(tokenId);
    }

    /// ==== Chainlink VRF Overrides

    /// @notice Fulfills randomness from Chainlink VRF
    /// @param requestId returned id of VRF request
    /// @param randomness random number from VRF
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 minted = totalSupply();

        // the amount of tokens minted has to be greater than the latest recorded
        // seed boundary, otherwise it means that there is already a seed for tokens
        // up to the current amount of tokens
        if (
            seedTokenBoundaries.length == 0 ||
            minted > seedTokenBoundaries[seedTokenBoundaries.length - 1]
        ) {
            seeds.push(randomness);
            seedTokenBoundaries.push(minted);
        }
        // Otherwise we discard the number. I'm hoping this doesn't happen though :D
        // More info: I'm hoping that this won't happen bevause we'll only ask for seeds
        // on spaced enough intervals, but not guaranteeing it in the contract
    }
}
