// SPDX-License-Identifier: MIT LICENSE

/**
       .     '     ,      '     ,     .     '   .    
      _________        _________       _________    
   _ /_|_____|_\ _  _ /_|_____|_\ _ _ /_|_____|_\ _ 
     '. \   / .'      '. \   / .'     '. \   / .'   
       '.\ /.'          '.\ /.'         '.\ /.'     
         '.'              '.'             '.'
 
 ██████╗ ██╗ █████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██████╗  
 ██╔══██╗██║██╔══██╗████╗ ████║██╔═══██╗████╗  ██║██╔══██╗ 
 ██║  ██║██║███████║██╔████╔██║██║   ██║██╔██╗ ██║██║  ██║ 
 ██║  ██║██║██╔══██║██║╚██╔╝██║██║   ██║██║╚██╗██║██║  ██║ 
 ██████╔╝██║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██████╔╝ 
 ╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝  
           ██╗  ██╗███████╗██╗███████╗████████╗
           ██║  ██║██╔════╝██║██╔════╝╚══██╔══╝   <'l    
      __   ███████║█████╗  ██║███████╗   ██║       ll    
 (___()'`; ██╔══██║██╔══╝  ██║╚════██║   ██║       llama~
 /,    /`  ██║  ██║███████╗██║███████║   ██║       || || 
 \\"--\\   ╚═╝  ╚═╝╚══════╝╚═╝╚══════╝   ╚═╝       '' '' 

*/

pragma solidity ^0.8.0;
import "./MerkleProof.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "./IDiamondHeist.sol";
import "./IDIAMOND.sol";
import "./IStaking.sol";
import "./ITraits.sol";
import "./IHeistPass.sol";

