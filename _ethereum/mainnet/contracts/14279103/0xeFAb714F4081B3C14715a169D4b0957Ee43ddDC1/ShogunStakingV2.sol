// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./SafeMathUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";

import "./IShogunToken.sol";
import "./IShogunNFT.sol";

/*  _____ _                             _____                                 _     
  / ____| |                            / ____|                               (_)    
 | (___ | |__   ___   __ _ _   _ _ __ | (___   __ _ _ __ ___  _   _ _ __ __ _ _ ___ 
  \___ \| '_ \ / _ \ / _` | | | | '_ \ \___ \ / _` | '_ ` _ \| | | | '__/ _` | / __|
  ____) | | | | (_) | (_| | |_| | | | |____) | (_| | | | | | | |_| | | | (_| | \__ \
 |_____/|_| |_|\___/ \__, |\__,_|_| |_|_____/ \__,_|_| |_| |_|\__,_|_|  \__,_|_|___/
                      __/ |                                                         
                     |___/    
*/

contract ShogunStakingV2 is
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Family {
        address familyOwner;
        uint256 lastClaim;
        uint256 guildMultiplier;
        uint256 medallionMultiplier;
        uint256 shogunBonus;
        uint256[] shogunIds;
        TrainState trainState;
    }

    struct GuildCounter {
        uint8 justiceCount;
        uint8 courageCount;
        uint8 compassionCount;
        uint8 respectCount;
        uint8 integrityCount;
        uint8 honourCount;
        uint8 dutyCount;
        uint8 restraintCount;
    }

    enum TrainState {
        IN_PROGRESS,
        ENDED
    }

    IShogunNFT public SS;
    IShogunToken public SHO;

    uint256 public baseReward;
    uint256 private timescale;

    uint256[] public countMultipliers;
    uint256 public guildMultiplier;
    uint256 public medallionMultiplier;
    uint256 public shogunBonus;
    mapping(uint256 => bool) public isLegendarySamurai;
    mapping(address => uint256) public medallionCount;

    bytes public guilds;

    mapping(uint256 => Family) public families; // Map id to Family
    mapping(address => uint256[]) public userFamilies; // Maps user address to familyId
    mapping(uint256 => uint256) public onTraining; // Maps tokenId to familyId (0 = not training) (No double training)
    mapping(address => uint256) public bonusSHO;

    // Private Variables
    CountersUpgradeable.Counter private _familyId;

    // Reserve Storage
    uint256[50] private ______gap;

    address public unstaker;
    bool public trainingEnabled;
    mapping(uint256 => uint256) public lastClaim;

    // Events
    event TrainingStarted(
        address indexed user,
        uint256 trainId,
        uint256[] shogunIds,
        uint256 startTime
    );
    event TrainingEnded(
        address indexed user,
        uint256 trainId,
        uint256[] shogunIds,
        uint256 endTime
    );
    event RewardClaimed(
        address indexed user,
        uint256 amount,
        uint256 claimTime
    );
    event BonusClaimed(address indexed user, uint256 amount, uint256 claimTime);

    // Modifiers
    function __ShogunStaking_init(
        address ss,
        uint256 _baseReward,
        address admin
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        // Constructor init
        _setupRole(DEFAULT_ADMIN_ROLE, admin); // To revoke access after functions are set
        baseReward = _baseReward;
        SS = IShogunNFT(ss);
        countMultipliers = [10000, 10100, 10300];
        guildMultiplier = 200;
        medallionMultiplier = 10;
        shogunBonus = 800; // 8% for shogun bonus
        timescale = 1 days;
    }

    // ------------------------- USER FUNCTION ---------------------------

    /// @dev Start Multiple Training Sessions
    function startTrainingMultiple(uint256[][] memory shogunIdsArray) public {
        for (uint256 i = 0; i < shogunIdsArray.length; i++) {
            startTraining(shogunIdsArray[i]);
        }
    }

    /// @dev Start train
    /// @notice Sends SSs (max. 5) on a train, SSs of the same Guild and if rare will get a bonus multiplier!
    function startTraining(uint256[] memory shogunIds) public {
        require(trainingEnabled, "ShogunStaking: Training is disabled!");

        require(
            areAvailiable(shogunIds),
            "ShogunStaking: One or More shoguns are already training"
        );

        require(
            areOwned(shogunIds),
            "ShogunStaking: One or More shoguns are not owned by you!"
        );

        require(shogunIds.length <= 3, "ShogunStaking: Maximum of 3 SS only!");
        require(shogunIds.length > 0, "ShogunStaking: At least 1 SS required!");

        _familyId.increment();
        SS.lockToken(shogunIds);

        for (uint256 i = 0; i < shogunIds.length; i++) {
            onTraining[shogunIds[i]] = _familyId.current();
        }

        uint256 _guildMultiplier;
        uint256 _medallionMultiplier;
        uint256 _shogunBonus;

        (_guildMultiplier, _medallionMultiplier) = calculateMultipliers(
            shogunIds
        );

        _shogunBonus = calculateShogunBonus(shogunIds);

        Family memory _family = Family(
            msg.sender, // address familyOwner
            block.timestamp,
            _guildMultiplier, // uint256 GuildMultiplier;
            _medallionMultiplier,
            _shogunBonus,
            shogunIds, // uint256[] shogunIds;
            TrainState.IN_PROGRESS // TrainState trainState;
        );

        families[_familyId.current()] = _family;
        userFamilies[msg.sender].push(_familyId.current());

        emit TrainingStarted(
            msg.sender,
            _familyId.current(),
            shogunIds,
            block.timestamp
        );
    }

    function setMedallionCount(
        address[] memory users,
        uint256[] memory quantities
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            users.length == quantities.length,
            "ShogunStaking: User length and Quantity does not match"
        );
        for (uint256 i = 0; i < users.length; i++) {
            medallionCount[users[i]] = quantities[i];
        }
    }

    /// @dev Claim SHO reward for given family Id
    function claimRewards(uint256 familyId) public nonReentrant {
        require(trainingEnabled, "ShogunStaking: Training is disabled!");
        Family storage family = families[familyId];
        address familyOwner = family.familyOwner;
        require(
            msg.sender == familyOwner || msg.sender == unstaker,
            "ShogunStaking: Only family owner can claim SHO"
        );
        require(
            family.trainState == TrainState.IN_PROGRESS,
            "ShogunStaking: Training has already ended!"
        );
        uint256 rewards = calculateRewards(familyId);
        SHO.mint(familyOwner, rewards); // change
        family.lastClaim = block.timestamp;
        emit RewardClaimed(msg.sender, rewards, block.timestamp);
    }

    /// @dev QOL to claim all rewards
    function claimAllRewards() public nonReentrant {
        uint256[] memory familyIds = getUserFamilies(msg.sender);
        uint256 totalRewards = 0;
        Family storage train;

        for (uint256 i = 0; i < familyIds.length; i++) {
            totalRewards = totalRewards.add(calculateRewards(familyIds[i]));
            train = families[familyIds[i]];
            train.lastClaim = block.timestamp;
        }
        SHO.mint(msg.sender, totalRewards);
        emit RewardClaimed(msg.sender, totalRewards, block.timestamp);
    }

    function claimRewardsV2(uint256 tokenId) public {
        // check if token belongs to owner
        require(
            SS.ownerOf(tokenId) == msg.sender,
            "ShogunStaking: Claimant is not the owner!"
        );

        uint256 rewards = calculateRewardsV2(tokenId);
        lastClaim[tokenId] = block.timestamp;

        SHO.mint(msg.sender, rewards);
    }

    function claimRewardsMultiV2(uint256[] memory tokenIds) public {
        // check if token belongs to owner
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                SS.ownerOf(tokenIds[i]) == msg.sender,
                "ShogunStaking: Claimant is not the owner!"
            );
        }
        uint256 rewards = calculateRewardsMultiV2(tokenIds);

        for (uint256 j; j < tokenIds.length; j++) {
            lastClaim[tokenIds[j]] = block.timestamp;
        }
        SHO.mint(msg.sender, rewards);
    }

    /// @dev Lets user claim bonus SHO
    function claimBonusSHO() public nonReentrant {
        uint256 claimAmount = bonusSHO[msg.sender];
        require(
            claimAmount > 0,
            "ShogunStaking: User does not have Bonus SHO Tokens to claim"
        );
        bonusSHO[msg.sender] = 0;
        SHO.transfer(msg.sender, claimAmount);
        emit BonusClaimed(msg.sender, claimAmount, block.timestamp);
    }

    /// @dev Claim tokens and leave train
    /// @notice End train for SSs. You will stop acumulating SHO.
    function endTraining(uint256 trainId) public {
        require(trainingEnabled, "ShogunStaking: Training is disabled!");
        // Only Family Owner
        require(
            msg.sender == families[trainId].familyOwner ||
                msg.sender == unstaker,
            "ShogunStaking: Not the owner of the family"
        );
        // Must be training state
        require(
            families[trainId].trainState == TrainState.IN_PROGRESS,
            "ShogunStaking: Training already Ended"
        );

        // Distribute Remaining Rewards
        claimRewards(trainId);

        // Unlock Tokens
        SS.unlockToken(families[trainId].shogunIds);

        // Change Family State such that further claims cannot be made
        families[trainId].trainState = TrainState.ENDED;

        uint256[] memory shogunIds = families[trainId].shogunIds;

        for (uint256 i = 0; i < shogunIds.length; i++) {
            onTraining[shogunIds[i]] = 0;
        }

        emit TrainingEnded(
            msg.sender,
            trainId,
            families[trainId].shogunIds,
            block.timestamp
        );
    }

    /// @dev Claim tokens and leave train
    /// @notice End train for SSs. You will stop acumulating SHO.
    function endMultipleTraining(uint256[] memory trainIds) public {
        for (uint256 i = 0; i < trainIds.length; i++) {
            endTraining(trainIds[i]);
        }
    }

    // ----------------------- View FUNCTIONS -----------------------

    /// @dev Retrieves Count multiplier
    function getCountMultiplier(uint256 guildCount, bool sameGuild)
        public
        view
        returns (uint256)
    {
        if (sameGuild) {
            return countMultipliers[guildCount - 1] + guildMultiplier;
        } else {
            return countMultipliers[guildCount - 1];
        }
    }

    /// @dev Retrieves Rare multiplier
    function getTotalMedallionMultiplier(address user)
        public
        view
        returns (uint256)
    {
        return medallionMultiplier.mul(medallionCount[user]);
    }

    /// @dev Calculates guild Multiplier based on tokenIds
    function calculateMultipliers(uint256[] memory _tokenIds)
        internal
        view
        returns (uint256 _guildMultiplier, uint256 _medallionMultiplier)
    {
        uint8[8] memory _guildCounter = [0, 0, 0, 0, 0, 0, 0, 0];
        uint8 maxCount = 0;
        bool _sameGuild;

        // Count SS per guild
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            _guildCounter[getGuild(_tokenIds[i]) - 1] += 1;
        }

        // Find Maximum Count and Index of Max Count
        for (uint8 i = 0; i < _guildCounter.length; i++) {
            if (_guildCounter[i] > maxCount) {
                maxCount = _guildCounter[i];
            }
        }

        if (maxCount == 3) {
            _sameGuild = true;
        }

        _guildMultiplier = getCountMultiplier(_tokenIds.length, _sameGuild);
        _medallionMultiplier = getTotalMedallionMultiplier(msg.sender);
    }

    /// @dev Caluclate rewards for given Family Id
    function calculateRewards(uint256 trainId)
        public
        view
        returns (uint256 rewardAmount)
    {
        Family memory family = families[trainId];
        rewardAmount = baseReward
            .mul(block.timestamp.sub(family.lastClaim))
            .mul(family.shogunIds.length)
            .mul(
                (family.guildMultiplier).add(family.medallionMultiplier).add(
                    family.shogunBonus
                )
            )
            .div(timescale)
            .div(10000);
    }

    function calculateRewardsV2(uint256 tokenId)
        public
        view
        returns (uint256 rewardAmount)
    {
        uint256 userLastClaim = lastClaim[tokenId];
        if (userLastClaim < 1645797600) {
            userLastClaim = 1645797600;
        }

        if (isLegendarySamurai[tokenId] == true) {
            rewardAmount =
                (baseReward * 2 * (block.timestamp - userLastClaim)) /
                1 days;
        } else {
            rewardAmount =
                (baseReward * (block.timestamp - userLastClaim)) /
                1 days;
        }
    }

    function calculateRewardsMultiV2(uint256[] memory tokenIds)
        public
        view
        returns (uint256 rewardAmount)
    {
        for (uint256 i; i < tokenIds.length; i++) {
            rewardAmount += calculateRewardsV2(tokenIds[i]);
        }
    }

    function calculateShogunBonus(uint256[] memory shogunIds)
        internal
        view
        returns (uint256 out)
    {
        for (uint256 i = 0; i < shogunIds.length; i++) {
            if (isLegendarySamurai[shogunIds[i]] == true) {
                out += shogunBonus;
            }
        }
    }

    /// @dev Determines if the tokenIds are availiable for training
    function areAvailiable(uint256[] memory tokenIds)
        public
        view
        returns (bool out)
    {
        out = true;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (onTraining[tokenIds[i]] > 0) {
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
            if (SS.ownerOf(tokenIds[i]) != msg.sender) {
                out = false;
            }
        }
    }

    function getUserFamilies(address user)
        public
        view
        returns (uint256[] memory)
    {
        return userFamilies[user];
    }

    function getFamily(uint256 trainId) public view returns (Family memory) {
        return families[trainId];
    }

    function getGuild(uint256 tokenId) public view returns (uint8) {
        return uint8(guilds[tokenId - 1]);
    }

    // ---------------------- ADMIN FUNCTIONS -----------------------

    function setBaseReward(uint256 _amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseReward = _amount;
    }

    function setCountMultiplier(uint256[] memory _countMultipliers)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        countMultipliers = _countMultipliers;
    }

    function setGuildMultiplier(uint256 _guildMultiplier)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        guildMultiplier = _guildMultiplier;
    }

    function setMedallionMultiplier(uint256 _medallionMultiplier)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        medallionMultiplier = _medallionMultiplier;
    }

    function setLegendaryShoguns(
        uint256[] memory shogunIds,
        bool[] memory flags
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < shogunIds.length; i++) {
            isLegendarySamurai[shogunIds[i]] = flags[i];
        }
    }

    function setShogunBonus(uint256 _shogunBonus)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        shogunBonus = _shogunBonus;
    }

    /// @dev Set bonus SHO Tokens to be claimed
    function setBonusSHO(address[] memory addresses, uint256[] memory amounts)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            addresses.length == amounts.length,
            "ShogunStaking: To and amount length not matching"
        );
        uint256 totalAmount;
        for (uint256 i = 0; i < addresses.length; i++) {
            bonusSHO[addresses[i]] = amounts[i];
            totalAmount += amounts[i];
        }

        // Mint total bonus sho to contract
        SHO.mint(address(this), totalAmount);
    }

    /// @dev Storing Guild Metadata as 1 byte hexes on a byte for gas optimization
    function updateGuilds(bytes calldata _guilds)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        guilds = _guilds;
    }

    function setSHOToken(address sho) public onlyRole(DEFAULT_ADMIN_ROLE) {
        SHO = IShogunToken(sho);
    }

    function setTimeScale(uint256 _newTimescale)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        timescale = _newTimescale;
    }

    /// @dev Airdrop SHO Tokens out of contract
    function airdrop(address[] memory to, uint256[] memory amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            to.length == amount.length,
            "ShogunStaking: To and amount length not matching"
        );
        for (uint256 i = 0; i < to.length; i++) {
            SHO.mint(to[i], amount[i]);
        }
    }

    function setUnstaker(address _unstaker)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        unstaker = _unstaker;
    }

    function removeUnstaker() public onlyRole(DEFAULT_ADMIN_ROLE) {
        unstaker = address(0);
    }

    function enableTraining(bool training) public onlyRole(DEFAULT_ADMIN_ROLE) {
        trainingEnabled = training;
    }

    function getFamilyCount() public view returns (uint256) {
        return _familyId.current();
    }

    function getFamilyStatus(uint256 familyId)
        public
        view
        returns (TrainState)
    {
        return families[familyId].trainState;
    }

    function getShogunsOfFamily(uint256 familyId)
        public
        view
        returns (uint256[] memory)
    {
        return families[familyId].shogunIds;
    }

    function getOwnerOfFamily(uint256 familyId) public view returns (address) {
        return families[familyId].familyOwner;
    }

    function unlockShogunNFTs(uint256[] memory shogunIds)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Unlock Tokens
        SS.unlockToken(shogunIds);
    }
}
