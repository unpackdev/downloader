// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./IWildAbduction.sol";
import "./IBank.sol";
import "./ITraits.sol";
import "./ILAND.sol";


contract WildAbduction is IWildAbduction, ERC721Enumerable, Ownable, Pausable {

    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

    event CowboyMinted(uint256 indexed tokenId);
    event MutantMinted(uint256 indexed tokenId);
    event AlienMinted(uint256 indexed tokenId);
    event CowboyStolen(uint256 indexed tokenId);
    event CowboyBurned(uint256 indexed tokenId);
    event AlienBurned(uint256 indexed tokenId);


    // max number of tokens that can be minted: 40000 in production
    uint256 public maxTokens;
    // max number of mutants that can be minted as gen 0: 55 in production
    uint256 public MUTANT_COUNT;
    // number of tokens that can be claimed for a fee: 4444
    uint256 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public override minted;


    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => CowboyAlien) public tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    // reference to bank
    IBank public bank;
    // reference to Traits
    ITraits public traits;
    
    // address => allowedToCallFunctions
    mapping(address => bool) private admins;

    constructor() ERC721("WAG Game", 'WGAME') {
        maxTokens = 40000;
        admins[msg.sender] = true;
        PAID_TOKENS = 4444;
        _pause();
    }

    function setContracts(address _bank, address _traits) external onlyOwner {
        bank = IBank(_bank);
        traits = ITraits(_traits);
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
        if(tx.origin != recipient && recipient != address(bank)) {
            emit CowboyStolen(minted);
        }
        _safeMint(recipient, minted);
    }

    /** 
    * Burn a token - any game logic should be handled before this function.
    */
    function burn(uint256 tokenId) external override whenNotPaused {
        require(admins[_msgSender()], "Only admins can call this");
        require(ownerOf(tokenId) == tx.origin, "Oops you don't own that");
        if(tokenTraits[tokenId].isCowboy) {
            emit CowboyBurned(tokenId);
        }
        else {
            emit AlienBurned(tokenId);
        }
        _burn(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) {
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
    function generate(uint256 tokenId, uint256 seed) internal returns (CowboyAlien memory t) {
        t = selectTraits(seed);

        // only 55 mutants
        if (t.isMutant && MUTANT_COUNT == 55 && minted <= PAID_TOKENS) {
            return generate(tokenId, random(seed));
        }
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
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
    function selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
        return traits.selectTrait(seed, traitType);
    }

    

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t -  a struct of randomly selected traits
   */
    function selectTraits(uint256 seed) internal view returns (CowboyAlien memory t) {

        t.isMutant = (seed & 0xFFFF) % 3 == 0 && (seed & 0xFFFF) % 7 == 0;

        if (t.isMutant) {
            t.isCowboy = true;
        } else {
            // not exactly 88.75%
            t.isCowboy = (seed & 0xFFFF) % 10 != 0;
        }

        seed >>= 16;
        t.pants = selectTrait(uint16(seed & 0xFFFF), 0 );

        seed >>= 16;
        t.top = selectTrait(uint16(seed & 0xFFFF), 1 );

        seed >>= 16;
        t.hat = selectTrait(uint16(seed & 0xFFFF), 2 );

        seed >>= 16;
        t.weapon = selectTrait(uint16(seed & 0xFFFF), 3);

        seed >>= 16;
        t.accessory = selectTrait(uint16(seed & 0xFFFF), 4);

        seed >>= 16;
        if (!t.isCowboy) {
            t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), 5);
        }
    }

    /**
    * converts a struct to a 256 bit hash to check for uniqueness
    * @param s the struct to pack into a hash
    * @return the 256 bit hash of the struct
    */
    function structToHash(CowboyAlien memory s) internal pure returns (uint256) {
        return uint256(keccak256(
                abi.encodePacked(
                    s.isCowboy,
                    s.isMutant,
                    s.pants,
                    s.top,
                    s.hat,
                    s.weapon,
                    s.accessory,
                    s.alphaIndex
                )
            ));
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


    /***READ */

    function getTokenTraits(uint256 tokenId) external view override returns (CowboyAlien memory) {
        return tokenTraits[tokenId];
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
    * enables owner to pause / unpause minting
    */
    function setPaused(bool _paused) external onlyOwner {
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

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        return traits.tokenURI(tokenId);
    }

}