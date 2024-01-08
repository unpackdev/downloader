// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./ISharks.sol";
import "./ICoral.sol";
import "./ITraits.sol";
import "./IChum.sol";
import "./IRandomizer.sol";

contract Sharks is ISharks, ERC721Enumerable, Ownable, Pausable {
    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

    event TokenMinted(uint256 indexed tokenId, ISharks.SGTokenType indexed tokenType);
    event TokenStolen(uint256 indexed tokenId, ISharks.SGTokenType indexed tokenType);

    // max number of tokens that can be minted: 30000 in production
    uint16 public maxTokens;
    // number of tokens that can be claimed for a fee: 5,000
    uint16 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public override minted;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => SGToken) private tokenTraits;
    // Tracks the last block and timestamp that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => LastWrite) private lastWriteAddress;
    mapping(uint256 => LastWrite) private lastWriteToken;

    // count of traits for each type
    // 0 - 1 are minnows, 2 - 3 are sharks, 4 - 5 are orcas
    uint8[6] public traitCounts;

    // reference to the Tower contract to allow transfers to it without approval
    ICoral public coral;
    // reference to Traits
    ITraits public traits;
    // reference to Randomizer
    IRandomizer public randomizer;

    // address => allowedToCallFunctions
    mapping(address => bool) private admins;

    constructor(uint16 _maxTokens) ERC721("Shark Game", "SHRK") {
        maxTokens = _maxTokens;
        PAID_TOKENS = _maxTokens / 6;
        _pause();

        // Minnows
        // body
        traitCounts[0] = 3;
        // accessory
        traitCounts[1] = 23;

        // Sharks
        // body
        traitCounts[2] = 3;
        // accessory
        traitCounts[3] = 23;

        // Orcas
        // body
        traitCounts[4] = 3;
        // accessory
        traitCounts[5] = 23;
    }

    /** CRITICAL TO SETUP / MODIFIERS */

    modifier requireContractsSet() {
        require(address(traits) != address(0) && address(coral) != address(0) && address(randomizer) != address(0), "Contracts not set");
        _;
    }

    modifier blockIfChangingAddress() {
        require(admins[_msgSender()] || lastWriteAddress[tx.origin].blockNum < block.number, "hmmmm what doing?");
        _;
    }

    modifier blockIfChangingToken(uint256 tokenId) {
        require(admins[_msgSender()] || lastWriteToken[tokenId].blockNum < block.number, "hmmmm what doing?");
        _;
    }

    function setContracts(address _traits, address _coral, address _rand) external onlyOwner {
        traits = ITraits(_traits);
        coral = ICoral(_coral);
        randomizer = IRandomizer(_rand);
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
        generate(minted, seed);
        if(tx.origin != recipient && recipient != address(coral)) {
            emit TokenStolen(minted, this.getTokenType(minted));
        }
        _safeMint(recipient, minted);
    }

    /**
    * Burn a token - any game logic should be handled before this function.
    */
    function burn(uint256 tokenId) external override whenNotPaused {
        require(admins[_msgSender()], "Only admins can call this");
        require(ownerOf(tokenId) == tx.origin, "Oops you don't own that");
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
    function generate(uint256 tokenId, uint256 seed) internal returns (SGToken memory t) {
        t = selectTraits(seed);
        tokenTraits[tokenId] = t;
        emit TokenMinted(tokenId, this.getTokenType(minted));
    }

    /**
    * chooses a random trait
    * @param seed portion of the 256 bit seed to remove trait correlation
    * @param traitType the trait type to select a trait for
    * @return the ID of the randomly selected trait
    */
    function selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
        return uint8(seed) % traitCounts[traitType];
    }

    /**
    * selects the species and all of its traits based on the seed value
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t -  a struct of randomly selected traits
    */
    function selectTraits(uint256 seed) internal view returns (SGToken memory t) {
        bool orcasEnabled = minted > 5000;
        uint256 typePercent = (seed & 0xFFFF) % 100;
        t.tokenType = typePercent < 90 ? ISharks.SGTokenType.MINNOW :
            typePercent < 92 && orcasEnabled ? ISharks.SGTokenType.ORCA : ISharks.SGTokenType.SHARK;
        uint8 shift = uint8(t.tokenType) * 2;
        seed >>= 16;
        t.base = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
        seed >>= 16;
        t.accessory = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
    }

    /** READ */

    /**
    * checks if a token is a Wizards
    * @param tokenId the ID of the token to check
    * @return wizard - whether or not a token is a Wizards
    */
    function getTokenType(uint256 tokenId) external view override blockIfChangingToken(tokenId) returns (ISharks.SGTokenType) {
        // Sneaky dragons will be slain if they try to peep this after mint. Nice try.
        ISharks.SGToken memory s = tokenTraits[tokenId];
        return s.tokenType;
    }

    function getMaxTokens() external view override returns (uint16) {
        return maxTokens;
    }

    function getPaidTokens() external view override returns (uint16) {
        return PAID_TOKENS;
    }

    /** ADMIN */

    /**
    * updates the number of tokens for sale
    */
    function setPaidTokens(uint16 _paidTokens) external onlyOwner {
        PAID_TOKENS = _paidTokens;
    }

    /**
    * enables owner to pause / unpause minting
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
    * @param addr the address to disable
    */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    /** Traits */

    function getTokenTraits(uint256 tokenId) external view override blockIfChangingAddress blockIfChangingToken(tokenId) returns (SGToken memory) {
        return tokenTraits[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ISharks) blockIfChangingAddress blockIfChangingToken(tokenId) returns (string memory) {
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
