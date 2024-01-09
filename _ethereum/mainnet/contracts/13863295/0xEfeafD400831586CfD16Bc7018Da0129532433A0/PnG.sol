// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./ERC721.sol";

import "./IPnG.sol";
import "./ITraits.sol";

import "./IFleet.sol";


import "./Accessable.sol";



contract TraitSelector {
    // list of probabilities for each trait type
    // 0 - 7 are associated with Galleons, 8 - 15 are associated with Pirates
    uint8[][16] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 7 are associated with Galleons, 8-15 are associated with Pirates
    uint8[][16] public aliases;

    constructor() {
        // A.J. Walker's Alias Algorithm
        // Galleons

        // base
        rarities[0] = [ 245, 173, 255 ];
        aliases[0] =  [ 1, 2, 2 ];
        // deck
        rarities[1] = [ 252, 212, 255 ];
        aliases[1] =  [ 1, 2, 2 ];
        // sails
        rarities[2] =  [60,   2,  1,  86, 219,  17, 80, 73,86, 139, 54, 120,  86,  18, 66, 80,60, 119, 66,  86,  73, 192, 99,  3,33, 255];
        aliases[2] = [ 1, 13, 23,  1,  1, 23,  1,  1, 2,  2, 24, 23,  5, 24,  5,  5, 10, 10, 10, 10, 11,  1, 11, 24, 25, 25];
        // crowsNest
        rarities[3] = [ 9,  23, 119, 19,  74, 179, 10,  19,82,   6, 143,  8,   7,  40, 75,  71,52, 150,  10, 21, 150,  38, 17, 122,21, 255];
        aliases[3] = [ 2,  4,  4,  4,  8,  8, 10, 14,15, 17, 15, 17, 17, 19, 19, 19,20, 20, 20, 23, 21, 24, 25, 24,25, 25];
        // decor
        rarities[4] = [ 19, 59,  9, 21, 116,  46,  8, 30, 11, 45, 39,  49, 255, 21,163, 10, 26,  6, 202,  11];
        aliases[4] = [4,  4,  4,  5,  5,  7,  7, 11,  7, 10, 12, 12, 12, 10, 7, 10, 10, 11, 10, 11];
        // flags
        rarities[5] = [ 8,  64,  34, 104, 210, 189,  49, 159,  45, 146,  29,  31,  33,  61, 40,  69, 111,  29,  14, 221, 116, 150, 255, 232, 142];
        aliases[5] = [ 9,  9, 12, 12,  0,  0, 13,  0, 0, 12,  1,  1, 15, 16,  2, 17, 17, 22,  3,  1,  2,  6, 22,  0, 6];
        // bowsprit
        rarities[6] = [11,  23, 20,  49, 29,  9, 219, 159, 243,  85, 78,  11, 71, 42,  34,  14, 204,  61, 18, 151,  3,  2,  26,  27, 189, 255];
        aliases[6] = [3,  3,  3,  4,  6,  8,  7,  8,  9, 18,  9,  9, 25, 12, 12, 16,  9, 18, 25, 25, 18, 19, 23, 24,  9, 25];

        // empty
        rarities[7] = [255];
        aliases[7] = [0];

        // Pirates
        // skin
        rarities[8] = [ 255, 255, 255, 255, 255 ];
        aliases[8] =  [ 0, 1, 2, 3, 4 ];
        // clothes
        rarities[9] = [255, 153,  76, 128,128,  76, 255, 179, 76, 128];
        aliases[9] = [0, 2, 5, 2, 5,6, 6, 2, 4, 4];
        // hair
        rarities[10] = [216, 71, 67, 216, 54,152, 35, 55, 221, 34,255];
        aliases[10] = [ 1, 5, 1, 1, 6, 6, 7, 8, 10, 4, 10];
        // earrings
        rarities[11] = [35, 69, 126, 6, 42,  56, 57,  47, 134, 101, 208, 112,  142, 255, 169, 208,  78];
        aliases[11] = [2, 4,  3, 4,  5,  6,  7,  11, 7, 12, 7, 12, 13, 13, 7, 9,  9];
        // mouth
        rarities[12] = [80, 208,  43, 120,67, 139, 190, 255];
        aliases[12] = [ 1, 2, 3, 6, 2, 2, 7, 7];
        // eyes
        rarities[13] = [ 125, 134, 208,  23, 125, 179, 107, 118, 249, 171, 255, 200, 100, 225];
        aliases[13] = [1, 2, 2, 0, 2, 2, 9, 0, 5, 4, 4, 4, 4, 4];
        // weapon
        rarities[14] = [159, 229,  84,  93, 176, 53, 113, 123, 103,  94, 78,  96, 255];
        aliases[14] = [ 1, 2, 11, 2, 2, 9, 9, 9, 10, 10, 11, 12,12];
        //  alphaIndex
        rarities[15] = [ 173, 255, 163, 10 ];
        aliases[15] =  [ 1, 1, 0, 0 ];
    }


    /**
    * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
    * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
    * probability & alias tables are generated off-chain beforehand
    * @param seed portion of the 256 bit seed to remove trait correlation
    * @param traitType the trait type to select a trait for 
    * @return the ID of the randomly selected trait
    */
    function selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
        // If a selected random trait probability is selected (biased coin) return that trait
        if (seed >> 8 < rarities[traitType][trait]) return trait + 1;
        return aliases[traitType][trait] + 1;
    }

    /**
    * selects the species and all of its traits based on the seed value
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t -  a struct of randomly selected traits
    */
    function selectTraits(uint256 seed) internal view returns (IPnG.GalleonPirate memory t) {    
        t.isGalleon = (seed & 0xFFFF) % 10 != 0;

        if (t.isGalleon) {
            seed >>= 16;
            t.base = selectTrait(uint16(seed & 0xFFFF), 0);

            seed >>= 16;
            t.deck = selectTrait(uint16(seed & 0xFFFF), 1);

            seed >>= 16;
            t.sails = selectTrait(uint16(seed & 0xFFFF), 2);

            seed >>= 16;
            t.crowsNest = selectTrait(uint16(seed & 0xFFFF), 3);

            seed >>= 16;
            t.decor = selectTrait(uint16(seed & 0xFFFF), 4);

            seed >>= 16;
            t.flags = selectTrait(uint16(seed & 0xFFFF), 5);

            seed >>= 16;
            t.bowsprit = selectTrait(uint16(seed & 0xFFFF), 6);

            seed >>= 16;
            t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), 7) - 1;
            t.hat = t.alphaIndex;
        }
        else {
            seed >>= 16;
            t.skin = selectTrait(uint16(seed & 0xFFFF), 8);

            seed >>= 16;
            t.clothes = selectTrait(uint16(seed & 0xFFFF), 9);

            seed >>= 16;
            t.hair = selectTrait(uint16(seed & 0xFFFF), 10);

            seed >>= 16;
            t.earrings = selectTrait(uint16(seed & 0xFFFF), 11);

            seed >>= 16;
            t.mouth = selectTrait(uint16(seed & 0xFFFF), 12);

            seed >>= 16;
            t.eyes = selectTrait(uint16(seed & 0xFFFF), 13);

            seed >>= 16;
            t.weapon = selectTrait(uint16(seed & 0xFFFF), 14);

            seed >>= 16;
            t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), 15) - 1;
            t.hat = t.alphaIndex;
        }

        return t;
    }
}