contract DiamondHeistV7 is
    ERC721AUpgradeable,
    IDiamondHeist,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    event LlamaMinted(uint256 indexed tokenId);
    event DogMinted(uint256 indexed tokenId);
    event LlamaBurned(uint256 indexed tokenId);
    event DogBurned(uint256 indexed tokenId);

    // max number of tokens that can be minted - 37,500 in production
    uint256 public constant MAX_TOKENS = 37500;
    // number of tokens that can be claimed for a fee - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS;

    uint256 public MINT_PRICE;

    // whitelist, 10 mints, get a discount, 1 free
    uint16 public constant MAX_COMMUNITY_AMOUNT = 5;
    uint256 public COMMUNITY_SALE_MINT_PRICE;
    bytes32 public whitelistMerkleRoot;
    mapping(address => uint256) public claimed;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => LlamaDog) public tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    // list of probabilities for each trait type
    uint8[][14] public rarities;
    // list of aliases for Walker's Alias algorithm
    uint8[][14] public aliases;

    // reference to the Staking for choosing random Dog thieves
    IStaking public staking;
    // reference to $DIAMOND for burning on mint
    IDIAMOND public diamond;
    // reference to Traits
    ITraits public traits;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC721A_init("Diamond Heist", "DIAMONDHEIST");
        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        _pause();

        PAID_TOKENS = 7500;
        MINT_PRICE = .06 ether;
        COMMUNITY_SALE_MINT_PRICE = .04 ether;

        // Llama/Body
        rarities[0] = [255, 61, 122, 30, 183, 224, 142, 30, 214, 173, 214, 122];
        aliases[0] = [0, 0, 0, 7, 7, 0, 5, 6, 7, 8, 8, 9];
        
        // Llama/Hat
        rarities[1] = [114, 254, 191, 152, 242, 152, 191, 229, 242, 114, 254, 76, 76, 203, 191];
        aliases[1] = [6, 0, 6, 6, 1, 6, 4, 6, 6, 6, 8, 6, 8, 10, 13];
        
        // Llama/Eye
        rarities[2] = [165, 66, 198, 255, 165, 211, 168, 165, 107, 99, 186, 175, 165];
        aliases[2] = [6, 6, 6, 0, 6, 3, 5, 6, 6, 8, 8, 10, 11];
        
        // Llama/Mouth
        rarities[3] = [140, 224, 28, 112, 112, 112, 254, 229, 160, 221, 140];
        aliases[3] = [7, 7, 7, 7, 7, 8, 0, 6, 7, 8, 9];
        
        // Llama/Clothes
        rarities[4] = [229, 254, 191, 216, 127, 152, 152, 165, 76, 114, 254, 152, 203, 76, 191];
        aliases[4] = [1, 0, 1, 2, 3, 2, 2, 4, 2, 4, 7, 4, 10, 7, 12];
        
        // Llama/Tail
        rarities[5] = [127, 255, 127, 127, 229, 102, 255, 255, 178, 51];
        aliases[5] = [7, 0, 7, 7, 7, 7, 0, 0, 7, 8];
        
        // Llama/alphaIndex
        rarities[6] = [255];
        aliases[6] = [0];
        
        // Dog/Body
        rarities[7] = [140, 254, 28, 224, 56, 181, 244, 84, 219, 28, 193];
        aliases[7] = [1, 0, 1, 1, 5, 1, 5, 5, 6, 10, 8];
        
        // Dog/Hat
        rarities[8] = [99, 165, 255, 178, 33, 232, 102, 33, 198, 232, 209, 198, 132];
        aliases[8] = [6, 6, 0, 2, 6, 6, 3, 6, 6, 6, 6, 6, 10];
        
        // Dog/Eye
        rarities[9] = [254, 30, 224, 153, 203, 30, 153, 214, 91, 91, 214, 153];
        aliases[9] = [0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 4];
        
        // Dog/Mouth
        rarities[10] = [254, 122, 61, 30, 61, 122, 142, 91, 91, 183, 244, 244];
        aliases[10] = [0, 0, 0, 0, 8, 8, 0, 9, 6, 8, 9, 9];
        
        // Dog/Clothes
        rarities[11] = [254, 107, 107, 35, 152, 198, 35, 107, 117, 132, 107, 107, 107, 107];
        aliases[11] = [0, 4, 5, 5, 0, 4, 5, 5, 5, 8, 8, 8, 9, 9];
        
        // Dog/Tail
        rarities[12] = [140, 254, 84, 84, 84, 203, 140, 196, 196, 140, 140];
        aliases[12] = [1, 0, 5, 5, 5, 1, 5, 5, 5, 5, 5];
        
        // Dog/alphaIndex
        rarities[13] = [20, 153, 255, 204];
        aliases[13] = [3, 3, 0, 2];
    }

    modifier requireContractsSet() {
        require(
            address(traits) != address(0) && address(staking) != address(0),
            "Contracts not set"
        );
        _;
    }

    function setContracts(ITraits _traits, IStaking _staking, IDIAMOND _diamond)
        external
        onlyOwner
    {
        traits = _traits;
        staking = _staking;
        diamond = _diamond;
    }

    function setWhiteListMerkleRoot(bytes32 _root) external onlyOwner {
        whitelistMerkleRoot = _root;
    }

    modifier isValidMerkleProof(bytes32[] memory proof) {
        require(
            MerkleProof.verify(
                proof,
                whitelistMerkleRoot,
                bytes32(uint256(uint160(_msgSender())))
            ),
            "INVALID_MERKLE_PROOF"
        );
        _;
    }

    /** EXTERNAL */
    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function minted() external view returns (uint256) {
        return _totalMinted();
    }

    function communitySaleLeft(bytes32[] memory merkleProof)
        external
        view
        isValidMerkleProof(merkleProof)
        returns (uint256)
    {
        if (_totalMinted() >= PAID_TOKENS) return 0;
        return MAX_COMMUNITY_AMOUNT - claimed[_msgSender()];
    }

    /**
     * mint a token - 90% Llama, 10% Dog
     * The first 20% are free to claim, the remaining cost $DIAMOND
     */
    function mintGame(uint256 amount, bool stake)
        internal
        whenNotPaused
        nonReentrant
    {
        uint256 tokenId = _totalMinted();
        require(tx.origin == _msgSender(), "ONLY_EOA");
        require(tokenId + amount <= MAX_TOKENS, "MINT_ENDED");
        require(amount > 0 && amount <= 15, "MINT_AMOUNT_INVALID");

        commits[commitId].recipient = _msgSender();
        commits[commitId].amount = uint16(amount);
        commits[commitId].stake = stake;
        userCommits[_msgSender()].push(commitId);

        uint256 totalDiamondCost = 0;
        for (uint256 index = 1; index <= amount;) {
         totalDiamondCost += mintCost(tokenId + index);
         unchecked { ++index; }
        }

        if (totalDiamondCost > 0) diamond.burn(_msgSender(), totalDiamondCost);

        emit MintCommited(commitId++, amount, stake);
    }

    /**
     * mint a token - 90% Llama, 10% Dog
     * The first 20% are free to claim, the remaining cost $DIAMOND
     */
    function mint(uint256 amount, bool stake) external payable {
        if (_totalMinted() < PAID_TOKENS) {
            // we have to still pay in ETH, we can make a transaction that pays both in ETH and DIAMOND
            // check how many tokens should be paid in ETH, the DIAMOND will be burned in mintGame function
            require(msg.value == (amount > (PAID_TOKENS - _totalMinted()) ? (PAID_TOKENS - _totalMinted()) : amount) * MINT_PRICE, "MINT_PAID_PRICE_INVALID");
        } else {
            require(msg.value == 0, "MINT_PAID_IN_DIAMONDS");
        }
        mintGame(amount, stake);
    }

    function mintCommunitySale(
        bytes32[] memory merkleProof,
        uint256 amount,
        bool stake
    ) external payable isValidMerkleProof(merkleProof) {
        require(
            claimed[_msgSender()] + amount <= MAX_COMMUNITY_AMOUNT,
            "MINT_COMMUNITY_ENDED"
        );
        require(_totalMinted() + amount <= PAID_TOKENS, "MINT_ENDED");
        require(msg.value == COMMUNITY_SALE_MINT_PRICE * (claimed[_msgSender()] == 0 ? amount - 1 : amount), "MINT_COMMUNITY_PRICE_INVALID");
        claimed[_msgSender()] += amount;
        mintGame(amount, stake);
    }

    /**
     * 0 - 20% = eth
     * 20 - 40% = 200 DIAMONDS
     * 40 - 60% = 300 DIAMONDS
     * 60 - 80% = 400 DIAMONDS
     * 80 - 100% = 500 DIAMONDS
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= PAID_TOKENS) return 0; // 1 / 5 = PAID_TOKENS
        if (tokenId <= (MAX_TOKENS * 2) / 5) return 2000 ether;
        if (tokenId <= (MAX_TOKENS * 3) / 5) return 5000 ether;
        if (tokenId <= (MAX_TOKENS * 4) / 5) return 10000 ether;
        return 20000 ether;
    }

    function isApprovedForAll(address owner, address operator) public view override(ERC721AUpgradeable, IERC721Upgradeable) returns (bool) {
        return (address(staking) == operator || ERC721AUpgradeable.isApprovedForAll(owner, operator));
    }

    /** INTERNAL */

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param tokenId the id of the token to generate traits for
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t - a struct of traits for the given token ID
     */
    function generate(uint256 tokenId, uint256 seed)
        internal
        returns (LlamaDog memory t)
    {
        t = selectTraits(tokenId, seed);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            if (t.isLlama) {
                emit LlamaMinted(tokenId);
            } else {
                emit DogMinted(tokenId);
            }
            return t;
        }
        return generate(tokenId, random(seed));
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
        // If a selected random trait probability is selected (biased coin) return that trait
        if (seed >> 8 <= rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */
    function selectTraits(uint256, uint256 seed)
        internal
        view
        returns (LlamaDog memory t)
    {
        t.isLlama = (seed & 0xFFFF) % 10 != 0;
        uint8 shift = t.isLlama ? 0 : 7;

        // what happens here is that we check the 16 least signficial bits of the seed
        // and then remove them from the seed, so that the next 16 bits are used for the next trait
        // Before: EBD302F8B72AB0883F98D59C3BB7C25C61E30A77AB5F93924D234A620A32
        // After:  EBD302F8B72AB0883F98D59C3BB7C25C61E30A77AB5F93924D234A62
        // trait 1: 0A32 -> 00001010 00110010
        seed >>= 16;
        t.body = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
        seed >>= 16;
        t.hat = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        t.eye = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        t.mouth = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        seed >>= 16;
        t.clothes = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        seed >>= 16;
        t.tail = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
    }

    /**
     * converts a struct to a 256 bit hash to check for uniqueness
     * @param s the struct to pack into a hash
     * @return the 256 bit hash of the struct
     */
    function structToHash(LlamaDog memory s) internal pure returns (uint256) {
        return
            uint256(
                bytes32(
                    abi.encodePacked(
                        s.isLlama,
                        s.body,
                        s.hat,
                        s.eye,
                        s.mouth,
                        s.clothes,
                        s.tail,
                        s.alphaIndex
                    )
                )
            );
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }

    /** READ */

    function getTokenTraits(uint256 tokenId)
        external
        view
        override
        returns (LlamaDog memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: token traits query for nonexistent token"
        );
        return tokenTraits[tokenId];
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    /**
     * checks if a token is a llama
     * @param tokenId the ID of the token to check
     * @return llama - whether or not a token is a llama
     */
    function isLlama(uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        IDiamondHeist.LlamaDog memory s = tokenTraits[tokenId];
        return s.isLlama;
    }

    /** ADMIN */
    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * updates the number of tokens for sale
     */
    function setPaidTokens(uint256 _paidTokens) external onlyOwner {
        PAID_TOKENS = _paidTokens;
    }

    /**
     * updates the mint price
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        MINT_PRICE = _mintPrice;
        COMMUNITY_SALE_MINT_PRICE = _mintPrice / 4 * 3;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** RENDER */

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721AUpgradeable, IERC721MetadataUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return traits.tokenURI(tokenId);
    }
    
    function updateRarity(uint8 traitType, uint8[] memory _rarities, uint8[] memory _aliases)
        external
        onlyOwner
    {
        rarities[traitType] = _rarities;
        aliases[traitType] = _aliases;
    }

    address llamapool;
    function setLlamapool(address _llamapool) external onlyOwner {
        llamapool = _llamapool;
    }
    function addManyToStaking(address account, uint16[] calldata tokenIds) external whenNotPaused nonReentrant {
        require(account == tx.origin, "Only EOA");
        require(_msgSender() == llamapool, "Only through Llamapool");

        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length;) {
            require(ownerOf(tokenIds[i]) == llamapool, "Llamapool does not own this token");
            transferFrom(address(llamapool), address(staking), tokenIds[i]);
            unchecked { ++i; }
        }
        staking.addManyToStaking(account, tokenIds);
    }

    event MintCommited(uint256 indexed id, uint256 amount, bool stake);
    event MintSeeded(uint256 indexed id);
    event MintRevealed(uint256 indexed id, uint16[] indexed tokenIds);

    struct MintCommit {
        address recipient;
        uint16 amount;
        bool stake;
        bool revealed;
        uint256 seed;
    }
    uint16 public commitId;
    mapping(uint256 => MintCommit) public commits;
    mapping(address => uint16[]) public userCommits;
    address private seeder;

    function setSeeder(address _seeder) external onlyOwner {
        seeder = _seeder;
    }

    function batchSeed(uint16[] calldata _commitIds, uint256[] calldata seeds) external {
        require(_msgSender() == seeder, "ONLY_SEEDER");

        uint256 length = _commitIds.length;
        for (uint256 i = 0; i < length;) {
            require(commits[_commitIds[i]].seed == 0, "Already seeded");
            commits[_commitIds[i]].seed = seeds[i];
            emit MintSeeded(_commitIds[i]);
            unchecked { ++i; }
        }
    }

    function batchReveal(uint16 _commitId) internal {
        MintCommit storage c = commits[_commitId];
        require(!c.revealed, "Already revealed");
        c.revealed = true;

        require(c.seed != 0, "Not yet seeded");

        uint16 tokenId = uint16(_totalMinted());
        uint16[] memory tokenIds = new uint16[](c.amount);

        uint256 length = tokenIds.length;
        for (uint16 index = 0; index < length;) {
            tokenId++;
            generate(tokenId, c.seed << index);
            tokenIds[index] = tokenId;
            unchecked { ++index; }
        }

        _mint(c.stake ? address(staking) : c.recipient, c.amount, "", false);
        if (c.stake) staking.addManyToStaking(c.recipient, tokenIds);

        emit MintRevealed(_commitId, tokenIds);
    }

    function batchUserRevealPending(address recipient) external whenNotPaused nonReentrant {
        require(recipient == tx.origin && recipient == _msgSender(), "Only EOA");

        // loop from userCommits[recipient].length to 0
        for (uint256 index = userCommits[recipient].length; index > 0; index--) {
            uint16 _commitId = userCommits[recipient][index - 1];
            MintCommit memory c = commits[_commitId];
            if (c.seed == 0) break; // reveals everything as long it has a seed
            if (!c.revealed) batchReveal(_commitId);
            userCommits[recipient].pop();
        }
    }

    function getPendingUserCommits(address recipient) public view returns (MintCommit[] memory _commits, uint16[] memory _commitIds) {
        _commits = new MintCommit[](userCommits[recipient].length);
        _commitIds = new uint16[](userCommits[recipient].length);

        uint256 length = userCommits[recipient].length;
        for (uint256 i = 0; i < length;) {
            _commits[i] = commits[userCommits[recipient][i]];
            _commitIds[i] = userCommits[recipient][i];
            unchecked { ++i; }
        }
        return (_commits, _commitIds);
    }

    function revealStuck(address recipient, uint16 userIndex) external whenNotPaused nonReentrant {
        require(_msgSender() == owner() || _msgSender() == recipient, "Only owner or recipient");
        uint16 _commitId = userCommits[recipient][userIndex];
        commits[_commitId].stake = false; // Force no-stake
        batchReveal(_commitId);
    }

    IHeistPass public heistPass;
    function setHeistPass(IHeistPass _heistPass) external onlyOwner {
        heistPass = _heistPass;
    }

    /**
     * Mint with ETH if holding a minting pass
     */
    function mintPass(uint256 passId, uint256 amount, bool stake) external payable {
        uint256 fee = heistPass.getFee(amount);
        require(msg.value == (MINT_PRICE * amount) - fee, "MINT_PAID_PRICE_INVALID");
        heistPass.burn{value: fee}(passId, amount);
        mintGame(amount, stake);
    }

    IHeistPass public referralLink;
    function setReferralLink(IHeistPass _link) external onlyOwner {
        referralLink = _link;
    }

    /**
     * Mint with ETH if holding a minting pass
     */
    function mintReferral(uint256 id, uint256 amount, bool stake) external payable {
        uint256 fee = referralLink.getFee(amount);
        require(msg.value == (MINT_PRICE * amount) - fee, "MINT_PAID_PRICE_INVALID");
        referralLink.burn{value: fee}(id, amount);
        mintGame(amount, stake);
    }
}
