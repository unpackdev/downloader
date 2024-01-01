//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

//import "./console.sol";
import "./Pausable.sol";
import "./NFTContract.sol";
import "./XBTC.sol";
import "./utils.sol";
import "./errors.sol";
import "./LootboxContract.sol";

// Quest number: 1 to 5
// RewardId: reward index from 0 to 4 (to 3 for last quest)

contract QuestsContract is Pausable, Utils {
    NFTContract private immutable nftContractRef;
    LootboxContract private immutable lootboxContractRef;
    XBTC private immutable xbtcContractRef;

    mapping(address => mapping(uint8 => uint8[])) public userQuestCompleted;
    mapping(address => uint8) public userQuestsCompletedTotal;
    mapping(uint8 => uint32[]) public questRuleAmounts;
    mapping(uint8 => bool) public questRewardsDisabled;

    event QuestResult(address indexed _owner, uint8 _questId, uint8 _rewardId, uint8 _typeId);

    constructor(
        address _nftContractAddress, address _lootboxContractAddress, address _xbtcContractAddress
    )
    {
        nftContractRef = NFTContract(_nftContractAddress);
        lootboxContractRef = LootboxContract(_lootboxContractAddress);
        xbtcContractRef = XBTC(_xbtcContractAddress);

        // Quests
        questRuleAmounts[1] = [5, 11, 19, 30];
        questRuleAmounts[2] = [8, 13, 21, 34];
        questRuleAmounts[3] = [5000, 21000, 42000, 120000];
        questRuleAmounts[4] = [3, 8, 13, 33];
        questRuleAmounts[5] = [3, 8, 13];
    }

    modifier isQuestRewardAvailable(uint8 _questId, uint8 _rewardIndex) {
        if (checkQuestNotAvailable(msg.sender, _questId, _rewardIndex)) {
            revert Quests_RewardNotAvailable();
        }
        if (_rewardIndex > 3 || _questId == 5 && _rewardIndex > 2) {
            revert Quests_InvalidReward();
        }
        _;
    }

    // QUEST #1: Unique NFT Collection - user need to collect unique First-Hand NFT to complete the quest
    // Collect first hand 5 unique NFTs: Tier 1 reward.
    // Collect first hand 11 unique NFTs: Tier 2 reward.
    // Collect first hand 19 unique NFTs: Tier 3 reward.
    // Collect first hand 30 unique NFTs: Tier 4 reward.
    function questUniqueNft(uint8 _rewardIndex)
    external
    whenNotPaused
    isQuestRewardAvailable(1, _rewardIndex)
    {
        uint8 _questId = 1;
        uint32 _countNFT = getUniqueNftCount(msg.sender);
        if (_countNFT < questRuleAmounts[_questId][_rewardIndex]) {
            revert Quests_NotEnoughUniqueNFT(questRuleAmounts[_questId][_rewardIndex]);
        }

        _mintRewardNFT(_questId, _rewardIndex);
    }

    // QUEST #2: First-Hand NFT Accumulation - user need to hold NFTs for a certain period of time
    // Collect and hold first hand 8 NFTs: Tier 1 reward.
    // Collect and hold first hand 13 NFTs: Tier 2 reward.
    // Collect and hold first hand 21 NFTs: Tier 3 reward.
    // Collect and hold first hand 34 NFTs: Tier 4 reward.
    function questNftAccumulation(uint8 _rewardIndex)
    external
    whenNotPaused
    isQuestRewardAvailable(2, _rewardIndex)
    {
        uint8 _questId = 2;
        uint32 _countNFT = getNftTotalCount(msg.sender);
        if (_countNFT < questRuleAmounts[_questId][_rewardIndex]) {
            revert Quests_NotEnoughTotalNFT(questRuleAmounts[_questId][_rewardIndex]);
        }

        _mintRewardNFT(_questId, _rewardIndex);
    }

    // QUEST #3: Spending XBTC Rewards - user need to spend XBTC to complete the quest
    // Spend ≥ 5000 xBTC: Tier 1 reward.
    // Spend ≥ 21000 xBTC: Tier 2 reward.
    // Spend ≥ 42000 xBTC: Tier 3 reward.
    // Spend ≥ 120000 xBTC: Tier 4 reward.
    function questSpendXBTC(uint8 _rewardIndex)
    external
    whenNotPaused
    isQuestRewardAvailable(3, _rewardIndex)
    {
        uint8 _questId = 3;
        uint32 _totalSpend = uint32(xbtcContractRef.userSpendXBTC(msg.sender) / 10 ** 18);
        if (_totalSpend < questRuleAmounts[_questId][_rewardIndex]) {
            revert Quests_NotEnoughSpendXBTC(_totalSpend);
        }

        _mintRewardNFT(_questId, _rewardIndex);
    }

    // QUEST #4: Treasury Hunter - user need to open and burn lootboxes
    // Open and burn 3 mystery boxes: Tier 1 reward.
    // Open and burn 8 mystery boxes: Tier 2 reward.
    // Open and burn 13 mystery boxes: Tier 3 reward.
    // Open and burn 33 mystery boxes: Tier 4 reward.
    function questTreasuryHunter(uint8 _rewardIndex)
    external
    whenNotPaused
    isQuestRewardAvailable(4, _rewardIndex)
    {
        uint8 _questId = 4;
        uint32 _totalOpened = lootboxContractRef.userOpenedLootboxes(msg.sender);
        if (_totalOpened < questRuleAmounts[_questId][_rewardIndex]) {
            revert Quests_NotEnoughLootboxesOpened(_totalOpened);
        }

        _mintRewardNFT(_questId, _rewardIndex);
    }

    // QUEST #5: Prize Accumulation - user need to claim quest rewards
    // Accumulate 3 rewards: Tier 1 reward.
    // Accumulate 8 rewards: Tier 2 reward.
    // Accumulate 13 rewards: Tier 3 reward.
    function questPrizeAccumulation(uint8 _rewardIndex)
    external
    whenNotPaused
    isQuestRewardAvailable(5, _rewardIndex)
    {
        uint8 _questId = 5;
        uint8 _totalRewards = userQuestsCompletedTotal[msg.sender];
        if (_totalRewards < questRuleAmounts[_questId][_rewardIndex]) {
            revert Quests_NotEnoughRewardsAccumulated(_totalRewards);
        }

        _mintRewardNFT(_questId, _rewardIndex);
    }

    // Get count of NFTs for first hand user
    function getNftTotalCount(address _user)
    public view
    returns (uint32)
    {
        uint32 _countHold = 0;
        uint16 _amount = uint16(nftContractRef.balanceOf(_user));

        for (uint16 _i = 0; _i < _amount; _i++) {
            uint256 _tokenId = nftContractRef.tokenOfOwnerByIndex(_user, _i);
            if (nftContractRef.firstHandNFTs(_tokenId)) {
                _countHold++;
            }
        }

        return _countHold;
    }

    // Get count of unique NFTs (types) for user
    function getUniqueNftCount(address _user)
    public view
    returns (uint32)
    {
        uint32 _countUnique = 0;
        uint16 _amount = uint16(nftContractRef.balanceOf(_user));
        uint8[] memory _typesExist = new uint8[](_amount);

        for (uint16 _i = 0; _i < _amount; _i++) {
            uint256 _tokenId = nftContractRef.tokenOfOwnerByIndex(_user, _i);
            if (nftContractRef.firstHandNFTs(_tokenId)) {
                uint8 _rarityType = nftContractRef.nftRarityTypes(_tokenId);
                if (!valueExists(_typesExist, _rarityType)) {
                    _typesExist[_i] = _rarityType;
                    _countUnique++;
                }
            }
        }

        return _countUnique;
    }

    function checkQuestNotAvailable(address _user, uint8 _questId, uint8 _rewardIndex)
    public view
    returns (bool) {
        if (questRewardsDisabled[_rewardIndex]) {
            return true;
        }
        return valueExists(userQuestCompleted[_user][_questId], _rewardIndex);
    }

    // ---------------- Private ----------------

    function _mintRewardNFT(uint8 _questId, uint8 _rewardIndex)
    private
    {
        uint8[] memory _types = nftContractRef.getAvailableTypes(DistributionType.Quests, _getRewardRarityById(_rewardIndex));
        if (_types.length > 0) {
            userQuestCompleted[msg.sender][_questId].push(_rewardIndex);
            userQuestsCompletedTotal[msg.sender]++;
            nftContractRef.questCompleteMint(msg.sender, _types[0]);

            emit QuestResult(msg.sender, _questId, _rewardIndex, _types[0]);
        } else {
            // Disable rewards if no more available
            questRewardsDisabled[_rewardIndex] = true;
        }
    }

    function _getRewardRarityById(uint8 _rewardIndex)
    private pure
    returns (RarityNFT)
    {
        if (_rewardIndex == 0) {
            return RarityNFT.Ordinary;
        } else if (_rewardIndex == 1) {
            return RarityNFT.Majestic;
        } else if (_rewardIndex == 2) {
            return RarityNFT.Epic;
        } else if (_rewardIndex == 3) {
            return RarityNFT.Legendary;
        }

        revert Quests_InvalidReward();
    }

}