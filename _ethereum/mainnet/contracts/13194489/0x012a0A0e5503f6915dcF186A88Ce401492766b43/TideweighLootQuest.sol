// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC2981.sol";
import "./Base64.sol";
import "./LootInterface.sol";
import "./OwnableWithoutRenounce.sol";
import "./StringsSpecialHex.sol";

/* Functionality used to whitelist OpenSea trading address */

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title Quest for Loot (for Adventurers)
 *
 * An art project (some might be tempted to call it a game) based on https://www.lootproject.com/
 */
contract TideweighLootQuest is ERC721Enumerable, OwnableWithoutRenounce, ReentrancyGuard, Pausable, IERC2981 {

    // The quest has been started by the owner
    event QuestStarted(address indexed by, uint256 indexed questTokenId);

    // Someone contributed to the solution of a quest (this may or may not have solved the quest)
    event QuestContributed(address indexed contributor, uint256 indexed questTokenId, uint256 lootTokenId, uint256 lootIdx); 

    // The quest is solved, i.e., all the Loot required by the quest has been provided
    event QuestSolved(uint256 indexed questTokenId);

    // A reward has been offered for the next person who contributes to the quest's progress
    event RewardOffered(address indexed by, uint256 indexed questTokenId, uint256 amount);

    // The reward giver has changed his mind and cancelled the reward
    event RewardCancelled(address indexed by, uint256 indexed questTokenId);

    // Someone has contributed to the quest's progress and gets the reward, if one is being offered
    event RewardClaimed(address indexed by, uint256 indexed questTokenId, uint256 amount);

    LootInterface public lootContract;

    string[] private locomotion = [
        "Fly",
        "Walk",
        "Crawl",
        "Run",
        "Teleport",
        "Head"
    ];

    string[] private interlocutorPrefix = [
        "Old ",
        "Ancient ",
        "Wise ",
        "Mean ",
        "Angry ",
        "Big ",
        "Grumpy ",
        "Spindly ",
        "Mighty "
    ];

    string[] private interlocutorName = [
        // order of the names matters, to get the applicable "standard" possessive pronoun
        "Nardok", // 0
        "Argul",
        "Hagalbar",
        "Igor",
        "Henndar",
        "Rorik",
        "Yagul",
        "Engar",
        "Freya", // 8
        "Nyssa",
        "Galadrya",
        "Renalee",
        "Vixen",
        "Everen",
        "Ciradyl",
        "Faelyn",
        "Skytaker", //16 
        "Skeltor",
        "Arachnon",
        "Gorgo",
        "Hydratis",
        "Cerberis",
        "Typhox",
        "Fenryr"
    ];

    string[] private interlocutorPossessive = [
        "His ",
        "Her ",
        "Its "
    ];

    string[] private locationPrefix = [
        "Barren ",
        "Bleak ",
        "Desolate ",
        "Tenebrous ",
        "Mournful ",
        "Gray ",
        "Dark ",
        "Unknowable "
    ];    

    string[] private locationName = [
        "Sea ",
        "City ",
        "Mountain ",
        "Cave ",
        "Swamp ",
        "Desert ",
        "Abode ",
        "Pass ",
        "Forest "
    ];

    string[] private locationSuffix = [
        "of Doom",
        "of Passing",
        "of Death",
        "of Demise",
        "of Fate",
        "of Passage",
        "of Fears"
    ];

    string[] private lostEntityPrefix = [
        "mystical ",
        "ancient ",
        "enigmatic ",
        "transcendental ",
        "unfathomable ",
        "" // intentionally left blank
    ];

    string[] private lostEntityClass = [
        "brother",
        "sister",
        "living sword",
        "dragon",
        "pet",
        "sentient staff",
        "animate artefact"
    ];

    string[] private lostAction = [
        " disappeared",
        " vanished",
        " faded",
        " gone missing",
        " dematerialized",
        " withered"
    ];

    string[] private gratitudePrefix = [
        "eternal ",
        "unbounded ",
        "infinite ",
        "endless ",
        "immeasurable "
    ];

    string[] private gratitudeType = [
        "thanks!",
        "gratitude!",
        "appreciation!",
        "respect!",
        "affection!",
        "trust!"
    ];

    address public proxyRegistryAddress; // OpenSea trading proxy. Zero indicates that OpenSea whitelisting is disabled

    mapping(uint256 => uint256) public usedUpLoot; // Tracks the Loot that has been used up to solve Quests

    mapping(uint256 => uint256) public requiredLootResolutionStatus; // Tracks how much of the required Loot has been provided

    mapping(uint256 => uint256) public questToRewardAmountMap; // Tracks how much reward is on offer for a quest's resolution

    mapping(uint256 => address) public questToRewardSourceMap; // Tracks who offered the reward for a quest's resolution

    uint256 public artistShare = 0; // ETH owed to the artist

    // order matters from here on, to pack the fields

    uint16 royalty = 10;    // Royalty expected by the artist on secondary transfers (IERC2981)

    uint16 public tokensLeftForSale = 1000; // Maximum number of tokens that can be acquired without owning Loot

    uint16 public tokensLeftForPromotion = 100; // Maximum number of tokens that can be handed out by the owner for promotional purposes

    uint64 public minimumReward = 0.01 ether;
    uint64 public maximumReward = 1 ether;
    uint64 public minimumMintPrice = 0.5 ether;

    constructor(string memory name, string memory symbol, uint256 initialTokensForOwner, address _proxyRegistryAddress, address _lootContract) ERC721(name, symbol) {

        proxyRegistryAddress = _proxyRegistryAddress;
        lootContract = LootInterface(_lootContract);

        for(uint256 cnt = 0; cnt < initialTokensForOwner; cnt++) {
            _safeMint(_msgSender(), totalSupply()+1);
        }

    }

    //
    // ERC165 interface implementation
    //

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId)
            || interfaceId == type(IERC2981).interfaceId
            || interfaceId == 0x7f5828d0; // Ownable
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading - if we have a valid proxy registry address on file
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    // 
    // ERC721 functions
    //

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mintQuest(address recipient) internal nonReentrant {
        require(totalSupply() < 10000 , "All quests have been set");
        require(balanceOf(recipient) < 3, "Can hold max 3 quests at once");
        _safeMint(recipient, totalSupply()+1);

    }

    /**
     * @dev Claim Quest for free if you're a holder of Loot
     *
     */
    function claimQuestAsLootHolder() public {
        require(lootContract.balanceOf(_msgSender()) > 0, "Must hold Loot (for Adventurers) to claim for free");
        mintQuest(_msgSender());
    }

    /**
     * @dev Pay for a Quest for free if you want a token but don't hold any Loot
     *
     */
    function mint() public payable {
        require(tokensLeftForSale > 0, "No more tokens for sale");
        require(msg.value >= minimumMintPrice, "Insufficient ether provided");
        artistShare += msg.value;
        tokensLeftForSale -= 1;
        mintQuest(_msgSender());
    }
    
    /**
     * @dev Some quests are available for promotional purposes
     *
     */
    function mintPromotion(address recipient) public onlyOwner {
        require(recipient != address(0), "ERC721: mint to the zero address");
        require(tokensLeftForPromotion > 0, "No more tokens for promotion");
        tokensLeftForPromotion -= 1;
        mintQuest(recipient);
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function lcgRandom(uint256 xk) internal pure returns (uint256 xkplusone) {
        return (16807 * (xk % 2147483647)) % 2147483647;
    }
    
    function pluckIndex(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (uint256 index) {
        return  random(string(abi.encodePacked(keyPrefix, Strings.toString(tokenId)))) % sourceArray.length;
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        return sourceArray[pluckIndex(tokenId, keyPrefix, sourceArray)];
    }

    function getLocomotion(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Locomotion", locomotion);
    }

    function getInterlocutorPrefix(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "InterlocutorPrefix", interlocutorPrefix);
    }

    function getInterlocutorName(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "InterlocutorName", interlocutorName);
    }

    function getInterlocutorPossessive(uint256 tokenId) public view returns (string memory) {
        return interlocutorPossessive[pluckIndex(tokenId, "InterlocutorName", interlocutorName) / 8]; // the use of interlocutorName here is correct
    }

    function getLocationPrefix(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "LocationPrefix", locationPrefix);
    }

    function getLocationName(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "LocationName", locationName);
    }

    function getLocationSuffix(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "LocationSuffix", locationSuffix);
    }

    function getLostEntityPrefix(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LostEntityPrefix", lostEntityPrefix);
    }

    function getLostEntityClass(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LostEntityClass", lostEntityClass);
    }

    function getLostAction(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LostAction", lostAction);
    }

    function getGratitudePrefix(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "GratitudePrefix", gratitudePrefix);
    }

    function getGratitudeType(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "GratitudeType", gratitudeType);
    }

    function getInterlocutor(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(getInterlocutorPrefix(tokenId), getInterlocutorName(tokenId)));
    }

    function getLocation(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(getLocationPrefix(tokenId), getLocationName(tokenId), getLocationSuffix(tokenId)));
    }

    function getLostEntity(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(getLostEntityPrefix(tokenId), getLostEntityClass(tokenId)));
    }

    function getDifficulty(uint256 tokenId) public pure returns (uint256 difficulty) {
        uint256 r = random(string(abi.encodePacked("Difficulty", Strings.toString(tokenId)))) % 100;
        if(     r <  5) return 1;
        else if(r < 20) return 2;
        else if(r < 45) return 3;
        else if(r < 70) return 4;
        else if(r < 85) return 5;
        else if(r < 95) return 6;
        else if(r < 99) return 7;
        else            return 8;
    }

    /**
     * @dev Returns mask of requires loot indices
     *
     * lootIdxMask defined analogously to lootIdx as for solveQuest, where the value of each activated bit = (1 << lootIdx)
     */
    function getRequiredLootIdxMask(uint256 tokenId) public pure returns (uint256 lootIdxMask) {
        uint256 difficulty = getDifficulty(tokenId);
        uint256 chosen = 0;
        lootIdxMask = 0;
        uint256 randTmp = random(string(abi.encodePacked("Loots", Strings.toString(tokenId))));
        while(chosen < difficulty) { // need to iterate in a random fashion
            randTmp = lcgRandom(randTmp);
            uint256 newlyChosenPosition = uint256(randTmp) % 8;
            if(lootIdxMask & (1 << newlyChosenPosition) == 0) {
                // Loot was not chosen previously, do so now
                lootIdxMask |= (1 << newlyChosenPosition);
                chosen += 1;
            }
        }
    }

    /**
     * @dev Enumeration of loot indices
     *
     * lootIdx defined identically as for solveQuest
     *
     * position must be in [0, difficulty)
     */
    function getRequiredLootIdx(uint256 tokenId, uint256 position) public pure returns (uint256 lootIdx) {
        uint lootIdxMask = getRequiredLootIdxMask(tokenId);
        uint256 cnt = 0;
        for(uint i = 0; i < 8; i++) {
            if(lootIdxMask & (1 << i) != 0) {
                if(cnt == position) return i;
                cnt++;
            }
        }
        revert("Must stay below difficulty"); // If we arrive here, the caller requested an impossible position at the given difficulty level
    }

    /**
     * @dev Multiplicity of each lootIdx
     *
     * lootIdx defined identically as for solveQuest
     */
    function getRequiredLootIdxMultiplicity(uint256 tokenId, uint256 requiredLootIdx) public pure returns (uint256 multiplicity) {
        if(getRequiredLootIdxMask(tokenId) & (1 << requiredLootIdx) == 0) return 0;
        uint256 r = random(string(abi.encodePacked("Multiplicity", Strings.toString(tokenId + 27644437 * requiredLootIdx)))) % 100;
        if(     r < 60) return 1;
        else if(r < 90) return 2;
        else            return 3;
    }

    function lookupLootName(uint256 lootTokenId, uint256 lootIdx) internal view returns (string memory) {
        string memory loot;
        if(     lootIdx == 0) loot = lootContract.getWeapon(lootTokenId);
        else if(lootIdx == 1) loot = lootContract.getChest(lootTokenId);
        else if(lootIdx == 2) loot = lootContract.getHead(lootTokenId);
        else if(lootIdx == 3) loot = lootContract.getWaist(lootTokenId);
        else if(lootIdx == 4) loot = lootContract.getFoot(lootTokenId);
        else if(lootIdx == 5) loot = lootContract.getHand(lootTokenId);
        else if(lootIdx == 6) loot = lootContract.getNeck(lootTokenId);
        else if(lootIdx == 7) loot = lootContract.getRing(lootTokenId);
        return loot;
    }

    /**
     * @dev Required Loot
     *
     * lootIdx defined identically as for solveQuest
     * variantIdx must stay below lootIdxMultiplicity for chosen lootIdx
     */
    function getRequiredLoot(uint256 questTokenId, uint256 requiredLootIdx, uint256 variantIdx) public view returns (string memory) {
        require(variantIdx < getRequiredLootIdxMultiplicity(questTokenId, requiredLootIdx), "Loot must be required");
        bytes32[3] memory requiredLoot;
        uint256 variantsFounds = 0;
        uint256 samplingLootPrng = random(string(abi.encodePacked("SamplingLoot", Strings.toString(questTokenId + 27644437 * requiredLootIdx))));
        do {
            uint256 samplingLootTokenId = 1 + (samplingLootPrng % 7777);
            string memory candidateLoot = lookupLootName(samplingLootTokenId, requiredLootIdx);
            bool alreadyKnown = false;
            for(uint256 lookback = 0; lookback < requiredLoot.length; lookback++) {
                if(keccak256(abi.encodePacked(candidateLoot)) == requiredLoot[lookback]) {
                    alreadyKnown = true;
                }
            }
            if(!alreadyKnown) {
                requiredLoot[variantsFounds] = keccak256(abi.encodePacked(candidateLoot));
                variantsFounds += 1;
                if(variantIdx < variantsFounds) return candidateLoot;
            }
            samplingLootPrng = lcgRandom(samplingLootPrng);
        } while(true);
        return ""; // this can actually never happen...
    }

    function buildAttributes(uint256 tokenId, bool questSolved) internal pure returns (string memory) {
        string memory questStatus;
        if(questSolved) {
            questStatus = "Solved";
        } else {
            questStatus = "Open";
        }
        return string(abi.encodePacked('"attributes": [{ "trait_type": "Quest", "value": "', questStatus, '" }, { "trait_type": "Difficulty", "value": ', Strings.toString(getDifficulty(tokenId)),' }],'));
    }

    function buildRequiredLootList(uint256 tokenId) internal view returns (string memory result, uint256 nextLineY) {
        string[64] memory parts;
        uint256 partCounter = 0;
        nextLineY = 120;
        uint256 difficulty = getDifficulty(tokenId);
        for(uint256 loot = 0; loot < difficulty; loot++) {
            parts[partCounter++] = string(abi.encodePacked('</text><text x="10" y="', Strings.toString(nextLineY) ,'" class="base">'));
            uint256 requiredLootIdx = getRequiredLootIdx(tokenId, loot);
            uint256 variants = getRequiredLootIdxMultiplicity(tokenId, requiredLootIdx);
            for(uint256 variantIdx = 0; variantIdx < variants; variantIdx++) {
                parts[partCounter++] = getRequiredLoot(tokenId, requiredLootIdx, variantIdx);
                if(variantIdx + 1 < variants) {
                    if(variantIdx == 1) {
                        nextLineY += 20;
                        parts[partCounter++] = string(abi.encodePacked(',</text><text x="10" y="', Strings.toString(nextLineY) ,'" class="base">or '));
                    } else {
                        parts[partCounter++] = ', or ';
                    }
                }
            }
            nextLineY += 20;
        }
        for(uint256 assemblyPart = 0; assemblyPart < partCounter; assemblyPart++) {
            result = string(abi.encodePacked(result, parts[assemblyPart]));
        }
    }
    function buildGraphics(uint256 tokenId) internal pure returns (string memory) {
        string[6] memory parts;
        parts[ 0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500"><style>.base{fill:black;font-family:serif;font-size:14px;} .bold{font-weight:bold;}';
        for(uint256 i = 1; i <= 4; i++) {
            parts[i] = string(abi.encodePacked(' .st', Strings.toString(i),'{fill:#',StringsSpecialHex.toHexStringWithoutPrefixWithoutLengthCheck(uint24(random(Strings.toString(tokenId*7841+i))), 3),';stroke-miterlimit:10;}'));
        }
        parts[ 5] = '</style><rect width="100%" height="100%" fill="lightgray" /><path class="st1" d="M343.7,364.7c0,0,0,33.5,0,49c0,13.6,49.1,38.4,49.1,38.4v-87.4H343.7z"/><rect x="343.7" y="309.7" class="st2" width="49.1" height="55"/><path class="st3" d="M441.8,364.7c0,0,0,33.5,0,49c0,13.6-49.1,38.4-49.1,38.4v-87.4H441.8z"/><rect x="392.8" y="309.7" class="st4" width="49.1" height="55"/><text x="10" y="20" class="base">';
        return string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        bool questSolved = isQuestSolved(tokenId);
        
        string[3] memory questNameParts;
        questNameParts[ 0] = getInterlocutor(tokenId);
        questNameParts[ 1] = ' in the ';
        questNameParts[ 2] = getLocation(tokenId);
        string memory questName = string(abi.encodePacked(questNameParts[0], questNameParts[1], questNameParts[2]));

        (string memory lootList, uint256 nextLineY) = buildRequiredLootList(tokenId);
        string[20] memory parts;
        parts[ 0] = buildGraphics(tokenId);
        parts[ 1] = getLocomotion(tokenId);
        parts[ 2] = ' to ';
        // insert questName here
        parts[ 3] = '. </text><text x="10" y="40" class="base">';
        parts[ 4] = getInterlocutorPossessive(tokenId);
        parts[ 5] = getLostEntity(tokenId);
        parts[ 6] = ' has ';
        parts[ 7] = getLostAction(tokenId);
        parts[ 8] = '. </text><text x="10" y="60" class="base">';
        parts[ 9] = 'To help the ';
        parts[10] = getLostEntityClass(tokenId);
        parts[11] = ', use all of the items on the list below. </text><text x="10" y="80" class="base">You\'ll be rewarded with ';
        parts[12] = getGratitudePrefix(tokenId);
        parts[13] = getGratitudeType(tokenId);
        parts[14] = lootList;
        if(questSolved) {
            parts[18] = string(abi.encodePacked('</text><text x="10" y="', Strings.toString(nextLineY + 20),'" class="base bold">Quest successfully solved!'));
        }
        parts[19] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], questName, parts[3], parts[4], parts[5], parts[6], parts[7]));
        output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));
        output = string(abi.encodePacked(output, parts[15], parts[16], parts[17], parts[18], parts[19]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Quest #', 
            Strings.toString(tokenId), 
            ' - ',
            questName,
            '", ', 
            buildAttributes(tokenId, questSolved),
            ' "description": "Each Quest is randomly generated on chain. Solve it by using the appropriate Loot (for Adventurers), or reward others to do so.", "image": "data:image/svg+xml;base64,', 
            Base64.encode(bytes(output)), 
            '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    /**
     * @dev Solve a quest, or contribute to the quest's solution
     *
     * lootIdx:
     *   0 = weapon
     *   1 = chest
     *   2 = head
     *   3 = waist
     *   4 = foot
     *   5 = hand
     *   6 = neck
     *   7 = ring
     */
    function solveQuest(uint256 questTokenId, uint256 lootIdx, uint256 variantIdx, uint256 providedLootTokenId) external whenNotPaused {
        require(_msgSender() == lootContract.ownerOf(providedLootTokenId), "Can only apply own(ed) Loot");
        getRequiredLootIdxMask(questTokenId) & (1 << lootIdx);
        require(requiredLootResolutionStatus[questTokenId / 32] & ((1 << lootIdx) << (8 * (questTokenId % 32))) == 0, "Loot must still be missing");
        require(usedUpLoot[providedLootTokenId / 32] & ((1 << lootIdx) << (8 * (providedLootTokenId % 32))) == 0, "Provided Loot was used before");

        if(((requiredLootResolutionStatus[questTokenId / 32] >> (8 * (questTokenId % 32)))) & 0xff == 0) {
            require(_msgSender() == ownerOf(questTokenId), "Only owner can begin quest");
            emit QuestStarted(_msgSender(), questTokenId);
        }
        
        string memory providedLoot = lookupLootName(providedLootTokenId, lootIdx);
        string memory requiredLoot = getRequiredLoot(questTokenId, lootIdx, variantIdx);
        require(keccak256(abi.encodePacked(providedLoot)) == keccak256(abi.encodePacked(requiredLoot)), "Matching loot must be provided");

        requiredLootResolutionStatus[questTokenId / 32] |= ((1 << lootIdx) << (8 * (questTokenId % 32))); // Mark required Loot as provided
        usedUpLoot[providedLootTokenId / 32] |= ((1 << lootIdx) << (8 * (providedLootTokenId % 32))); // Mark provided Loot as used up

        emit QuestContributed(_msgSender(), questTokenId, providedLootTokenId, lootIdx);

        if(isQuestSolved(questTokenId)) {
            emit QuestSolved(questTokenId);
        }

        uint256 reward = questToRewardAmountMap[questTokenId];
        if(reward > 0) {
            // Zero out the applicable reward, to prevent a reentrancy attack
            delete questToRewardAmountMap[questTokenId];
            delete questToRewardSourceMap[questTokenId];

            emit RewardClaimed(_msgSender(), questTokenId, reward);
            // The following MUST be the very last action that we're doing here
            payable(_msgSender()).transfer(reward);
        }

    }

    /**
     * @dev Get resolution state of quest
     */
    function isQuestSolved(uint256 questTokenId) public view returns (bool solved) {
        return ((requiredLootResolutionStatus[questTokenId / 32] >> (8 * (questTokenId % 32)))) & 0xff
            == getRequiredLootIdxMask(questTokenId);
    }

    /**
     * @dev set allowed reward bounds
     */
    function setRewardBounds(uint64 _minimumReward, uint64 _maximumReward) external onlyOwner {
        minimumReward = _minimumReward;
        maximumReward = _maximumReward;
    }

    /**
     * @dev Offer a reward to the next person who contributes to a quest's resolution
     */
    function offerReward(uint256 questTokenId) external payable whenNotPaused {
        require(msg.value <= maximumReward, "This is not a bank");
        require(msg.value >= minimumReward, "Seriously, that\'s all?");
        require(questToRewardSourceMap[questTokenId] == address(0) && questToRewardAmountMap[questTokenId] == 0, "Only 1 active reward per quest");
        
        uint256 reward = (100 - royalty) * msg.value / 100;
        questToRewardAmountMap[questTokenId] = reward;
        questToRewardSourceMap[questTokenId] = _msgSender();
        artistShare += msg.value - reward; // The artist gets the rest - after all, this Quest is all about Loot ;-)
        
        emit RewardOffered(_msgSender(), questTokenId, msg.value);
    }

    /**
     * @dev If someone really changes his mind, give back the reward - minus the Loot that the artist has already got, sorry...
     */
    function cancelReward(uint256 questTokenId) external whenNotPaused {
        require(questToRewardSourceMap[questTokenId] == _msgSender(), "Must have offered the reward");

        uint256 reward = questToRewardAmountMap[questTokenId];

        // Zero out the applicable reward, to prevent a reentrancy attack
        delete questToRewardAmountMap[questTokenId];
        delete questToRewardSourceMap[questTokenId];

        emit RewardCancelled(_msgSender(), questTokenId);
        
        // The following MUST be the very last action that we're doing here
        payable(_msgSender()).transfer(reward);
    }

    /**
     * @dev Withdraw artist share of funds
     *
     */
    function withdrawArtistShare() external onlyOwner {
        uint256 withdrawal = artistShare;
        artistShare -= withdrawal;
        payable(owner()).transfer(withdrawal);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Used here to implement pausing of contract
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Pause contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    //
    // ERC2981 royalties interface implementation
    //

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */

    function royaltyInfo(uint256 /* _tokenId */, uint256 _value) external view override returns (address receiver, uint256 royaltyAmount) {
        return (owner(), royalty * _value / 100);
    }

    /**
     * @dev Update expected royalty
     */
    function setRoyaltyInfo(uint16 percentage) external onlyOwner {
        royalty = percentage;
    }

    /**
     * @dev set minimum price for paid mints
     */
    function setMinimumMintPrice(uint64 _minimumMintPrice) external onlyOwner {
        minimumMintPrice = _minimumMintPrice;
    }

    //
    // OpenSea registry functions
    //

    /* @dev Update the OpenSea proxy registry address
     *
     * Zero address is allowed, and disables the whitelisting
     *
     */
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

}
