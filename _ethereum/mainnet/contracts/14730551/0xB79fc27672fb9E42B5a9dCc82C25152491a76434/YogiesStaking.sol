// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
      _____                   _______                   _____                    _____                    _____                    _____          
     |\    \                 /::\    \                 /\    \                  /\    \                  /\    \                  /\    \         
     |:\____\               /::::\    \               /::\    \                /::\    \                /::\    \                /::\    \        
     |::|   |              /::::::\    \             /::::\    \               \:::\    \              /::::\    \              /::::\    \       
     |::|   |             /::::::::\    \           /::::::\    \               \:::\    \            /::::::\    \            /::::::\    \      
     |::|   |            /:::/~~\:::\    \         /:::/\:::\    \               \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
     |::|   |           /:::/    \:::\    \       /:::/  \:::\    \               \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
     |::|   |          /:::/    / \:::\    \     /:::/    \:::\    \              /::::\    \      /::::\   \:::\    \       \:::\   \:::\    \   
     |::|___|______   /:::/____/   \:::\____\   /:::/    / \:::\    \    ____    /::::::\    \    /::::::\   \:::\    \    ___\:::\   \:::\    \  
     /::::::::\    \ |:::|    |     |:::|    | /:::/    /   \:::\ ___\  /\   \  /:::/\:::\    \  /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \ 
    /::::::::::\____\|:::|____|     |:::|    |/:::/____/  ___\:::|    |/::\   \/:::/  \:::\____\/:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\
   /:::/~~~~/~~       \:::\    \   /:::/    / \:::\    \ /\  /:::|____|\:::\  /:::/    \::/    /\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /
  /:::/    /           \:::\    \ /:::/    /   \:::\    /::\ \::/    /  \:::\/:::/    / \/____/  \:::\   \:::\   \/____/  \:::\   \:::\   \/____/ 
 /:::/    /             \:::\    /:::/    /     \:::\   \:::\ \/____/    \::::::/    /            \:::\   \:::\    \       \:::\   \:::\    \     
/:::/    /               \:::\__/:::/    /       \:::\   \:::\____\       \::::/____/              \:::\   \:::\____\       \:::\   \:::\____\    
\::/    /                 \::::::::/    /         \:::\  /:::/    /        \:::\    \               \:::\   \::/    /        \:::\  /:::/    /    
 \/____/                   \::::::/    /           \:::\/:::/    /          \:::\    \               \:::\   \/____/          \:::\/:::/    /     
                            \::::/    /             \::::::/    /            \:::\    \               \:::\    \               \::::::/    /      
                             \::/____/               \::::/    /              \:::\____\               \:::\____\               \::::/    /       
                              ~~                      \::/____/                \::/    /                \::/    /                \::/    /        
                                                                                \/____/                  \/____/                  \/____/                                                                                                                                                                 
 */

import "./IERC20.sol";
import "./IERC1155.sol";
import "./OwnableUpgradeable.sol";

contract IYogies {
    function stakeYogie(uint256 yogieId, address sender) external {}
    function unstakeYogie(uint256 yogieId, address sender) external {}

    function vaultStartPoint() external view returns (uint256) {}
    function viyStartPoint() external view returns (uint256) {}

    function freeMint(bytes32[] calldata proof, address caller) external {}
    function nextYogieId() external view returns (uint256) {}
}

abstract contract IYogiesItems is IERC1155 {
    function car() external view returns(uint256) {}
    function house() external view returns (uint256) {}
}

abstract contract IGemies is IERC20 {
    function hasDebt(address user) external view returns (bool) {}
}

