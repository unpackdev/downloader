// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

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
/// ### On-chain vs Off-chain
///
/// What is on-chain here?
/// - The generated traits
/// - The revealed traits metadata
/// - The traits img data
///
/// What is off-chain?
/// - The random number we get for batch reveals.
/// - The non-revealed image.
///
/// ### Minting and Revealing
///
/// 1. The user mints an NFT
/// 2. A seed is assigned for OG and Gen0 batches, this reveals the NFTs.
///
/// Why? We believe that as long as minting and revealing happens in the same
/// transaction, people will be able to cheat. So first you commit to minting, then
/// the seed is released.
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
contract VampireGame is
    IVampireGame,
    IVampireGameControls,
    ERC721,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    /// ==== Events

    event TokenRevealed(uint256 indexed tokenId, uint256 seed);
    event OGRevealed(uint256 seed);
    event Gen0Revealed(uint256 seed);

    /// ==== Immutable Properties

    /// @notice max amount of tokens that can be minted
    uint16 public immutable maxSupply;
    /// @notice max amount of og tokens
    uint16 public immutable ogSupply;
    /// @notice address to withdraw the eth
    address private immutable splitter;
    /// @notice minting price in wei
    uint256 public immutable mintPrice;

    /// ==== Mutable Properties

    /// @notice current amount of minted tokens
    uint16 public totalSupply;
    /// @notice max amount of gen 0 tokens (tokens that can be bought with eth)
    uint16 public genZeroSupply;
    /// @notice seed for the OGs who minted contract v1
    uint256 public ogSeed;
    /// @notice seed for all Gen 0 except for OGs
    uint256 public genZeroSeed;
    /// @notice contract storing the traits data
    ITraits public traits;
    /// @notice game controllers they can access special functions
    mapping(uint16 => uint256) public tokenSeeds;
    /// @notice game controllers they can access special functions
    mapping(address => bool) public controllers;

    /// === Constructor

    /// @dev constructor, most of the immutable props can be set here so it's easier to test
    /// @param _mintPrice price to mint one token in wei
    /// @param _maxSupply maximum amount of available tokens to mint
    /// @param _genZeroSupply maxiumum amount of tokens that can be bought with eth
    /// @param _splitter address to where the funds will go
    constructor(
        uint256 _mintPrice,
        uint16 _maxSupply,
        uint16 _genZeroSupply,
        uint16 _ogSupply,
        address _splitter
    ) ERC721("The Vampire Game", "VGAME") {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        genZeroSupply = _genZeroSupply;
        ogSupply = _ogSupply;
        splitter = _splitter;
        _pause();
    }

    /// ==== Modifiers

    modifier onlyControllers() {
        require(controllers[_msgSender()], "ONLY_CONTROLLERS");
        _;
    }

    /// ==== Airdrop

    function airdropToOwners(
        address v1Contract,
        uint16 from,
        uint16 to
    ) external onlyOwner {
        require(to >= from);
        IERC721 v1 = IERC721(v1Contract);
        for (uint16 i = from; i <= to; i++) {
            _mint(v1.ownerOf(i), i);
        }
        totalSupply += (to - from + 1);
    }

    /// ==== Minting

    /// @notice mint an unrevealed token using eth
    /// @param amount amount to mint
    function mintWithETH(uint16 amount)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(amount > 0, "INVALID_AMOUNT");
        require(amount * mintPrice == msg.value, "WRONG_VALUE");
        uint16 supply = totalSupply;
        require(supply + amount <= genZeroSupply, "NOT_ENOUGH_TOKENS");
        totalSupply = supply + amount;
        address to = _msgSender();
        for (uint16 i = 0; i < amount; i++) {
            _safeMint(to, supply + i);
        }
    }

    /// ==== Revealing

    /// @notice set the seed for the OG tokens. Once this is set, it cannot be changed!
    function revealOgTokens(uint256 seed) external onlyOwner {
        require(ogSeed == 0, "ALREADY_SET");
        ogSeed = seed;
        emit OGRevealed(seed);
    }

    /// @notice set the seed for the non-og Gen 0 tokens. Once this is set, it cannot be changed!
    function revealGenZeroTokens(uint256 seed) external onlyOwner {
        require(genZeroSeed == 0, "ALREADY_SET");
        genZeroSeed = seed;
        emit Gen0Revealed(seed);
    }

    /// ====================

    /// @notice Calculate the seed for a specific token
    /// - For OG tokens, the seed is derived from ogSeed
    /// - For Gen 0 tokens, the seed is derived from genZeroSeed
    /// - For other tokens, there is a seed for each for each
    function seedForToken(uint16 tokenId) public view returns (uint256) {
        uint16 supply = totalSupply;

        uint16 og = ogSupply;
        if (tokenId < og) {
            // amount of minted tokens needs to be greater than or equal to the og supply
            uint256 seed = ogSeed;
            if (supply >= og && seed != 0) {
                return
                    uint256(keccak256(abi.encodePacked(seed, "og", tokenId)));
            }

            return 0;
        }

        // read from storage only once
        uint16 pt = genZeroSupply;
        if (tokenId < pt) {
            // amount of minted tokens needs to be greater than or equal to the og supply
            uint256 seed = genZeroSeed;
            if (supply >= pt && seed != 0) {
                return
                    uint256(keccak256(abi.encodePacked(seed, "ze", tokenId)));
            }

            return 0;
        }

        if (supply > tokenId) {
            return tokenSeeds[tokenId];
        }

        return 0;
    }

    /// ==== Functions to calculate traits given a seed

    function _isVampire(uint256 seed) private pure returns (bool) {
        return (seed & 0xFFFF) % 10 == 0;
    }

    /// Human Traits

    function _tokenTraitHumanSkin(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 16) & 0xFFFF;
        uint256 trait = traitSeed % 5;
        if (traitSeed >> 8 < [50, 15, 15, 250, 255][trait]) return uint8(trait);
        return [3, 4, 4, 0, 3][trait];
    }

    function _tokenTraitHumanFace(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 32) & 0xFFFF;
        uint256 trait = traitSeed % 19;
        if (
            traitSeed >> 8 <
            [
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
            ][trait]
        ) return uint8(trait);
        return
            [1, 0, 3, 1, 3, 3, 3, 4, 7, 4, 8, 4, 8, 10, 10, 10, 18, 18, 14][
                trait
            ];
    }

    function _tokenTraitHumanTShirt(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 48) & 0xFFFF;
        uint256 trait = traitSeed % 28;
        if (
            traitSeed >> 8 <
            [
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
            ][trait]
        ) return uint8(trait);
        return
            [
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
            ][trait];
    }

    function _tokenTraitHumanPants(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 64) & 0xFFFF;
        uint256 trait = traitSeed % 16;
        if (
            traitSeed >> 8 <
            [
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
            ][trait]
        ) return uint8(trait);
        return [2, 0, 1, 2, 3, 3, 4, 6, 7, 4, 6, 7, 8, 8, 15, 12][trait];
    }

    function _tokenTraitHumanBoots(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 80) & 0xFFFF;
        uint256 trait = traitSeed % 6;
        if (traitSeed >> 8 < [150, 30, 60, 255, 150, 60][trait])
            return uint8(trait);
        return [0, 3, 3, 0, 3, 4][trait];
    }

    function _tokenTraitHumanAccessory(uint256 seed)
        private
        pure
        returns (uint8)
    {
        uint256 traitSeed = (seed >> 96) & 0xFFFF;
        uint256 trait = traitSeed % 20;
        if (
            traitSeed >> 8 <
            [
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
            ][trait]
        ) return uint8(trait);
        return
            [
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
            ][trait];
    }

    function _tokenTraitHumanHair(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 112) & 0xFFFF;
        uint256 trait = traitSeed % 10;
        if (
            traitSeed >> 8 <
            [250, 115, 100, 40, 175, 255, 180, 100, 175, 185][trait]
        ) return uint8(trait);
        return [0, 0, 4, 6, 0, 4, 5, 9, 6, 8][trait];
    }

    /// ==== Vampire Traits

    function _tokenTraitVampireSkin(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 16) & 0xFFFF;
        uint256 trait = traitSeed % 13;
        if (
            traitSeed >> 8 <
            [234, 239, 234, 234, 255, 234, 244, 249, 130, 234, 234, 247, 234][
                trait
            ]
        ) return uint8(trait);
        return [0, 0, 1, 2, 3, 4, 5, 6, 12, 7, 9, 10, 11][trait];
    }

    function _tokenTraitVampireFace(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 32) & 0xFFFF;
        uint256 trait = traitSeed % 15;
        if (
            traitSeed >> 8 <
            [
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
            ][trait]
        ) return uint8(trait);
        return [1, 0, 1, 4, 2, 4, 5, 12, 12, 13, 13, 14, 5, 12, 13][trait];
    }

    function _tokenTraitVampireClothes(uint256 seed)
        private
        pure
        returns (uint8)
    {
        uint256 traitSeed = (seed >> 48) & 0xFFFF;
        uint256 trait = traitSeed % 27;
        if (
            traitSeed >> 8 <
            [
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
            ][trait]
        ) return uint8(trait);
        return
            [
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
            ][trait];
    }

    function _tokenTraitVampireCape(uint256 seed) private pure returns (uint8) {
        uint256 traitSeed = (seed >> 128) & 0xFFFF;
        uint256 trait = traitSeed % 9;
        if (traitSeed >> 8 < [9, 9, 150, 90, 9, 210, 9, 9, 255][trait])
            return uint8(trait);
        return [5, 5, 0, 2, 8, 3, 8, 8, 5][trait];
    }

    function _tokenTraitVampirePredatorIndex(uint256 seed)
        private
        pure
        returns (uint8)
    {
        uint256 traitSeed = (seed >> 144) & 0xFFFF;
        uint256 trait = traitSeed % 4;
        if (traitSeed >> 8 < [255, 8, 160, 73][trait]) return uint8(trait);
        return [0, 0, 0, 2][trait];
    }

    /// ==== State Control

    /// @notice set the max amount of gen 0 tokens
    function setGenZeroSupply(uint16 _genZeroSupply) external onlyOwner {
        require(genZeroSupply != _genZeroSupply, "NO_CHANGES");
        genZeroSupply = _genZeroSupply;
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
    /// we also need token 0 to so setup market places before mint
    function reserve(address to, uint16 amount) external onlyOwner {
        uint16 supply = totalSupply;
        require(supply + amount < genZeroSupply);
        totalSupply = supply + amount;
        for (uint16 i = 0; i < amount; i++) {
            _safeMint(to, supply + i);
        }
    }

    /// ==== pause/unpause

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// ==== IVampireGameControls Overrides

    /// @notice see {IVampireGameControls.mintFromController}
    function mintFromController(address receiver, uint16 amount)
        external
        override
        whenNotPaused
        onlyControllers
    {
        uint16 supply = totalSupply;
        require(supply + amount <= maxSupply, "NOT_ENOUGH_TOKENS");
        totalSupply = supply + amount;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(receiver, supply + i);
        }
    }

    /// @notice for a game controller to reveal the metadata of multiple token ids
    function controllerRevealTokens(
        uint16[] calldata tokenIds,
        uint256[] calldata seeds
    ) external override whenNotPaused onlyControllers {
        require(
            tokenIds.length == seeds.length,
            "INPUTS_SHOULD_HAVE_SAME_LENGTH"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenSeeds[tokenIds[i]] == 0, "ALREADY_REVEALED");
            tokenSeeds[tokenIds[i]] = seeds[i];
            emit TokenRevealed(tokenIds[i], seeds[i]);
        }
    }

    /// ==== IVampireGame Overrides

    /// @notice see {IVampireGame.getTotalSupply}
    function getTotalSupply() external view override returns (uint16) {
        return totalSupply;
    }

    /// @notice see {IVampireGame.getOGSupply}
    function getOGSupply() external view override returns (uint16) {
        return ogSupply;
    }

    /// @notice see {IVampireGame.getGenZeroSupply}
    function getGenZeroSupply() external view override returns (uint16) {
        return genZeroSupply;
    }

    /// @notice see {IVampireGame.getMaxSupply}
    function getMaxSupply() external view override returns (uint16) {
        return maxSupply;
    }

    /// @notice see {IVampireGame.getTokenTraits}
    function getTokenTraits(uint16 tokenId)
        external
        view
        override
        returns (TokenTraits memory tt)
    {
        uint256 seed = seedForToken(tokenId);
        require(seed != 0, "NOT_REVEALED");
        tt.isVampire = _isVampire(seed);

        if (tt.isVampire) {
            tt.skin = _tokenTraitVampireSkin(seed);
            tt.face = _tokenTraitVampireFace(seed);
            tt.clothes = _tokenTraitVampireClothes(seed);
            tt.cape = _tokenTraitVampireCape(seed);
            tt.predatorIndex = _tokenTraitVampirePredatorIndex(seed);
        } else {
            tt.skin = _tokenTraitHumanSkin(seed);
            tt.face = _tokenTraitHumanFace(seed);
            tt.clothes = _tokenTraitHumanTShirt(seed);
            tt.pants = _tokenTraitHumanPants(seed);
            tt.boots = _tokenTraitHumanBoots(seed);
            tt.accessory = _tokenTraitHumanAccessory(seed);
            tt.hair = _tokenTraitHumanHair(seed);
        }
    }

    function isTokenVampire(uint16 tokenId)
        external
        view
        override
        returns (bool)
    {
        return _isVampire(seedForToken(tokenId));
    }

    function getPredatorIndex(uint16 tokenId)
        external
        view
        override
        returns (uint8)
    {
        uint256 seed = seedForToken(tokenId);
        require(seed != 0, "NOT_REVEALED");
        return _tokenTraitVampirePredatorIndex(seed);
    }

    /// @notice see {IVampireGame.isTokenRevealed(tokenId)}
    function isTokenRevealed(uint16 tokenId)
        public
        view
        override
        returns (bool)
    {
        return seedForToken(tokenId) != 0;
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
}
