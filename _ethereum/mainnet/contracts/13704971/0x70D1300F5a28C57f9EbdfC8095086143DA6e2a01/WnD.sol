// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./IWnD.sol";
import "./ITower.sol";
import "./ITraits.sol";
import "./IGP.sol";

contract WnD is IWnD, ERC721Enumerable, Ownable, Pausable {

    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

    // max number of tokens that can be minted: 60000 in production
    uint256 public maxTokens;
    // number of tokens that can be claimed for a fee: 15,000
    uint256 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public override minted;
    uint16 private numWizards;
    uint16 private numDragons;
    uint16 private numWizardsStolen;
    uint16 private numDragonsStolen;
    uint16 private numWizardsBurned;
    uint16 private numDragonsBurned;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => WizardDragon) public override tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;
    // Tracks the last block and timestamp that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => LastWrite) private lastWrite;

    // list of probabilities for each trait type
    // 0 - 9 are associated with Wizard, 10 - 18 are associated with Dragons
    uint8[][18] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 9 are associated with Wizard, 10 - 18 are associated with Dragons
    uint8[][18] public aliases;

    // reference to the Tower contract to allow transfers to it without approval
    ITower public tower;
    // reference to Traits
    ITraits public traits;

    // address => allowedToCallFunctions
    mapping(address => bool) private admins;

    constructor(uint256 _maxTokens) ERC721("Wizards & Dragons Game", "WnD") {
        maxTokens = _maxTokens;
        PAID_TOKENS = _maxTokens / 4;
        _pause();

        // A.J. Walker's Alias Algorithm
        // Wizards
        // body
        rarities[0] = [80, 150, 200, 250, 255];
        aliases[0] = [4, 4, 4, 4, 4];
        // head
        rarities[1] = [150, 40, 240, 90, 115, 135, 40, 199, 100];
        aliases[1] = [3, 7, 4, 0, 5, 6, 8, 5, 0];
        // spell
        rarities[2] =  [255, 135, 60, 130, 190, 156, 250, 120, 60, 25, 190];
        aliases[2] = [0, 0, 0, 6, 6, 0, 0, 0, 6, 8, 0];
        // eyes
        rarities[3] = [221, 100, 181, 140, 224, 147, 84, 228, 140, 224, 250, 160, 241, 207, 173, 84, 254];
        aliases[3] = [1, 2, 5, 0, 1, 7, 1, 10, 5, 10, 11, 12, 13, 14, 16, 11, 0];
        // neck
        rarities[4] = [175, 100, 40, 250, 115, 100, 80, 110, 180, 255, 210, 180];
        aliases[4] = [3, 0, 4, 1, 11, 7, 8, 10, 9, 9, 8, 8];
        // mouth
        rarities[5] = [80, 225, 220, 35, 100, 240, 70, 160, 175, 217, 175, 60];
        aliases[5] = [1, 2, 5, 8, 2, 8, 8, 9, 9, 10, 7, 10];
        // neck
        rarities[6] = [255];
        aliases[6] = [0];
        // wand
        rarities[7] = [243, 189, 50, 30, 55, 180, 80, 90, 155, 30, 222, 255];
        aliases[7] = [1, 7, 5, 2, 11, 11, 0, 10, 0, 0, 11, 3];
        // rankIndex
        rarities[8] = [255];
        aliases[8] = [0];

        // Dragons
        // body
        rarities[9] = [100, 80, 177, 199, 255, 40, 211, 177, 25, 230, 90, 130, 199, 230];
        aliases[9] = [4, 3, 3, 4, 4, 13, 9, 1, 2, 5, 13, 0, 6, 12];
        // head
        rarities[10] = [255];
        aliases[10] = [0];
        // spell
        rarities[11] = [255];
        aliases[11] = [0];
        // eyes
        rarities[12] = [90, 40, 219, 80, 183, 225, 40, 120, 60, 220];
        aliases[12] = [1, 8, 3, 2, 5, 6, 5, 9, 4, 3];
        // nose
        rarities[13] = [255];
        aliases[13] = [0];
        // mouth
        rarities[14] = [239, 244, 255, 234, 234, 234, 234, 234, 234, 234, 234, 234, 234, 234];
        aliases[14] = [1, 2, 2, 0, 2, 2, 9, 0, 5, 4, 4, 4, 4, 4];
        // tails
        rarities[15] = [80, 200, 144, 145, 80, 140, 120];
        aliases[15] = [1, 6, 0, 0, 3, 0, 3];
        // wand 
        rarities[16] = [255];
        aliases[16] = [0];
        // rankIndex
        rarities[17] = [14, 155, 80, 255]; 
        aliases[17] = [2, 3, 3, 3];
    }

    /** CRITICAL TO SETUP / MODIFIERS */

    modifier requireContractsSet() {
        require(address(traits) != address(0) && address(tower) != address(0), "Contracts not set");
        _;
    }

    modifier disallowIfStateIsChanging() {
        // frens can always call whenever they want :)
        require(admins[_msgSender()] || lastWrite[tx.origin].blockNum < block.number, "hmmmm what doing?");
        _;
    }

    function setContracts(address _traits, address _tower) external onlyOwner {
        traits = ITraits(_traits);
        tower = ITower(_tower);
    }

    /** EXTERNAL */

    function getNumWizards() external view disallowIfStateIsChanging returns (uint16) {
        return numWizards;
    }
    function getNumWizardsStolen() external view disallowIfStateIsChanging returns (uint16) {
        return numWizardsStolen;
    }
    function getNumDragons() external view disallowIfStateIsChanging returns (uint16) {
        return numDragons;
    }
    function getNumDragonsStolen() external view disallowIfStateIsChanging returns (uint16) {
        return numDragonsStolen;
    }
    function getNumWizardsBurned() external view disallowIfStateIsChanging returns (uint16) {
        return numWizardsBurned;
    }
    function getNumDragonsBurned() external view disallowIfStateIsChanging returns (uint16) {
        return numDragonsBurned;
    }

    /** 
    * Mint a token - any payment / game logic should be handled in the game contract. 
    * This will just generate random traits and mint a token to a designated address.
    */
    function mint(address recipient, uint256 seed) external override whenNotPaused {
        require(admins[_msgSender()], "Only admins can call this");
        require(minted + 1 <= maxTokens, "All tokens minted");
        minted++;
        generate(minted, seed, lastWrite[tx.origin]);
        if(tx.origin != recipient && recipient != address(tower)) {
            // Stolen!
            if(tokenTraits[minted].isWizard) {
                numWizardsStolen += 1;
            }
            else {
                numDragonsStolen += 1;
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
        if(tokenTraits[minted].isWizard) {
            numWizardsBurned += 1;
        }
        else {
            numDragonsBurned += 1;
        }
        _burn(tokenId);
    }

    function updateOriginAccess() external override {
        require(admins[_msgSender()], "Only admins can call this");
        lastWrite[tx.origin].blockNum = uint64(block.number);
        lastWrite[tx.origin].time = uint64(block.number);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
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
    function generate(uint256 tokenId, uint256 seed, LastWrite memory lw) internal returns (WizardDragon memory t) {
        t = selectTraits(seed);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            if(t.isWizard) {
                numWizards += 1;
            }
            else {
                numDragons += 1;
            }
            return t;
        }
        return generate(tokenId, random(seed, lw.time, lw.blockNum), lw);
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
    function selectTraits(uint256 seed) internal view returns (WizardDragon memory t) {    
        t.isWizard = (seed & 0xFFFF) % 10 != 0;
        uint8 shift = t.isWizard ? 0 : 9;
        seed >>= 16;
        t.body = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
        seed >>= 16;
        t.head = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        t.spell = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        t.eyes = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        seed >>= 16;
        t.neck = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        seed >>= 16;
        t.mouth = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        t.tail = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
        seed >>= 16;
        t.wand = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
        seed >>= 16;
        t.rankIndex = selectTrait(uint16(seed & 0xFFFF), 8 + shift);
    }

    /**
    * converts a struct to a 256 bit hash to check for uniqueness
    * @param s the struct to pack into a hash
    * @return the 256 bit hash of the struct
    */
    function structToHash(WizardDragon memory s) internal pure returns (uint256) {
        return uint256(keccak256(
            abi.encodePacked(
                s.isWizard,
                s.body,
                s.head,
                s.spell,
                s.eyes,
                s.neck,
                s.mouth,
                s.tail,
                s.wand,
                s.rankIndex
            )
        ));
    }

    /**
    * generates a pseudorandom number for picking traits. Uses point in time randomization to prevent abuse.
    */
    function random(uint256 seed, uint64 timestamp, uint64 blockNumber) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(blockNumber > 1 ? blockNumber - 2 : blockNumber),// Different block than WnDGame to ensure if needing to re-randomize that it goes down a different path
            timestamp,
            seed
        )));
    }

    /** READ */

    function getMaxTokens() external view override returns (uint256) {
        return maxTokens;
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
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
        PAID_TOKENS = uint16(_paidTokens);
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
    * @param addr the address to disbale
    */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    /** Traits */

    function getTokenTraits(uint256 tokenId) external view override disallowIfStateIsChanging returns (WizardDragon memory) {
        return tokenTraits[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override disallowIfStateIsChanging returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        return traits.tokenURI(tokenId);
    }

    /** OVERRIDES FOR SAFETY */

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override(ERC721Enumerable, IERC721Enumerable) disallowIfStateIsChanging returns (uint256) {
        // Y U checking on this address in the same block it's being modified... hmmmm
        require(admins[_msgSender()] || lastWrite[owner].blockNum < block.number, "hmmmm what doing?");
        return super.tokenOfOwnerByIndex(owner, index);
    }
    
    function balanceOf(address owner) public view virtual override(ERC721, IERC721) disallowIfStateIsChanging returns (uint256) {
        // Y U checking on this address in the same block it's being modified... hmmmm
        require(admins[_msgSender()] || lastWrite[owner].blockNum < block.number, "hmmmm what doing?");
        return super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view virtual override(ERC721, IERC721) disallowIfStateIsChanging returns (address) {
        address addr = super.ownerOf(tokenId);
        // Y U checking on this address in the same block it's being modified... hmmmm
        require(admins[_msgSender()] || lastWrite[addr].blockNum < block.number, "hmmmm what doing?");
        return addr;
    }

}