contract YogiesStaking is OwnableUpgradeable {
    
    /** === Yogies contracts === */

    IYogies public yogies;
    IYogies public gYogies;
    IGemies public gemies;

    /** === Staking core === */

    /// @dev Stores last action timestamp, reward per day, yogies staked and accumulated reward in single uint256
    /// - first 32 bits: last action timestamp
    /// - second 16 bits: total yogies staked
    /// - third 104 bits: total rewards per day the user earns
    /// - remaining 104 bits: accumulated gemies reward
    mapping(address => uint256) public yogiesStakeData;

    uint256 public yogieBaseType;
    uint256 public vaultYogieType;
    uint256 public viyYogieType;
    uint256 public gYogieType;

    mapping(uint256 => uint256) public yogieTypeToYield;

    mapping(uint256 => uint256) public carBonus; // maps car amount to bonus. Base 100
    uint256 public carBonusCap; // max car amount where bonus increase stops

    constructor(
        address _yogies,
        address _gYogies
        //address _gemies
    ) {}

    function initialize(
        address _yogies,
        address _gYogies
       // address _gemies
    ) public initializer {
        __Ownable_init();

        yogies = IYogies(_yogies);
        gYogies = IYogies(_gYogies);
        //gemies = IGemies(_gemies);

        carBonus[1] = 20;
        carBonus[2] = 35;
        carBonus[3] = 50;

        yogieTypeToYield[0] = 10 ether; // normal yogie
        yogieTypeToYield[1] = 15 ether; // vault yogie
        yogieTypeToYield[2] = 30 ether; // viy yogie
        yogieTypeToYield[3] = 45 ether; // genesis yogie

        yogieBaseType = 0;
        vaultYogieType = 1;
        viyYogieType = 2;
        gYogieType = 3;

        carBonusCap = 3;
    }


    /** === Stake helpers === */
    function _validateVaultYogies(uint256 yogieId) internal view returns (bool) {
        uint256 vaultStartPoint = yogies.vaultStartPoint();
        uint256 viyStartPoint = yogies.viyStartPoint();
        return vaultStartPoint != 0 && yogieId >= vaultStartPoint && yogieId < viyStartPoint;
    }

    function _validateVIY(uint256 yogieId) internal view returns (bool) {
        uint256 viyStartPoint = yogies.viyStartPoint();
        return yogieId >= viyStartPoint;
    }

    function _validateStakeAmount(address user, uint256 newStakeTotal) internal view returns (bool) {
        //uint256 houseBalance = yogiesItems.balanceOf(user, yogiesItems.house());
//
        //if (houseBalance == 0) {
        //    return newStakeTotal == 1;
        //} else {
        //    return newStakeTotal <= houseBalance * 10;
        //}
        return newStakeTotal == 1;
    }

    function _getUnrealizedReward(address user, uint256 lastAction, uint256 dailyReward) internal view returns (uint256) {
        uint256 nakedReward = (block.timestamp - lastAction) * dailyReward / 1 days;

        //uint256 carBalance = yogiesItems.balanceOf(user, yogiesItems.car());
        //uint256 carBonusPercentage = carBalance > carBonusCap ? carBonus[carBonusCap] : carBonus[carBalance];
//
        //if (carBonusPercentage == 0) {
        //    return nakedReward;
        //} else {
        //    uint256 carBonusReceived = nakedReward * carBonusPercentage / 100;
        //    return nakedReward + carBonusReceived;
        //}

        return nakedReward;
    }

    /** === Stake functions === */
    function _stakeSingleYogie(uint256 yogieId, uint256 yogieType) internal {
        require(yogieType >= yogieBaseType && yogieType <= gYogieType, "Incorrect yogie type");

        if (_validateVaultYogies(yogieId)) {
            require(yogieType == vaultYogieType, "Yogie type of vault yogie incorrect");
        } else {
            require(yogieType != vaultYogieType, "Yogie type of vault yogie incorrect");
        }

        if (_validateVIY(yogieId)) {
            require(yogieType == viyYogieType, "Yogie type of viy yogie incorrect");
        } else {
            require(yogieType != viyYogieType, "Yogie type of viy yogie incorrect");
        }
        
        if (yogieType == gYogieType) {
            gYogies.stakeYogie(yogieId, msg.sender);
        } else {
            yogies.stakeYogie(yogieId, msg.sender);
        }
        
        uint256 yogieStakeData = yogiesStakeData[msg.sender];

        uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
        uint256 dailyReward = _getDailyReward(yogieStakeData);
        uint256 totalStaked = _getTotalStakedYogies(yogieStakeData);
        uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);

        uint256 earnedRewardSinceLastAction = totalStaked == 0 ? 0 : _getUnrealizedReward(msg.sender, lastAction, dailyReward);        
        uint256 newDailyReward = dailyReward + yogieTypeToYield[yogieType];
        uint256 newTotal = totalStaked + 1;
        uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;
        
        require(_validateStakeAmount(msg.sender, newTotal), "Not enough houses supporting stake amount");

        yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, newDailyReward, newTotal, newAccumulatedReward);
    }

    function stakeSingleYogie(uint256 yogieId, uint256 yogieType) external {
        _stakeSingleYogie(yogieId, yogieType);
    }

    function unStakeSingleYogie(uint256 yogieId, uint256 yogieType) external {
        require(yogieType >= yogieBaseType && yogieType <= gYogieType, "Incorrect yogie type");
        //require(!gemies.hasDebt(msg.sender), "Sender account frozen");

        if (_validateVaultYogies(yogieId)) {
            require(yogieType == vaultYogieType, "Yogie type of vault yogie incorrect");
        } else {
            require(yogieType != vaultYogieType, "Yogie type of vault yogie incorrect");
        }

        if (_validateVIY(yogieId)) {
            require(yogieType == viyYogieType, "Yogie type of viy yogie incorrect");
        } else {
            require(yogieType != viyYogieType, "Yogie type of viy yogie incorrect");
        }
        
        if (yogieType == gYogieType) {
            gYogies.unstakeYogie(yogieId, msg.sender);
        } else {
            yogies.unstakeYogie(yogieId, msg.sender);
        }
        
        uint256 yogieStakeData = yogiesStakeData[msg.sender];

        uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
        uint256 dailyReward = _getDailyReward(yogieStakeData);
        uint256 totalStaked = _getTotalStakedYogies(yogieStakeData);
        uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);

        uint256 earnedRewardSinceLastAction = _getUnrealizedReward(msg.sender, lastAction, dailyReward);
        uint256 newDailyReward = dailyReward - yogieTypeToYield[yogieType];
        uint256 newTotal = totalStaked - 1;
        uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;

        yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, newDailyReward, newTotal, newAccumulatedReward);
    }

    //function stakeManyYogies(uint256[] calldata yogieIds, uint256[] calldata yogieTypes) external {
    //    require(yogieIds.length > 0, "Cannot stake 0 yogies");
    //    require(yogieIds.length == yogieTypes.length, "ids and types mismatch");
