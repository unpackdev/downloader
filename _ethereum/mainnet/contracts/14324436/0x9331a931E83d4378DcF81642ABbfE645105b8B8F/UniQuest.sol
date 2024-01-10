//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMathUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";

import "./IUninterestedUnicorns.sol";
import "./ICandyToken.sol";

contract UniQuest is
    AccessControlUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Quest {
        address questOwner;
        uint256 questLevel;
        uint256 questStart;
        uint256 questEnd;
        uint256 lastClaim;
        uint256 clanMultiplier;
        uint256 rareMultiplier;
        uint256 lengthMultiplier;
        uint256[] unicornIds;
        QuestState questState;
    }

    struct ClanCounter {
        uint8 airCount;
        uint8 earthCount;
        uint8 fireCount;
        uint8 waterCount;
        uint8 darkCount;
        uint8 pureCount;
    }

    // Enums
    enum Clans {
        AIR,
        EARTH,
        FIRE,
        WATER,
        DARK,
        PURE
    }

    enum QuestState {
        IN_PROGRESS,
        ENDED
    }

    IUninterestedUnicorns public UU;
    ICandyToken public UCD;

    uint256 public baseReward;
    uint256 public baseRoboReward;
    uint256 public baseGoldenReward;
    uint256 private timescale;

    uint256[] public clanMultipliers;
    uint256[] public rareMultipliers;
    uint256[] public lengthMultipliers;
    uint256[] public questLengths;
    bytes public clans;

    mapping(uint256 => Quest) public quests;
    mapping(address => uint256[]) public userQuests; // Maps user address to questIds
    mapping(uint256 => uint256) public onQuest; // Maps tokenId to QuestId (0 = not questing)
    mapping(uint256 => uint256) clanCounter;

    mapping(uint256 => bool) private isRoboUni;
    mapping(uint256 => bool) private isGoldenUni;
    mapping(uint256 => uint256) private HODLLastClaim;

    // Private Variables
    CountersUpgradeable.Counter private _questId;
    bool private initialized;

    // Reserve Storage
    uint256[50] private ______gap;

    // Events
    event QuestStarted(
        address indexed user,
        uint256 questId,
        uint256[] unicornIds,
        uint256 questLevel,
        uint256 questStart,
        uint256 questEnd
    );
    event QuestEnded(address indexed user, uint256 questId, uint256 endDate);
    event RewardClaimed(
        address indexed user,
        uint256 amount,
        uint256 claimTime
    );

    event QuestUpgraded(
        address indexed user,
        uint256 questId,
        uint256 questLevel
    );

    // Modifiers
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "UninterestedUnicorns: OnlyAdmin"
        );
        _;
    }

    function __UniQuest_init(
        address uu,
        uint256 _baseReward,
        uint256 _baseRoboReward,
        uint256 _baseGoldenReward,
        address deployer,
        address treasury
    ) public initializer {
        require(!initialized, "Contract instance has already been initialized");
        __AccessControl_init();
        __ReentrancyGuard_init();
        __ERC721Holder_init();

        // Constructor init
        _setupRole(DEFAULT_ADMIN_ROLE, deployer); // To revoke access after functions are set
        grantRole(DEFAULT_ADMIN_ROLE, treasury);
        baseReward = _baseReward;
        baseRoboReward = _baseRoboReward;
        baseGoldenReward = _baseGoldenReward;
        UU = IUninterestedUnicorns(uu);
        clanMultipliers = [10000, 10000, 10200, 10400, 10600, 11000];
        rareMultipliers = [10000, 10200, 10400, 10600, 10800, 11000];
        lengthMultipliers = [10000, 10500, 11000];
        questLengths = [30 days, 90 days, 180 days];
        timescale = 1 days;

        initialized = true;
    }

    // ------------------------- USER FUNCTION ---------------------------

    /// @dev Start quest. questLevels = 0,1,2
    /// @notice Sends U_Us (max. 5) on a quest, U_Us of the same clan and if rare will get a bonus multiplier!
    function startQuest(uint256[] memory unicornIds, uint256 questLevel)
        public
    {
        require(
            areOwned(unicornIds),
            "UniQuest: One or More Unicorns are not owned by you!"
        );

        require(questLevel <= 2, "UniQuest: Invalid Quest Level!");
        require(unicornIds.length <= 5, "UniQuest: Maximum of 5 U_U only!");
        require(unicornIds.length > 0, "UniQuest: At least 1 U_U required!");

        _questId.increment();
        _lockTokens(unicornIds);

        for (uint256 i = 0; i < unicornIds.length; i++) {
            onQuest[unicornIds[i]] = _questId.current();
        }

        uint256 _clanMultiplier;
        uint256 _rareMultiplier;

        (_clanMultiplier, _rareMultiplier) = calculateMultipliers(unicornIds);

        Quest memory _quest = Quest(
            msg.sender, // address questOwner
            questLevel, // uint256 questLevel;
            block.timestamp, // uint256 questStart;
            block.timestamp.add(questLengths[questLevel]), // uint256 questEnd;
            block.timestamp, // uint256 lastClaim;
            _clanMultiplier, // uint256 clanMultiplier;
            _rareMultiplier, // uint256 rareMultiplier;
            lengthMultipliers[questLevel], // uint256 lengthMultiplier;
            unicornIds, // uint256[] unicornIds;
            QuestState.IN_PROGRESS // QuestState questState;
        );

        quests[_questId.current()] = _quest;
        userQuests[msg.sender].push(_questId.current());

        emit QuestStarted(
            msg.sender,
            _questId.current(),
            unicornIds,
            questLevel,
            block.timestamp,
            block.timestamp.add(questLengths[questLevel])
        );
    }

    /// @dev Start quest. questLevels = 0,1,2
    /// @notice Sends U_Us (max. 5) on a quest, U_Us of the same clan and if rare will get a bonus multiplier!
    function upgradeQuest(uint256 questId, uint256 questLevel) public {
        Quest storage quest = quests[questId];
        require(
            quest.questOwner == msg.sender,
            "UniQuest: Quest not owned by you!"
        );

        require(questLevel <= 2, "UniQuest: Invalid Quest Level!");
        require(
            questLevel > quest.questLevel,
            "UniQuest: Invalid Quest Level!"
        );

        // Increase Lockup Duration
        quest.questLevel = questLevel;
        quest.questEnd = block.timestamp + questLengths[questLevel];
        quest.lengthMultiplier = lengthMultipliers[questLevel];
    }

    /// @dev Claim UCD reward for given quest
    function claimRewards(uint256 questId) public nonReentrant {
        Quest storage quest = quests[questId];
        address questOwner = quest.questOwner;
        require(
            msg.sender == questOwner,
            "UniQuest: Only quest owner can claim candy"
        );
        require(
            quest.questState == QuestState.IN_PROGRESS,
            "UniQuest: Quest has already ended!"
        );
        uint256 rewards = calculateRewards(questId);
        UCD.mint(questOwner, rewards);
        quest.lastClaim = block.timestamp;
        emit RewardClaimed(msg.sender, rewards, block.timestamp);
    }

    /// @dev QOL to claim all rewards
    function claimAllRewards() public nonReentrant {
        uint256[] memory questIds = getUserQuests(msg.sender);
        uint256 totalRewards = 0;
        Quest storage quest;

        for (uint256 i = 0; i < questIds.length; i++) {
            totalRewards = totalRewards.add(calculateRewards(questIds[i]));
            quest = quests[questIds[i]];
            quest.lastClaim = block.timestamp;
        }
        UCD.mint(msg.sender, totalRewards);
    }

    /// @dev Claim HODLing Rewards for owned pure U_Us
    /// @notice You can only claim HODL rewards for your owned pure U_Us
    function claimHODLRewards(uint256[] memory tokenIds) public nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                UU.ownerOf(tokenIds[i]) == msg.sender,
                "UniQuest: Not Owner of token"
            );
        }

        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards += calculateHODLReward(tokenIds[i]);
            HODLLastClaim[tokenIds[i]] = block.timestamp;
        }

        UCD.mint(msg.sender, totalRewards);
    }

    /// @dev Claim tokens and leave quest
    /// @notice End quest for U_Us. You will stop acumulating UCD.
    function endQuest(uint256 questId) public {
        // Only Quest Owner
        require(
            msg.sender == quests[questId].questOwner,
            "UniQuest: Not the owner of quest"
        );
        // Current Time > Quest End Time
        require(
            isQuestEndable(questId),
            "UniQuest: Unicorns are still questing!"
        );
        // Must be questing state
        require(
            quests[questId].questState == QuestState.IN_PROGRESS,
            "UniQuest: Quest already Ended"
        );

        // Distribute Remaining Rewards
        claimRewards(questId);

        // Unlock Tokens
        _unlockTokens(quests[questId].unicornIds);

        // Change Quest State such that further claims cannot be made
        quests[questId].questState = QuestState.ENDED;

        emit QuestEnded(msg.sender, questId, block.timestamp);
    }

    // ----------------------- View FUNCTIONS -----------------------

    /// @dev Determines if quest is ended
    function isQuestEndable(uint256 questId) public view returns (bool) {
        return block.timestamp > quests[questId].questEnd;
    }

    /// @dev Retrieves clan multiplier
    function getClanMultiplier(uint256 clanCount)
        public
        view
        returns (uint256)
    {
        return clanMultipliers[clanCount];
    }

    /// @dev Retrieves Rare multiplier
    function getRareMultiplier(uint256 rareCount)
        public
        view
        returns (uint256)
    {
        return rareMultipliers[rareCount];
    }

    /// @dev Retrieves Length multiplier
    function getLengthMultiplier(uint256 questLevel)
        public
        view
        returns (uint256)
    {
        return lengthMultipliers[questLevel];
    }

    /// @dev Calculates Clan Multiplier based on tokenIds
    function calculateMultipliers(uint256[] memory _tokenIds)
        internal
        view
        returns (uint256 _clanMultiplier, uint256 _rareMultiplier)
    {
        uint8[6] memory _clanCounter = [0, 0, 0, 0, 0, 0];
        uint8 maxCount = 0;
        uint8 maxIndex;
        uint256 rareCount = 0;

        // Count UU per clan
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            _clanCounter[getClan(_tokenIds[i]) - 1] += 1;
        }

        // Find Maximum Count and Index of Max Count
        for (uint8 i = 0; i < _clanCounter.length; i++) {
            if (_clanCounter[i] > maxCount) {
                maxCount = _clanCounter[i];
                maxIndex = i;
            }
        }

        // Wildcard bonus
        if (maxIndex < 4) {
            maxCount += _clanCounter[5];
        }

        _clanMultiplier = getClanMultiplier(maxCount);

        rareCount = rareCount.add(_clanCounter[4]).add(_clanCounter[5]);
        _rareMultiplier = getRareMultiplier(rareCount);
    }

    /// @dev Calulate HODLing rewards for tokenIds given
    function calculateHODLRewards(uint256[] memory tokenIds)
        public
        view
        returns (uint256 HODLRewards)
    {
        HODLRewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isGoldenUni[tokenIds[i]]) {
                HODLRewards = HODLRewards.add(
                    baseGoldenReward.mul(calcGoldenDuration(tokenIds[i])).div(
                        timescale
                    )
                );
            } else if (isRoboUni[tokenIds[i]]) {
                HODLRewards = HODLRewards.add(
                    baseRoboReward.mul(calcRoboDuration(tokenIds[i])).div(
                        timescale
                    )
                );
            }
        }
    }

    /// @dev Calulate HODLing rewards for tokenId
    function calculateHODLReward(uint256 tokenId)
        public
        view
        returns (uint256 HODLRewards)
    {
        if (isGoldenUni[tokenId]) {
            HODLRewards = baseGoldenReward.mul(calcGoldenDuration(tokenId)).div(
                    timescale
                );
        } else if (isRoboUni[tokenId]) {
            HODLRewards = baseRoboReward.mul(calcRoboDuration(tokenId)).div(
                timescale
            );
        }
    }

    /// @dev Calculate duration since last claim for golden U_Us
    function calcGoldenDuration(uint256 tokenId)
        private
        view
        returns (uint256)
    {
        return block.timestamp.sub(HODLLastClaim[tokenId]);
    }

    /// @dev Calculate duration since last claim for UniMech U_Us
    function calcRoboDuration(uint256 tokenId) private view returns (uint256) {
        return block.timestamp.sub(HODLLastClaim[tokenId]);
    }

    /// @dev Caluclate rewards for given Quest Id
    function calculateRewards(uint256 questId)
        public
        view
        returns (uint256 rewardAmount)
    {
        Quest memory quest = quests[questId];
        rewardAmount = baseReward
            .mul(block.timestamp.sub(quest.lastClaim))
            .mul(quest.unicornIds.length)
            .mul(quest.clanMultiplier)
            .mul(quest.rareMultiplier)
            .mul(quest.lengthMultiplier)
            .div(timescale)
            .div(1000000000000);
    }

    /// @dev Determines if the tokenIds are availiable for questing
    function areAvailiable(uint256[] memory tokenIds)
        public
        view
        returns (bool out)
    {
        out = true;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (onQuest[tokenIds[i]] > 0) {
                out = false;
            }
        }
    }

    /// @dev Determines if the all tokenIds are owned by msg sneder
    function areOwned(uint256[] memory tokenIds)
        public
        view
        returns (bool out)
    {
        out = true;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (UU.ownerOf(tokenIds[i]) != msg.sender) {
                out = false;
            }
        }
    }

    function getUserQuests(address user)
        public
        view
        returns (uint256[] memory)
    {
        return userQuests[user];
    }

    function getQuest(uint256 questId) public view returns (Quest memory) {
        return quests[questId];
    }

    function isQuestOver(uint256 questId) public view returns (bool) {
        Quest memory quest = quests[questId];
        return block.timestamp > quest.questEnd;
    }

    function getClan(uint256 tokenId) public view returns (uint8) {
        return uint8(clans[tokenId - 1]);
    }

    // ---------------------- ADMIN FUNCTIONS -----------------------

    function setBaseReward(uint256 _amount) public onlyAdmin {
        baseReward = _amount;
    }

    function setRoboReward(uint256 _amount) public onlyAdmin {
        baseRoboReward = _amount;
    }

    function setGoldenReward(uint256 _amount) public onlyAdmin {
        baseGoldenReward = _amount;
    }

    /// @dev Storing Clan Metadata as 1 byte hexes on a byte for gas optimization
    function setRoboIds(uint256[] memory _roboTokenIds) public onlyAdmin {
        for (uint256 i = 0; i < _roboTokenIds.length; i++) {
            isRoboUni[_roboTokenIds[i]] = true;
            HODLLastClaim[_roboTokenIds[i]] = block.timestamp;
        }
    }

    /// @dev Storing Clan Metadata as 1 byte hexes on a byte for gas optimization
    function setGoldenIds(uint256[] memory _goldenTokenIds) public onlyAdmin {
        for (uint256 i = 0; i < _goldenTokenIds.length; i++) {
            isGoldenUni[_goldenTokenIds[i]] = true;
            HODLLastClaim[_goldenTokenIds[i]] = block.timestamp;
        }
    }

    /// @dev Storing Clan Metadata as 1 byte hexes on a byte for gas optimization
    function updateClans(bytes calldata _clans) public onlyAdmin {
        clans = _clans;
    }

    function setUniCandy(address uniCandy) public onlyAdmin {
        UCD = ICandyToken(uniCandy);
    }

    function setTimeScale(uint256 _newTimescale) public onlyAdmin {
        timescale = _newTimescale;
    }

    function transferQuestOwnership(uint256 questId, address newOwner)
        public
        onlyAdmin
    {
        Quest storage quest = quests[questId];
        quest.questOwner = newOwner;
    }

    function setQuestLengths(uint256[] memory _newQuestLengths)
        public
        onlyAdmin
    {
        questLengths = _newQuestLengths;
    }

    function _lockTokens(uint256[] memory tokenIds) private {
        for (uint256 i; i < tokenIds.length; i++) {
            UU.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    function _unlockTokens(uint256[] memory tokenIds) private {
        for (uint256 i; i < tokenIds.length; i++) {
            UU.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            // reset last claim for HODL rewards
            HODLLastClaim[tokenIds[i]] = block.timestamp;
        }
    }
}