contract PnG is IPnG, ERC721, Accessable, Pausable, TraitSelector {
    uint256 constant MAX_INT = type(uint256).max;

    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

    event GalleonMinted(uint256 indexed tokenId);
    event PirateMinted(uint256 indexed tokenId);

    event GalleonStolen(uint256 indexed tokenId);
    event PirateStolen(uint256 indexed tokenId);
    
    event GalleonBurned(uint256 indexed tokenId);
    event PirateBurned(uint256 indexed tokenId);

    // max number of tokens that can be minted: 50000 in production
    uint256 public maxTokens;
    // number of tokens that can be claimed for a fee: 10,000
    uint256 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public override minted;

    // tokenId -> traits
    mapping(uint256 => GalleonPirate) private tokenTraits;
    // tokenHash -> tokenId
    mapping(uint256 => uint256) public existingCombinations;
    // Tracks the last block and timestamp that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => LastWrite) private lastWriteAddress;
    mapping(uint256 => LastWrite) private lastWriteToken;

    // reference to the Fleet contract to allow transfers to it without approval
    IFleet public fleet;
    ITraits public traits;

    constructor(uint256 _maxTokens) ERC721("Pirate Game", "PnG") {
        maxTokens = _maxTokens;
        PAID_TOKENS = _maxTokens / 5;
        _pause();
    }

    /** MODIFIERS */

    modifier requireContractsSet() {
        require(address(traits) != address(0) && address(fleet) != address(0), "Contracts not set");
        _;
    }

    modifier blockIfChangingAddress() {
        require(isAdmin(_msgSender()) || lastWriteAddress[tx.origin].blockNum < block.number, "Cannot interact in the current block");
        _;
    }

    modifier blockIfChangingToken(uint256 tokenId) {
        require(isAdmin(_msgSender()) || lastWriteToken[tokenId].blockNum < block.number, "Cannot interact in the current block");
        _;
    }

    function setContracts(address _traits, address _fleet) external onlyOwner {
        traits = ITraits(_traits);
        fleet = IFleet(_fleet);
    }

    /** EXTERNAL */

    function getTokenWriteBlock(uint256 tokenId) external view override
        onlyAdmin
        returns(uint64) 
    {
        return lastWriteToken[tokenId].blockNum;
    }

    /** 
    * Mint a token - any payment / game logic should be handled in the game contract. 
    * This will just generate random traits and mint a token to a designated address.
    */
    function mint(address recipient, uint256 seed) external override 
        whenNotPaused 
        onlyAdmin
    {
        require(minted + 1 <= maxTokens, "All tokens minted");
        minted++;
        generate(minted, seed);
        if(tx.origin != recipient && recipient != address(fleet)) {
            // Stolen!
            if(tokenTraits[minted].isGalleon) {
                emit GalleonStolen(minted);
            }
            else {
                emit PirateStolen(minted);
            }
        }
        _safeMint(recipient, minted);
    }

    /** 
    * Burn a token - any game logic should be handled before this function.
    */
    function burn(uint256 tokenId) external override 
        whenNotPaused 
        onlyAdmin
    {
        require(ownerOf(tokenId) == tx.origin, "Oops you don't own that");
        if(tokenTraits[tokenId].isGalleon) {
            emit GalleonBurned(tokenId);
        }
        else {
            emit PirateBurned(tokenId);
        }
        _burn(tokenId);
    }

    function updateOriginAccess(uint16[] memory tokenIds) external override 
        onlyAdmin
    {
        uint64 blockNum = uint64(block.number);
        uint64 time = uint64(block.timestamp);
        lastWriteAddress[tx.origin] = LastWrite(time, blockNum);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            lastWriteToken[tokenIds[i]] = LastWrite(time, blockNum);
        }
    }

    function transferFrom( address from, address to, uint256 tokenId) 
        public 
        virtual 
        override(ERC721, IERC721) 
        blockIfChangingToken(tokenId) 
    {
        // allow admin contracts to be send without approval
        if(!isAdmin(_msgSender())) {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        }
        _transfer(from, to, tokenId);
    }

    /** INTERNAL */

    /**
    * generates traits for a specific token, checking to make sure it's unique
    * @param tokenId the id of the token to generate traits for
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t - a struct of traits for the given token ID
    */
    function generate(uint256 tokenId, uint256 seed) internal returns (GalleonPirate memory t) {
        t = selectTraits(seed);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;

            if(t.isGalleon)
                emit GalleonMinted(tokenId);
            else
                emit PirateMinted(tokenId);

            return t;
        }

        if (seed == MAX_INT)
            return generate(tokenId, 1);
        else
            return generate(tokenId, seed+1);
    }

    /**
    * converts a struct to a 256 bit hash to check for uniqueness
    * @param s the struct to pack into a hash
    * @return the 256 bit hash of the struct
    */
    function structToHash(GalleonPirate memory s) internal pure returns (uint256) {
        if (s.isGalleon) {
            return uint256(keccak256(abi.encodePacked(
                s.isGalleon,
                // Galleon
                s.base,
                s.deck,
                s.sails,
                s.crowsNest,
                s.decor,
                s.flags,
                s.bowsprit
        )));
        } else {
            return uint256(keccak256(abi.encodePacked(
                s.isGalleon,
                s.skin,
                s.clothes,
                s.hair,
                s.earrings,
                s.mouth,
                s.eyes,
                s.weapon,
                s.hat,
                s.alphaIndex
            )));
        }
    }

    /** READ */

    function isGalleon(uint256 tokenId) external view override 
        blockIfChangingToken(tokenId) 
        returns (bool) 
    {
        IPnG.GalleonPirate memory s = tokenTraits[tokenId];
        return s.isGalleon;
    }

    function getMaxTokens() external view override returns (uint256) {
        return maxTokens;
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    /** ADMIN */

    /**
    * updates the number of tokens for sale
    */
    function _setTokensAmount(uint16 _paidTokens, uint16 _maxTokens) external onlyAdmin {
        PAID_TOKENS = _paidTokens;
        maxTokens = _maxTokens;
    }

    /**
    * enables owner to pause / unpause minting
    */
    function _setPaused(bool _paused) external requireContractsSet onlyAdmin {
        if (_paused) _pause();
        else _unpause();
    }


    /** Traits */

    function getTokenTraits(uint256 tokenId) external view override 
        blockIfChangingAddress 
        blockIfChangingToken(tokenId) 
        returns (GalleonPirate memory) 
    {
        return tokenTraits[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override 
        blockIfChangingAddress 
        blockIfChangingToken(tokenId) 
        returns (string memory) 
    {
        require(_exists(tokenId), "Token ID does not exist");
        return traits.tokenURI(tokenId);
    }


    function totalSupply() public view returns (uint256) {
        return minted;
    }

    
    function balanceOf(address owner) public view virtual override(ERC721, IERC721) 
        blockIfChangingAddress 
        returns (uint256) 
    {
        // checking on this address in the same block it's being modified
        require(
            isAdmin(_msgSender()) || lastWriteAddress[owner].blockNum < block.number, 
            "Cannot interact in the current block"
        );
        return super.balanceOf(owner);
    }


    function ownerOf(uint256 tokenId) public view virtual override(ERC721, IERC721) 
        blockIfChangingAddress 
        blockIfChangingToken(tokenId) 
        returns (address) 
    {
        address addr = super.ownerOf(tokenId);
        // checking on this address in the same block it's being modified
        require(
            isAdmin(_msgSender()) || lastWriteAddress[addr].blockNum < block.number, 
            "Cannot interact in the current block"
        );
        return addr;
    }


    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(
            isAdmin(_msgSender()) || lastWriteToken[index+1].blockNum < block.number, 
            "Cannot interact in the current block"
        );
        return index + 1;
    }


    function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721) 
        blockIfChangingToken(tokenId) 
    {
        super.approve(to, tokenId);
    }


    function getApproved(uint256 tokenId) public view virtual override(ERC721, IERC721) 
        blockIfChangingToken(tokenId) 
        returns (address) 
    {
        return super.getApproved(tokenId);
    }


    function setApprovalForAll(address operator, bool approved) 
        public virtual override(ERC721, IERC721) 
        blockIfChangingAddress 
    {
        super.setApprovalForAll(operator, approved);
    }


    function isApprovedForAll(address owner, address operator) 
        public view virtual override(ERC721, IERC721) 
        blockIfChangingAddress 
        returns (bool) 
    {
        return super.isApprovedForAll(owner, operator);
    }
    

    function safeTransferFrom( address from, address to, uint256 tokenId) 
        public virtual override(ERC721, IERC721) 
        blockIfChangingToken(tokenId) 
    {
        super.safeTransferFrom(from, to, tokenId);
    }


    function safeTransferFrom( address from, address to, uint256 tokenId, bytes memory _data)
        public virtual override(ERC721, IERC721) 
        blockIfChangingToken(tokenId) 
    {
        super.safeTransferFrom(from, to, tokenId, _data);
    }


    /**
     * allows owner to withdraw funds from minting
     */
    function _withdraw() external onlyTokenClaimer {
        payable(_msgSender()).transfer(address(this).balance);
    }
}