//
    //    uint256 totalRewardAdded;
    //    for (uint256 i = 0; i < yogieIds.length; i++) {
    //        uint256 yogieId = yogieIds[i];
    //        uint256 yogieType = yogieTypes[i];
//
    //        require(yogieType >= yogieBaseType && yogieType <= gYogieType, "Incorrect yogie type");
//
    //        if (_validateVaultYogies(yogieId)) {
    //            require(yogieType == vaultYogieType, "Yogie type of vault yogie incorrect");
    //        } else {
    //            require(yogieType != vaultYogieType, "Yogie type of vault yogie incorrect");
    //        }
//
    //        if (_validateVIY(yogieId)) {
    //            require(yogieType == viyYogieType, "Yogie type of viy yogie incorrect");
    //        } else {
    //            require(yogieType != viyYogieType, "Yogie type of viy yogie incorrect");
    //        }
    //        
    //        if (yogieType == gYogieType) {
    //            gYogies.stakeYogie(yogieId, msg.sender);
    //        } else {
    //            yogies.stakeYogie(yogieId, msg.sender);
    //        }
//
    //        totalRewardAdded += yogieTypeToYield[yogieType];
    //    }        
    //    
    //    uint256 yogieStakeData = yogiesStakeData[msg.sender];
//
    //    uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
    //    uint256 dailyReward = _getDailyReward(yogieStakeData);
    //    uint256 totalStaked = _getTotalStakedYogies(yogieStakeData);
    //    uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);
//
    //    if (totalStaked == 0) {
    //        require(_validateStakeAmount(msg.sender, yogieIds.length), "Not enough houses supporting stake amount");
    //        yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, totalRewardAdded, yogieIds.length, accumulatedReward);
    //    } else {
    //        uint256 earnedRewardSinceLastAction = _getUnrealizedReward(msg.sender, lastAction, dailyReward);
    //        uint256 newDailyReward = dailyReward + totalRewardAdded;
    //        uint256 newTotal = totalStaked + yogieIds.length;
    //        uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;
//
    //        require(_validateStakeAmount(msg.sender, newTotal), "Not enough houses supporting stake amount");
//
    //        yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, newDailyReward, newTotal, newAccumulatedReward);
    //    }
    //}
//
    //function unStakeManyYogies(uint256[] calldata yogieIds, uint256[] calldata yogieTypes) external {
    //    require(yogieIds.length > 0, "Cannot stake 0 yogies");
    //    require(yogieIds.length == yogieTypes.length, "ids and types mismatch");
    //    //require(!gemies.hasDebt(msg.sender), "Sender account frozen");
//
    //    uint256 totalRewardLost;
    //    for (uint256 i = 0; i < yogieIds.length; i++) {
    //        uint256 yogieId = yogieIds[i];
    //        uint256 yogieType = yogieTypes[i];
//
    //        require(yogieType >= yogieBaseType && yogieType <= gYogieType, "Incorrect yogie type");
//
    //        if (_validateVaultYogies(yogieId)) {
    //            require(yogieType == vaultYogieType, "Yogie type of vault yogie incorrect");
    //        } else {
    //            require(yogieType != vaultYogieType, "Yogie type of vault yogie incorrect");
    //        }
