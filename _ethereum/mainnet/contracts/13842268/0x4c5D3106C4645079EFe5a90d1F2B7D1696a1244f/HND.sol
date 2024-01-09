// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./IHND.sol";
import "./IKingdom.sol";
import "./ITraits.sol";
import "./IEXP.sol";

contract HND is IHND, ERC721Enumerable, Ownable, Pausable {

    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

    event HeroMinted(uint256 indexed tokenId);
    event DemonMinted(uint256 indexed tokenId);
    event heroStolen(uint256 indexed tokenId);
    event DemonStolen(uint256 indexed tokenId);
    event HeroBurned(uint256 indexed tokenId);
    event DemonBurned(uint256 indexed tokenId);

    // max number of tokens that can be minted: 60000 in production
    uint256 public maxTokens;
    // number of tokens that can be claimed for a fee: 15,000
    uint256 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public override minted;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => HeroDemon) private tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;
    // Tracks the last block and timestamp that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => LastWrite) private lastWriteAddress;
    mapping(uint256 => LastWrite) private lastWriteToken;

    // list of probabilities for each trait type
    // 0 - 10 are associated with Hero, 11 - 17 are associated with Demons
    uint8[][18] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 10 are associated with Hero, 11 - 17 are associated with Demons
    uint8[][18] public aliases;

    // reference to the Kingdom contract to allow transfers to it without approval
    IKingdom public kingdom;
    // reference to Traits
    ITraits public traits;


    // address => allowedToCallFunctions
    mapping(address => bool) private admins;

    constructor(uint256 _maxTokens) ERC721("Heroes & Demons Game", "HnD") {
        maxTokens = _maxTokens;
        PAID_TOKENS = _maxTokens / 5;
        _pause();

        // A.J. Walker's Alias Algorithm
        // HEROES
        // body
        aliases[0] = [0];
        rarities[0] = [255];

        // face - male
        aliases[1] = [1, 0, 0, 1, 3, 4, 5, 6, 7, 8, 7, 7, 14, 14, 9];
        rarities[1] = [66, 44, 42, 55, 67, 65, 63, 63, 49, 78, 4, 35, 21, 43, 55];

        // face - female
        aliases[2] = [1, 1, 4, 1, 3];
        rarities[2] = [151, 173, 103, 153, 170];

        // headpiece - male
        aliases[3]= [1, 0, 1, 2, 2, 3, 5, 6, 7, 8, 9, 10, 2, 3, 5, 7, 8, 9, 11];
        rarities[3] = [45, 56, 84, 51, 18, 59, 45, 65, 46, 56, 48, 49, 27, 25, 22, 19, 19, 10, 6];

        // headpiece - female
        aliases[4] = [1, 0, 0, 1, 1, 3];
        rarities[4] = [194, 156, 48, 195, 93, 64];

        //armor-male
        aliases[5] = [1, 2, 0, 4, 2, 4, 9, 5, 9, 7];
        rarities[5] = [111, 41, 110, 21, 105, 98, 19, 107, 43, 95];

        //armor-female
        aliases[6] = [1, 0, 1, 0, 2];
        rarities[6] = [231, 197, 164, 126, 32];

        //gloves
        aliases[7] = [1, 0, 1, 2, 0, 3, 2, 5, 5, 5];
        rarities[7] = [108, 88, 79, 82, 64, 139, 40, 44, 78, 28];

        //shoes
        aliases[8] = [1, 2, 0, 2, 3, 3, 7, 3, 1, 7];
        rarities[8] = [112, 38, 107, 114, 26, 72, 27, 142, 74, 38];

        //weapon
        aliases[9] = [1, 0, 3, 0, 3, 3, 3, 6, 6, 6, 6, 9, 9, 9, 12];
        rarities[9] = [130, 18, 9, 84, 41, 38, 114, 21, 38, 91, 41, 17, 58, 15, 35];
        
        //shield
        aliases[10]= [1, 2, 0, 2, 5, 2];
        rarities[10] = [199, 56, 242, 97, 16, 140];

        // DEMONS
     
        //demon-body
        aliases[11] = [1, 2, 0, 4, 2, 6, 4, 8, 6, 8];
        rarities[11] = [128, 54, 173, 19, 170, 65, 151, 40, 134, 66];

        //demon-eyes
        aliases[12] = [1, 5, 6, 1, 9, 0, 5, 9, 6, 8];
        rarities[12] = [180, 22, 29, 98, 10, 147, 129, 19, 165, 201];

        // demon-horns
        aliases[13] = [1, 0, 1, 8, 10, 12, 14, 14, 2, 14, 8, 10, 11, 14, 12];
        rarities[13] = [64, 64, 101, 5, 45, 18, 75, 69, 100, 39, 105, 69, 94, 53, 99];

        // demon-tailflame
        aliases[14] = [1, 2, 0, 4, 2, 4, 5];
        rarities[14] = [236, 33, 192, 96, 170, 180, 93];

        // demon-armor
        aliases[15] = [1, 1, 5, 6, 1, 4, 5];
        rarities[15] = [151, 182, 16, 54, 131, 254, 196, 1];

        //demon-weapon
        aliases[16] = [1, 0, 0, 4, 2, 4, 4, 4, 6, 6, 9, 9, 11, 9, 12];
        rarities[16] = [120, 28, 70, 18, 189, 37, 133, 11, 24, 119, 12, 71, 79, 58, 31];

        // demon-rank
        rarities[17] = [14, 155, 80, 255];
        aliases[17] = [2, 3, 3, 3];
    }

    /** CRITICAL TO SETUP / MODIFIERS */

    modifier requireContractsSet() {
        require(address(traits) != address(0) && address(kingdom) != address(0), "Contracts not set");
        _;
    }

    modifier blockIfChangingAddress() {
        // frens can always call whenever they want :)
        require(admins[_msgSender()] || lastWriteAddress[tx.origin].blockNum < block.number, "hmmmm what doing?");
        _;
    }

    modifier blockIfChangingToken(uint256 tokenId) {
        // frens can always call whenever they want :)
        require(admins[_msgSender()] || lastWriteToken[tokenId].blockNum < block.number, "hmmmm what doing?");
        _;
    }

    function setContracts(address _traits, address _kingdom) external onlyOwner {
        traits = ITraits(_traits);
        kingdom = IKingdom(_kingdom);
    }

    /** EXTERNAL */

    function getTokenWriteBlock(uint256 tokenId) external view override returns(uint64) {
        require(admins[_msgSender()], "Only admins can call this");
        return lastWriteToken[tokenId].blockNum;
    }

    /** 
    * Mint a token - any payment / game logic should be handled in the game contract. 
    * This will just generate random traits and mint a token to a designated address.
    */
    function mint(address recipient, uint256 seed) external override whenNotPaused {
        require(admins[_msgSender()], "Only admins can call this");
        require(minted + 1 <= maxTokens, "All tokens minted");
        minted++;
        generate(minted, seed, lastWriteAddress[tx.origin]);
        if(tx.origin != recipient && recipient != address(kingdom)) {
            // Stolen!
            if(tokenTraits[minted].isHero) {
                emit heroStolen(minted);
            }
            else {
                emit DemonStolen(minted);
            }
        }
        _safeMint(recipient, minted);
    }

    /** 
    * Burn a token - any game logic should be handled before this function.
    */
    function burn(uint256 tokenId) external override whenNotPaused {
        require(admins[_msgSender()], "Only admins can call this");
        require(ownerOf(tokenId) == tx.origin, "Oops you don't own that");
        if(tokenTraits[tokenId].isHero) {
            emit HeroBurned(tokenId);
        }
        else {
            emit DemonBurned(tokenId);
        }
        _burn(tokenId);
    }

    function updateOriginAccess(uint16[] memory tokenIds) external override {
        require(admins[_msgSender()], "Only admins can call this");
        uint64 blockNum = uint64(block.number);
        uint64 time = uint64(block.timestamp);
        lastWriteAddress[tx.origin] = LastWrite(time, blockNum);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            lastWriteToken[tokenIds[i]] = LastWrite(time, blockNum);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) {
        // allow admin contracts to be send without approval
        if(!admins[_msgSender()]) {
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
    function generate(uint256 tokenId, uint256 seed, LastWrite memory lw) internal returns (HeroDemon memory t) {
        t = selectTraits(seed);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            if(t.isHero) {
                emit HeroMinted(tokenId);
            }
            else {
                emit DemonMinted(tokenId);
            }
            return t;
        }

        // if not random, hash the seed and try again
        return generate(tokenId, uint256(keccak256(abi.encode(seed))), lw);
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
        if (seed >> 8 < rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    /**
    * selects the species and all of its traits based on the seed value
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t -  a struct of randomly selected traits
    */

    function selectTraits(uint256 seed) internal view returns (HeroDemon memory t) {    
        t.isHero = (seed & 0xFFFF) % 10 != 0; // 90% chance it's a hero

        t.isFemale = (seed & 0xFFFF) % 10 <= 3; // 30% chance for female

        // t.isFemale is cast as 0/1 for false/true
        uint8 isFemale;
        if (t.isFemale) {
            isFemale = 1;
        }
        
        t.body = t.isHero ? 0 : selectTrait(uint16(seed & 0xFFFF), 11);
        seed >>= 16;
        
        t.weapon = selectTrait(uint16(seed & 0xFFFF), t.isHero ? 9 : 16);
        seed >>= 16;

        t.armor = selectTrait(uint16(seed & 0xFFFF), t.isHero ? 5 + isFemale : 15);
        seed >>= 16;

        t.headpiecehorns = selectTrait(uint16(seed & 0xFFFF), t.isHero ? 3 + isFemale : 13);
        seed >>= 16;   
           

        if (t.isHero) {   
            // body is shared

            t.face = selectTrait(uint16(seed & 0xFFFF), 1 + isFemale);
            seed >>= 16;

            // headpiecehorns is shared

            // armor is shared

            t.gloves = selectTrait(uint16(seed & 0xFFFF), 7);
            seed >>= 16;
            
            t.shoes = selectTrait(uint16(seed & 0xFFFF), 8);
            seed >>= 16;   
            
            // weapon is "shared"
            
            t.shield = selectTrait(uint16(seed & 0xFFFF), 10);
            seed >>= 16;
        } else {
            t.eyes = selectTrait(uint16(seed & 0xFFFF), 12);
            seed >>= 16;
            
            // headpiecehorns is shared

            // armor is shared
            
            t.tailflame = selectTrait(uint16(seed & 0xFFFF), 14);
            seed >>= 16;            
            
            t.rankIndex = selectTrait(uint16(seed & 0xFFFF), 17);
            seed >>= 16;
        }
 
    }

    /**
    * converts a struct to a 256 bit hash to check for uniqueness
    * @param s the struct to pack into a hash
    * @return the 256 bit hash of the struct
    */
    function structToHash(HeroDemon memory s) internal pure returns (uint256) {
        return uint256(keccak256(
            abi.encodePacked(
                s.isHero,
                s.isFemale,
                s.body,
                s.face,
                s.headpiecehorns,
                s.gloves,
                s.armor,
                s.weapon,
                s.shield,
                s.shoes,
                s.tailflame,
                s.rankIndex
            )
        ));
    }

    /** READ */

    /**
    * checks if a token is a heroes
    * @param tokenId the ID of the token to check
    * @return wizard - whether or not a token is a heroes
    */
    function isHero(uint256 tokenId) external view override blockIfChangingToken(tokenId) returns (bool) {
        // Sneaky dragons will be slain if they try to peep this after mint. Nice try.
        IHND.HeroDemon memory s = tokenTraits[tokenId];
        return s.isHero;
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
    function setPaidTokens(uint256 _paidTokens) external onlyOwner {
        PAID_TOKENS = uint16(_paidTokens);
    }

    /**
    */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
    * enables an address to mint / burn
    * @param addr the address to enable
    */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
    * disables an address from minting / burning
    * @param addr the address to disbale
    */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    /** Traits */

    function getTokenTraits(uint256 tokenId) external view override blockIfChangingAddress blockIfChangingToken(tokenId) returns (HeroDemon memory) {
        return tokenTraits[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override blockIfChangingAddress blockIfChangingToken(tokenId) returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        return traits.tokenURI(tokenId);
    }

    /** OVERRIDES FOR SAFETY */

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override(ERC721Enumerable, IERC721Enumerable) blockIfChangingAddress returns (uint256) {
        // Y U checking on this address in the same block it's being modified... hmmmm
        require(admins[_msgSender()] || lastWriteAddress[owner].blockNum < block.number, "hmmmm what doing?");
        uint256 tokenId = super.tokenOfOwnerByIndex(owner, index);
        require(admins[_msgSender()] || lastWriteToken[tokenId].blockNum < block.number, "hmmmm what doing?");
        return tokenId;
    }
    
    function balanceOf(address owner) public view virtual override(ERC721, IERC721) blockIfChangingAddress returns (uint256) {
        // Y U checking on this address in the same block it's being modified... hmmmm
        require(admins[_msgSender()] || lastWriteAddress[owner].blockNum < block.number, "hmmmm what doing?");
        return super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view virtual override(ERC721, IERC721) blockIfChangingAddress blockIfChangingToken(tokenId) returns (address) {
        address addr = super.ownerOf(tokenId);
        // Y U checking on this address in the same block it's being modified... hmmmm
        require(admins[_msgSender()] || lastWriteAddress[addr].blockNum < block.number, "hmmmm what doing?");
        return addr;
    }

    function tokenByIndex(uint256 index) public view virtual override(ERC721Enumerable, IERC721Enumerable) returns (uint256) {
        uint256 tokenId = super.tokenByIndex(index);
        // NICE TRY TOAD DRAGON
        require(admins[_msgSender()] || lastWriteToken[tokenId].blockNum < block.number, "hmmmm what doing?");
        return tokenId;
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) {
        super.approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) returns (address) {
        return super.getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, IERC721) blockIfChangingAddress {
        super.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override(ERC721, IERC721) blockIfChangingAddress returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

}