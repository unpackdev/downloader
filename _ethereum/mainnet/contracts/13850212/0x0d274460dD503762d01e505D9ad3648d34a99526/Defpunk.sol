// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./console.sol";
import "./IDefpunk.sol";
import "./ITraits.sol";
import "./IRandomizer.sol";

contract Defpunk is IDefpunk, ERC721Enumerable, Ownable, Pausable {
    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }
    
    event MaleBurned(uint256 indexed tokenId);
    event FemaleBurned(uint256 indexed tokenId);
    event MaleMinted(uint256 indexed tokenId);
    event FemaleMinted(uint256 indexed tokenId);
    event WithdrawFunds(uint256 _withdraw);
    event updateMaxTokens(uint256 _maxTokens);
    event updateTreasuryWallet(address _treasury);
    event updateBaseURI(string _URI);
    event updateAdmin(address addr);
    event updateRemoveAdmin(address addr);

    // max number of males that have been minted
    uint256 public totalMaleMinted;
    // max number of females that have been minted
    uint256 public totalFemaleMinted;
    // max number of tokens that can be minted - 50000 in production
    uint256 public MAX_TOKENS;

    // list of probabilities for each trait type
    // 2 - 9 are associated with Males, 10 - 17 are associated with Females
    uint8[][20] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 2 - 9 are associated with Males, 10 - 17 are associated with Females
    uint8[][20] public aliases;
    // list aging properties
    // 2 - 9 are associated with Males, 10 - 17 are associated with Females
    uint8[][19] public canBeAged;
    // list maximum usage of properties
    // 2 - 9 are associated with Males, 10 - 17 are associated with Females
    uint16[][19] public maxUsed;
    // list usage of properties
    // 2 - 9 are associated with Males, 10 - 17 are associated with Females
    uint16[][19] public used;

    // number of tokens have been minted so far
    uint16 public override minted;
    // outcome chances when fusing
    uint8 public primaryFusePercentage = 80;
    uint8 public secondaryFusePercentage = 15;
    uint8 public agingFusePercentage = 10; 
    uint8 public agingFuseInitial = 10; 
    uint8 public agingFuseCap = 50; 

    // address -> treasury
    address public treasury;

    // string -> baseURI
    string private baseURI;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => Defpunk) public tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;
    // Tracks the last block and timestamp that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => LastWrite) private lastWriteAddress;
    mapping(uint256 => LastWrite) private lastWriteToken;
    // address => allowedToCallFunctions
    mapping(address => bool) private admins;

    // reference to Traits
    ITraits public traits;
    // reference to Randomizer
    IRandomizer public randomizer;

    /** 
    * instantiates contract and rarity tables
    */
    constructor(uint256 _maxTokens) ERC721("Defpunks", 'DP') {
        _pause();
        MAX_TOKENS = _maxTokens;
        
        // I know this looks weird but it saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm
        // Gender
        rarities[0] = [255, 255];
        aliases[0] = [0, 1];
        // Male
        // Background
        rarities[1] = [207, 223, 220, 220, 236, 233, 233, 249, 246, 245, 252, 255, 194, 210, 207];
        aliases[1] = [3, 4, 5, 6, 7, 8, 9, 10, 10, 11, 11, 11, 0, 1, 2];
        // Skin
        rarities[2] = [116, 106, 183, 189, 113, 173, 99, 253, 163, 113, 166, 255, 93];
        aliases[2] = [5, 0, 7, 7, 8, 11, 2, 11, 11, 3, 4, 11, 4];
        // Nose
        rarities[3] =  [188, 82, 239, 165, 126, 243, 255, 224];
        aliases[3] = [2, 3, 6, 6, 5, 6, 6, 6];
        // Eyes
        rarities[4] = [230, 166, 179, 255, 191, 204, 230, 191, 179, 217, 242, 230, 153, 147, 255, 230, 128, 159, 236, 140, 255, 242, 255, 255, 153];
        aliases[4] = [15, 0, 3, 3, 6, 7, 15, 15, 7, 10, 17, 12, 17, 17, 14, 18, 12, 18, 20, 13, 20, 14, 22, 23, 14];
        // Neck
        rarities[5] = [163, 167, 114, 139, 155, 159, 122, 255];
        aliases[5] = [7, 7, 7, 7, 7, 7, 7, 7];
        // Mouth
        rarities[6] = [168, 242, 246, 178, 215, 145, 233, 223, 252, 229, 126, 155, 213, 229, 243, 204, 233, 255, 203];
        aliases[6] = [14, 0, 15, 15, 16, 0, 2, 2, 3, 16, 3, 4, 9, 16, 17, 17, 17, 17, 13];
        // Ears
        rarities[7] = [153, 26, 77, 255];
        aliases[7] = [3, 3, 3, 3];
        // Hair
        rarities[8] = [184, 250, 252, 217, 145, 153, 199, 237, 237, 235, 138, 207, 214, 222, 107, 191, 130, 229, 201, 235, 135, 242, 122, 255, 92, 249, 245, 99, 160, 255];
        aliases[8] = [1, 25, 3, 25, 3, 25, 5, 5, 25, 28, 5, 8, 8, 8, 9, 18, 18, 19, 28, 28, 28, 29, 20, 29, 21, 29, 23, 23, 29, 29];
        // Mouth Accessory
        rarities[9] = [32, 64, 117, 106, 255];
        aliases[9] = [4, 4, 4, 4, 4];

        // Female
        // Background
        rarities[10] = [207, 223, 220, 220, 236, 233, 233, 249, 246, 245, 252, 255, 194, 210, 207];
        aliases[10] = [3, 4, 5, 6, 7, 8, 9, 10, 10, 11, 11, 11, 0, 1, 2];
        // Skin
        rarities[11] = [116, 106, 183, 189, 113, 173, 99, 253, 163, 113, 166, 255, 93];
        aliases[11] = [5, 0, 7, 7, 8, 11, 2, 11, 11, 3, 4, 11, 4];
        // Nose
        rarities[12] =  [188, 82, 239, 165, 126, 243, 255, 224];
        aliases[12] = [2, 3, 6, 6, 5, 6, 6, 6];
        // Eyes
        rarities[13] = [230, 166, 179, 255, 191, 204, 230, 191, 179, 217, 242, 230, 153, 147, 255, 230, 128, 159, 236, 140, 255, 242, 255, 255, 153];
        aliases[13] = [15, 0, 3, 3, 6, 7, 15, 15, 7, 10, 17, 12, 17, 17, 14, 18, 12, 18, 20, 13, 20, 14, 22, 23, 14];
        // Neck
        rarities[14] = [163, 167, 114, 139, 155, 159, 122, 255];
        aliases[14] = [7, 7, 7, 7, 7, 7, 7, 7];
        // Mouth
        rarities[15] = [168, 242, 246, 178, 215, 145, 233, 223, 252, 229, 126, 155, 213, 229, 243, 204, 233, 255, 203];
        aliases[15] = [14, 0, 15, 15, 16, 0, 2, 2, 3, 16, 3, 4, 9, 16, 17, 17, 17, 17, 13];
        // Ears
        rarities[16] = [153, 26, 77, 255];
        aliases[16] = [3, 3, 3, 3];
        // Hair
        rarities[17] = [184, 250, 252, 217, 145, 153, 199, 237, 237, 235, 138, 207, 214, 222, 107, 191, 130, 229, 201, 235, 135, 242, 122, 255, 92, 249, 245, 99, 160, 255];
        aliases[17] = [1, 25, 3, 25, 3, 25, 5, 5, 25, 28, 5, 8, 8, 8, 9, 18, 18, 19, 28, 28, 28, 29, 20, 29, 21, 29, 23, 23, 29, 29];
        // Mouth Accessory
        rarities[18] = [32, 64, 117, 106, 255];
        aliases[18] = [4, 4, 4, 4, 4];

        // Can be aged
        // Gender
        canBeAged[0] = [0, 0];
        // Male traits
        // Background
        canBeAged[1] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Skin
        canBeAged[2] = [1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0];
        // Nose
        canBeAged[3] = [0, 0, 0, 0, 0, 0, 0, 0];
        // Eyes
        canBeAged[4] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Neck
        canBeAged[5] = [0, 0, 0, 0, 0, 0, 0, 0];
        // Mouth
        canBeAged[6] = [1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0];
        // Ears
        canBeAged[7] = [0, 0, 0, 0];
        // Hair
        canBeAged[8] = [0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0];
        // Mouth Accessories
        canBeAged[9] = [0, 0, 0, 0, 0];
        // Female traits
        // Background
        canBeAged[10] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Skin
        canBeAged[11] = [1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0];
        // Nose
        canBeAged[12] = [0, 0, 0, 0, 0, 0, 0, 0];
        // Eyes
        canBeAged[13] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Neck
        canBeAged[14] = [0, 0, 0, 0, 0, 0, 0, 0];
        // Mouth
        canBeAged[15] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Ears
        canBeAged[16] = [0, 0, 0, 0];
        // Hair
        canBeAged[17] = [0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0];
        // Mouth Accessories
        canBeAged[18] = [0, 0, 0, 0, 0];
                
        // Maximums that can be used
        // Gender
        maxUsed[0] = [50000, 50000];
        // Male traits
        // Background
        maxUsed[1] = [3500,3500,3500,3500,3500,3500,3500,3500,3500,3500,3500,3500,2540,2750,2710];
        // Skin
        maxUsed[2] = [4000,1600,5100,5000,5500,4700,1500,5900,4600,1700,2500,6500,1400];
        // Nose
        maxUsed[3] = [4600,2000,7500,8300,3100,9100,9900,5500];
        // Eyes
        maxUsed[4] = [2500,1300,1400,2600,1500,1600,2300,2500,1400,1700,2200,1800,2400,2050,2900,2700,1000,3000,2800,1100,2150,1900,2000,2000,1200];
        // Neck
        maxUsed[5] = [4000,4100,2800,3400,3800,3900,3000,25000];
        // Mouth
        maxUsed[6] = [3000,2500,3100,3200,3250,1500,2400,2300,2600,2800,1300,1600,2200,2900,3400,3000,3350,3500,2100];
        // Ears
        maxUsed[7] = [7500,1250,3750,37500];
        // Hair
        maxUsed[8] = [1200,2100,1650,2150,950,2250,1300,1550,2350,2500,900,1350,1400,1450,700,1250,850,1500,2550,1700,1750,2650,800,2750,600,2700,1600,650,2450,2400];
        // Mouth Accessory
        maxUsed[9] = [1250,2500,4575,4175,37500];
        // Female traits
        // Background
        maxUsed[10] = [3500,3500,3500,3500,3500,3500,3500,3500,3500,3500,3500,3500,2540,2750,2710];
        // Skin
        maxUsed[11] = [4000,1600,5100,5000,5500,4700,1500,5900,4600,1700,2500,6500,1400];
        // Nose
        maxUsed[12] = [4600,2000,7500,8300,3100,9100,9900,5500];
        // Eyes
        maxUsed[13] = [2500,1300,1400,2600,1500,1600,2300,2500,1400,1700,2200,1800,2400,2050,2900,2700,1000,3000,2800,1100,2150,1900,2000,2000,1200];
        // Neck
        maxUsed[14] = [4000,4100,2800,3400,3800,3900,3000,25000];
        // Mouth
        maxUsed[15] = [3000,2500,3100,3200,3250,1500,2400,2300,2600,2800,1300,1600,2200,2900,3400,3000,3350,3500,2100];
        // Ears
        maxUsed[16] = [7500,1250,3750,37500];
        // Hair
        maxUsed[17] = [1200,2100,1650,2150,950,2250,1300,1550,2350,2500,900,1350,1400,1450,700,1250,850,1500,2550,1700,1750,2650,800,2750,600,2700,1600,650,2450,2400];
        // Mouth Accessory
        maxUsed[18] = [1250,2500,4575,4175,37500];
        
        // Used
        // Gender
        used[0] = [0, 0];
        // Male traits
        // Background
        used[1] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Skin
        used[2] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Nose
        used[3] = [0, 0, 0, 0, 0, 0, 0, 0];
        // Eyes
        used[4] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Neck
        used[5] = [0, 0, 0, 0, 0, 0, 0, 0];
        // Mouth
        used[6] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Ears
        used[7] = [0, 0, 0, 0];
        // Hair
        used[8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Mouth Accessories
        used[9] = [0, 0, 0, 0, 0];
        // Female traits
        // Background
        used[10] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Skin
        used[11] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Nose
        used[12] = [0, 0, 0, 0, 0, 0, 0, 0];
        // Eyes
        used[13] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Neck
        used[14] = [0, 0, 0, 0, 0, 0, 0, 0];
        // Mouth
        used[15] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Ears
        used[16] = [0, 0, 0, 0];
        // Hair
        used[17] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Mouth Accessories
        used[18] = [0, 0, 0, 0, 0];
    }

    /** CRITICAL TO SETUP / MODIFIERS */

    modifier requireContractsSet() {
        require(address(traits) != address(0) && address(randomizer) != address(0), "Contracts not set");
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

    modifier onlyOwnerOrAdmin() {
        // frens can always call whenever they want :)
        require(admins[_msgSender()] || owner() == _msgSender(), "Only admins or contract owner can call this");
        _;
    }

    function setContracts(address _traits, address _rand) external onlyOwner {
        traits = ITraits(_traits);
        randomizer = IRandomizer(_rand);
    }

    /**
    * @dev Updates the sales of the earlyAccess and the public sale
    */
    function setFusePercentages(uint8 _primaryFusePercentage, uint8 _secondaryFusePercentage, uint8 _agingFusePercentage, uint8 _agingFuseInitial, uint8 _agingFuseCap) external onlyOwner {
        primaryFusePercentage = _primaryFusePercentage;
        secondaryFusePercentage = _secondaryFusePercentage;
        agingFusePercentage = _agingFusePercentage;
        agingFuseInitial = _agingFuseInitial;
        agingFuseCap = _agingFuseCap; 
    }

    /** EXTERNAL */
    function getTokenWriteBlock(uint256 tokenId) external view override returns(uint64) {
        require(admins[_msgSender()], "Only admins can call this");
        return lastWriteToken[tokenId].blockNum;
    }

    function fuseTraits(uint256 fullseed, LastWrite memory lw, Defpunk memory fusionDefpunk, Defpunk memory burnDefpunk) internal returns (Defpunk memory t) {
		uint256 seed = fullseed;
        uint8 shift = 0;
        // for each trait, check the outcome of the fusion.
        seed >>= 16;
		t.isMale = fuseTrait(fullseed, lw, seed, 1, fusionDefpunk.isMale ? 0 : 1, fusionDefpunk.isMale ? 0 : 1)  == 0;
		shift = t.isMale ? 0 : 9;
        seed >>= 16;
        t.background = fuseTrait(fullseed, lw, seed, 1 + shift, fusionDefpunk.background, burnDefpunk.background);
        seed >>= 16;
		t.skin = fuseTrait(fullseed, lw, seed, 2 + shift, fusionDefpunk.skin, burnDefpunk.skin);
        if (canBeAged[2 + shift][t.skin] == 1 && traitHasAged(fusionDefpunk.fusionIndex, fullseed)) {
            t.aged[0] = 2 + shift;
        }
        seed >>= 16;
		t.nose = fuseTrait(fullseed, lw, seed, 3 + shift, fusionDefpunk.nose, burnDefpunk.nose);
        seed >>= 16;
		t.eyes = fuseTrait(fullseed, lw, seed, 4 + shift, fusionDefpunk.eyes, burnDefpunk.eyes);
        seed >>= 16;
		t.neck = fuseTrait(fullseed, lw, seed, 5 + shift, fusionDefpunk.neck, burnDefpunk.neck);
        seed >>= 16;
		t.mouth = fuseTrait(fullseed, lw, seed, 6 + shift, fusionDefpunk.mouth, burnDefpunk.mouth);
        if (canBeAged[6 + shift][t.mouth] == 1 && traitHasAged(fusionDefpunk.fusionIndex, fullseed)) {
            t.aged[1] = 6 + shift;
        }
        seed >>= 16;
		t.ears = fuseTrait(fullseed, lw, seed, 7 + shift, fusionDefpunk.ears, burnDefpunk.ears);
        seed >>= 16;
		t.hair = fuseTrait(fullseed, lw, seed, 8 + shift, fusionDefpunk.hair, burnDefpunk.hair);
        if (canBeAged[8 + shift][t.hair] == 1 && traitHasAged(fusionDefpunk.fusionIndex, fullseed)) {
            t.aged[2] = 8 + shift;
        }
        seed >>= 16;
		t.mouthAccessory = fuseTrait(fullseed, lw, seed, 9 + shift, fusionDefpunk.mouthAccessory, burnDefpunk.mouthAccessory);
        seed >>= 16;
        // afterwards, the fusionIndex is increased by 1
        t.fusionIndex = fusionDefpunk.fusionIndex + 1;
    }

    function fuseTrait(uint256 fullseed, LastWrite memory lw, uint256 seed, uint8 index, uint8 fusionTrait, uint8 burnTrait) internal returns (uint8 trait) {
		// Here is determined which trait will be kept after fusing. 
        // 60% chance to get the fusionTrait
        // 30% chance to get the burnTrait
        // 10% chance to get a whole new trait
        trait = 0;
		uint256 percent = seed % 100;
		if (percent < primaryFusePercentage) {
			trait = fusionTrait;
		} else if (percent < (primaryFusePercentage + secondaryFusePercentage)) {
			trait = burnTrait;
		} else {
			uint8 different = 0;
			do {
				trait = selectTrait(uint16(seed & 0xFFFF), index);
				if (trait != fusionTrait && trait != burnTrait) {
					different = 1;
				} else {
					fullseed = randomizer.random(fullseed, lw.time, lw.blockNum);
					seed = fullseed;
				}
			} while (different < 1);
		}
		return trait;
	}

    /** 
    * Mint
    */
    function mint(address recipient, uint256 seed) external override whenNotPaused onlyOwnerOrAdmin {
        require(minted + 1 <= MAX_TOKENS, "All tokens minted");
        minted++;
        generate(minted, seed, lastWriteAddress[tx.origin]);
        _safeMint(recipient, minted);
    }

    /** 
    * Burn a token
    */
    function burn(uint256 tokenId) public override whenNotPaused onlyOwnerOrAdmin {
        require(ownerOf(tokenId) == tx.origin, "Oops you don't own that");
        if(tokenTraits[tokenId].isMale) {
            emit MaleBurned(tokenId);
        }
        else {
            emit FemaleBurned(tokenId);
        }

        _burn(tokenId);
    }

    /** 
    * Fusion
    */
    function fuseTokens(uint256 fuseTokenId, uint256 burnTokenId, uint256 seed) external override onlyOwnerOrAdmin {
		Defpunk memory t = fuseTraits(seed, lastWriteAddress[tx.origin], tokenTraits[fuseTokenId], tokenTraits[burnTokenId]);
		// Store new fuseTokenId
		tokenTraits[fuseTokenId] = t;
        burn(burnTokenId);
    }

    /** 
    * Updates `lastWrite`
    */
    function updateOriginAccess(uint16[] memory tokenIds) external override onlyOwnerOrAdmin {
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
    function generate(uint256 tokenId, uint256 seed, LastWrite memory lw) internal returns (Defpunk memory t) {
		t = selectTraits(seed);
		if (existingCombinations[structToHash(t)] == 0 && exceedsMaxUsage(t) < 1) {
        	tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
			addUsed(t);
            if (t.isMale) {
                totalMaleMinted += 1;
                emit MaleMinted(tokenId);
            } else {
                totalFemaleMinted += 1;
                emit FemaleMinted(tokenId);
            }
            return t;
        }
        return generate(tokenId, randomizer.random(seed, lw.time, lw.blockNum), lw);
    }

    function traitHasAged(uint8 fusionIndex, uint256 seed) internal view returns (bool ) {
        uint16 fuseChance = agingFuseInitial + (fusionIndex * agingFusePercentage) >= agingFuseCap ? agingFuseCap : agingFuseInitial + (fusionIndex * agingFusePercentage);
        uint8 percent = uint8(seed >> 11) % 100;
        return percent < fuseChance;
    }

    function addUsed(Defpunk memory t) internal {
        // this function keeps track of which traits are used
		uint8 shift = t.isMale ? 0 : 9;
		used[0][t.isMale ? 0 : 1] = 0 + used[0][t.isMale ? 0 : 1];
        used[1 + shift][t.background] = 1 + used[1 + shift][t.background];
		used[2 + shift][t.skin] = 1 + used[2 + shift][t.skin];
		used[3 + shift][t.nose] = 1 + used[3 + shift][t.nose];
		used[4 + shift][t.eyes] = 1 + used[4 + shift][t.eyes];
		used[5 + shift][t.neck] = 1 + used[5 + shift][t.neck];
		used[6 + shift][t.mouth] = 1 + used[6 + shift][t.mouth];
		used[7 + shift][t.ears] = 1 + used[7 + shift][t.ears];
		used[8 + shift][t.hair] = 1 + used[8 + shift][t.hair];
		used[9 + shift][t.mouthAccessory] = 1 + used[9 + shift][t.mouthAccessory];
    }
    
    function exceedsMaxUsage(Defpunk memory t) internal view returns (uint8) {
        // this function return if any of the tracks exceed their max usage
		uint8 shift = t.isMale ? 0 : 9;
		if (maxUsed[0][t.isMale ? 0 : 1] < 1 + used[0][t.isMale ? 0 : 1] ||
			maxUsed[1 + shift][t.background] < 1 + used[1 + shift][t.background] ||
			maxUsed[2 + shift][t.skin] < 1 + used[2 + shift][t.skin] ||
			maxUsed[3 + shift][t.nose] < 1 + used[3 + shift][t.nose] ||
			maxUsed[4 + shift][t.eyes] < 1 + used[4 + shift][t.eyes] ||
			maxUsed[5 + shift][t.neck] < 1 + used[5 + shift][t.neck] ||
			maxUsed[6 + shift][t.mouth] < 1 + used[6 + shift][t.mouth] ||
			maxUsed[7 + shift][t.ears] < 1 + used[7 + shift][t.ears] ||
			maxUsed[8 + shift][t.hair] < 1 + used[8 + shift][t.hair] ||
			maxUsed[9 + shift][t.mouthAccessory] < 1 + used[9 + shift][t.mouthAccessory]) {
			return uint8(1);
		}
		return uint8(0);
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
    function selectTraits(uint256 seed) internal view returns (Defpunk memory t) {    
        t.isMale = (selectTrait(uint16(seed & 0xFFFF), 0) == 0);
        uint8 shift = t.isMale ? 0 : 9;
        seed >>= 16;
        t.background = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        t.skin = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        t.nose = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        seed >>= 16;
        t.eyes = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        seed >>= 16;
        t.neck = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        t.mouth = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
        seed >>= 16;
        t.ears = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
        seed >>= 16;
        t.hair = selectTrait(uint16(seed & 0xFFFF), 8 + shift);
        seed >>= 16;
        t.mouthAccessory = selectTrait(uint16(seed & 0xFFFF), 9 + shift);
        seed >>= 16;
        t.fusionIndex = 0;
    }
   
    /**
    * converts a struct to a 256 bit hash to check for uniqueness
    * @param s the struct to pack into a hash
    * @return the 256 bit hash of the struct
    */
    function structToHash(Defpunk memory s) internal pure returns (uint256) {
        return uint256(bytes32(
            abi.encodePacked(
                s.isMale,
                s.background,
                s.skin,
                s.nose,
                s.eyes,
                s.neck,
                s.mouth,
                s.ears,
                s.hair,
                s.mouthAccessory,
                s.fusionIndex,
                s.aged
            )
        ));
    }

    /**
     * @dev allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(address(treasury)).transfer(address(this).balance);

        emit WithdrawFunds(address(this).balance);
    }

    /** SETTERS */
    
    /**
    * @dev Updates the max tokens;
    */
    function setMaxTokens(uint256 _maxTokens) external onlyOwnerOrAdmin {
        MAX_TOKENS = _maxTokens;

        emit updateMaxTokens(_maxTokens);
    }

    /**
    * @dev enables owner to pause / unpause minting
    */
    function setPaused(bool _paused) external override onlyOwnerOrAdmin {
        if (_paused) _pause();
        else _unpause();
    }

    /**
    * Updates the treasury wallet
    */
    function setTreasuryWallet(address _treasury) external onlyOwnerOrAdmin {
        require(_treasury != address(0x0), 'Invalid treasury address');
        treasury = _treasury;

        emit updateTreasuryWallet(_treasury);
    }

    /**
    * @dev Sets the new base URI
    */
    function setBaseURI(string memory _URI) override external onlyOwnerOrAdmin {
        baseURI = _URI;

        emit updateBaseURI(_URI);
    }

    /**
    * enables an address to mint / burn
    * @param addr the address to enable
    */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;

        emit updateAdmin(addr);
    }

    /**
    * disables an address from minting / burning
    * @param addr the address to disbale
    */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;

        emit updateRemoveAdmin(addr);
    }

    /** READ */

    /**
    * checks if a token is a Male
    * @param tokenId the ID of the token to check
    * @return isMale - whether or not a token is a Male
    */
    function isMale(uint256 tokenId) external view override blockIfChangingToken(tokenId) returns (bool) {
        // Sneaky ppl will be slain if they try to peep this after mint. Nice try.
        IDefpunk.Defpunk memory s = tokenTraits[tokenId];
        return s.isMale;
    }
    
    function getMaxTokens() external view override returns (uint256) {
        return MAX_TOKENS;
    }

    function getBaseURI() external view override returns (string memory) {
        return baseURI;
    }

    function getTokenTraits(uint256 tokenId) external view override returns (Defpunk memory) {
        return tokenTraits[tokenId];
    }

   /** OVERRIDES FOR SAFETY */
    function _baseURI() internal view override virtual returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return traits.tokenURI(tokenId);
    }

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