//
    //        if (_validateVIY(yogieId)) {
    //            require(yogieType == viyYogieType, "Yogie type of viy yogie incorrect");
    //        } else {
    //            require(yogieType != viyYogieType, "Yogie type of viy yogie incorrect");
    //        }
    //        
    //        if (yogieType == gYogieType) {
    //            gYogies.unstakeYogie(yogieId, msg.sender);
    //        } else {
    //            yogies.unstakeYogie(yogieId, msg.sender);
    //        }
//
    //        totalRewardLost += yogieTypeToYield[yogieType];
    //    }        
    //    
    //    uint256 yogieStakeData = yogiesStakeData[msg.sender];
//
    //    uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
    //    uint256 dailyReward = _getDailyReward(yogieStakeData);
    //    uint256 totalStaked = _getTotalStakedYogies(yogieStakeData);
    //    uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);
//
    //    uint256 earnedRewardSinceLastAction = _getUnrealizedReward(msg.sender, lastAction, dailyReward);
    //    uint256 newDailyReward = dailyReward - totalRewardLost;
    //    uint256 newTotal = totalStaked - yogieIds.length;
    //    uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;
//
    //    yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, newDailyReward, newTotal, newAccumulatedReward);
    //}

    //function updateAccumulatedReward(address user) external {
    //    uint256 yogieStakeData = yogiesStakeData[user];
//
    //    uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
    //    uint256 dailyReward = _getDailyReward(yogieStakeData);
    //    uint256 totalStaked = _getTotalStakedYogies(yogieStakeData);
    //    uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);
//
    //    if (totalStaked > 0) {
    //        uint256 earnedRewardSinceLastAction = _getUnrealizedReward(msg.sender, lastAction, dailyReward);
    //        uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;
    //        yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, dailyReward, totalStaked, newAccumulatedReward);
    //    }
    //}

    /** === Mint Yogies === */
    function mintYogies(bytes32[] calldata proof, bool mintAndStake) external {
        uint256 nextYogie = yogies.nextYogieId();
        yogies.freeMint(proof, msg.sender);
        
        if (mintAndStake) {
            _stakeSingleYogie(nextYogie, yogieBaseType);
        }
    }

    /** === Getters === */
    function _getLastActionTimeStamp(uint256 yogieStakeData) internal pure returns(uint256) {
        return uint256(uint32(yogieStakeData));   
    }

    function _getTotalStakedYogies(uint256 yogieStakeData) internal pure returns (uint256) {
        return uint256(uint16(yogieStakeData >> 32));
    }

    function _getDailyReward(uint256 yogieStakeData) internal pure returns (uint256) {
        return uint256(uint104(yogieStakeData >> 48));
    }

    function _getAccumulatedReward(uint256 yogieStakeData) internal pure returns (uint256) {
        return uint256(uint104(yogieStakeData >> 152));
    }

    function _getUpdatedYogieStakeData(uint256 timestamp, uint256 daily, uint256 total, uint256 pending) internal pure returns (uint256) {
        uint256 newData = timestamp;
        newData |= total << 32;
        newData |= daily << 48;
        newData |= pending << 152;
        return newData;
    }

    /** === View === */
    function getLastActionTimeStamp(address user) external view returns(uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];
        return uint256(uint32(yogieStakeData));   
    }

    function getTotalStakedYogies(address user) external view returns (uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];
        return uint256(uint16(yogieStakeData >> 32));
    }

    function getDailyReward(address user) external view returns (uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];
        return uint256(uint104(yogieStakeData >> 48));
    }

    function getAccumulatedReward(address user) external view returns (uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];
        return uint256(uint104(yogieStakeData >> 152));
    }

    function getAccumulatedGemies(address user) external view returns (uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];

        uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
        uint256 dailyReward = _getDailyReward(yogieStakeData);
        uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);

        uint256 unrealizedReward = _getUnrealizedReward(user, lastAction, dailyReward);
        uint256 totalReward = accumulatedReward + unrealizedReward;

        return totalReward;
    }

    /** === Setter === */
    function setYogies(address _yogies) external onlyOwner {
        yogies = IYogies(_yogies);
    }

    function setGYogies(address _gYogies) external onlyOwner {
        gYogies = IYogies(_gYogies);
    }
    
    function setGemies(address _gemies) external onlyOwner {
        gemies = IGemies(_gemies);
    }

    function setYogieTypeToYield(uint256 yogieType, uint256 yield) external onlyOwner {
        yogieTypeToYield[yogieType] = yield;
    }

    function setCarBonus(uint256 amount, uint256 bonus) external onlyOwner {
        carBonus[amount] = bonus;
    }

    function setCarBonusCap(uint256 newCap) external onlyOwner {
        carBonusCap = newCap;
    }
}