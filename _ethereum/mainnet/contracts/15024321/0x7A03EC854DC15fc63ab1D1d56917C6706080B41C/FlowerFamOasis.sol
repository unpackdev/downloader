// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./console.sol";
import "./SimpleAccessUpgradable.sol";

import "./IBee.sol";
import "./IHoney.sol";
import "./IFlowerFam.sol";
import "./IFlowerFamNewGen.sol";
import "./IFlowerFamAffliliate.sol";

interface IFlowerFamEcoSystem {
    function updateTotalAccumulatedProductionOfUser(
        address user,
        uint256 amount
    ) external;

    function addInternalBalance(address user, uint112 amount) external;
}

interface IHoneyCoinReserve {
    function releaseFunds(uint256 amount, address user) external;

    function sendToMarketing(uint256 amount) external;

    function sendToLiquidity(uint256 amount) external;
}

contract FlowerFamOasis is SimpleAccessUpgradable {
    IBee public beeNFT;
    IHoney public HoneyToken;
    IFlowerFam public flowerFamNFT;
    IHoneyCoinReserve public honeyCoinReserve;
    IFlowerFamNewGen public flowerFamNewGenNFT;
    IFlowerFamEcoSystem public flowerFamEcoSystem;

    // Tokenomics
    uint256 public taxActionCounter;
    uint256 public taxActionTriggerMark;

    uint256 public marketingActionTriggerOffset;
    uint256 public liquidityActionTriggerOffset;

    uint256 public shareMarketing;
    uint256 public shareLiquidity;

    uint256 public allocMarketing;
    uint256 public allocLiquidity;

    bool public actionActive;

    /** User Oasis production */
    struct UserOasisProduction {
        uint32 lastAction;
        uint112 totalAccumulated;
        uint112 totalProductionPerDay;
        uint256 totalClaimed;
    }

    /** Oasis Land */
    struct OasisLand {
        uint256 price;
        uint256 reward;
    }

    /** User Oasis Info (only for view) */
    struct UserLandInfo {
        uint256 price;
        uint256 reward;
        uint256 landId;
        uint256 landCount;
        uint256 landYield;
        uint256 landEarnings;
    }

    uint256[] public oasisLandIds;

    mapping(uint256 => bool) public beeStakeInfo;
    mapping(uint256 => bool) public flowerStakeInfo;
    mapping(address => uint256) public userAssetsCount;
    mapping(address => uint256) public userToLastClaimInteraction;

    mapping(uint256 => OasisLand) public oasisLands;
    mapping(uint256 => UserLandInfo) public userLands;
    mapping(address => UserOasisProduction) public userToProductionInfo;
    mapping(address => mapping(uint256 => uint256)) public userToLandSpots;

    IFlowerFamAffliliate public flowerFamAffiliate;

    mapping(uint256 => uint256) public oasisLandToSale;
    mapping(uint256 => uint256) public oasisLandToSupply;

    event BuyLand(
        address indexed user,
        uint256 indexed landId,
        uint256 indexed amount
    );
    event BatchStakeAsset(address indexed user, uint256 indexed assetType);
    event BatchUnStakeAsset(address indexed user, uint256 indexed assetType);
    event ClaimUnclaimedAmount(
        address indexed user,
        uint256 indexed claimAmount,
        uint256 bonusAmount
    );

    event UpdateTotalProductionPerDay(
        address indexed user,
        uint256 indexed totalAccumulated,
        uint256 indexed totalProductionPerDay
    );

    constructor(
        address _honeyToken,
        address _flowerFamNFT,
        address _beeNFT,
        address _flowerFamNewGen,
        address _flowerFamEcosystem,
        address _honeyCoinReserve
    ) {}

    function initialize(
        address _honeyToken,
        address _flowerFamNFT,
        address _beeNFT,
        address _flowerFamNewGen,
        address _flowerFamEcosystem,
        address _honeyCoinReserve
    ) public initializer {
        __Ownable_init();

        beeNFT = IBee(_beeNFT);
        HoneyToken = IHoney(_honeyToken);
        flowerFamNFT = IFlowerFam(_flowerFamNFT);
        flowerFamNewGenNFT = IFlowerFamNewGen(_flowerFamNewGen);
        flowerFamEcoSystem = IFlowerFamEcoSystem(_flowerFamEcosystem);
        honeyCoinReserve = IHoneyCoinReserve(_honeyCoinReserve);

        taxActionTriggerMark = 20;
        liquidityActionTriggerOffset = 10;
        actionActive = true;

        shareMarketing = 20;
        shareLiquidity = 12;
    }

    receive() external payable {}

    function buyLand(
        uint256 landId,
        uint256 amount,
        uint256[] memory flowersWithBees,
        address affiliate
    ) external {
        require(oasisLands[landId].price > 0, "No land exists with id");
        require(
            oasisLandToSale[landId] + amount <= oasisLandToSupply[landId],
            "Land supply exceeded"
        );

        OasisLand memory land = oasisLands[landId];
        userToLandSpots[msg.sender][landId] += amount;

        uint256 totalPrice = land.price * amount;

        totalPrice = _applyAffiliate(totalPrice, affiliate);

        HoneyToken.spendEcoSystemBalance(
            msg.sender,
            uint128(totalPrice),
            flowersWithBees,
            ""
        );

        accumulateShares(totalPrice);
        triggerMarketing();
        triggerLiquidity();

        _updateUserOasisProduction(msg.sender);

        if (userToLastClaimInteraction[msg.sender] == 0) {
            userToLastClaimInteraction[msg.sender] = block.timestamp;
        }

        oasisLandToSale[landId] += amount;

        emit BuyLand(msg.sender, landId, amount);
    }

    // @dev assetType = 0 -> FlowerFam
    // @dev assetType = 1 -> FlowerFamNewGen
    // @dev assetType = 2 -> Bee
    function batchStakeAssetInOasis(
        uint256 assetType,
        uint256[] calldata flowerFamAssetIds
    ) external {
        require(oasisLandIds.length > 0, "No lands exists");
        require(flowerFamAssetIds.length > 0, "No fams provided");

        for (uint256 i = 0; i < flowerFamAssetIds.length; i++) {
            uint256 assetId = flowerFamAssetIds[i];

            userAssetsCount[msg.sender] += 1;

            if (assetType == 0) {
                flowerStakeInfo[assetId] = true;
                flowerFamNFT.stake(msg.sender, assetId);
            }

            if (assetType == 1) {
                flowerStakeInfo[assetId] = true;
                flowerFamNewGenNFT.stake(msg.sender, assetId);
            }

            if (assetType == 2) {
                beeStakeInfo[assetId] = true;
                beeNFT.stake(msg.sender, assetId);
            }
        }

        _updateUserOasisProduction(msg.sender);

        emit BatchStakeAsset(msg.sender, assetType);
    }

    function batchUnstakeAssetInOasis(
        uint256 assetType,
        uint256[] calldata flowerFamAssetIds
    ) external {
        require(flowerFamAssetIds.length > 0, "No fams provided");

        for (uint256 i = 0; i < flowerFamAssetIds.length; i++) {
            uint256 assetId = flowerFamAssetIds[i];

            userAssetsCount[msg.sender] -= 1;

            if (assetType == 0) {
                delete flowerStakeInfo[assetId];
                flowerFamNFT.unstake(msg.sender, assetId);
            }

            if (assetType == 1) {
                delete flowerStakeInfo[assetId];
                flowerFamNewGenNFT.unstake(msg.sender, assetId);
            }

            if (assetType == 2) {
                delete beeStakeInfo[assetId];
                beeNFT.unstake(msg.sender, assetId);
            }
        }

        _updateUserOasisProduction(msg.sender);

        emit BatchUnStakeAsset(msg.sender, assetType);
    }

    function cliamUnclaimedReward(uint256 ecoAmount, uint256 walletAmount)
        external
    {
        uint256 claimAmount = ecoAmount + walletAmount;
        uint256 claimTaxAmount = _getClaimTaxAmount(claimAmount);
        claimAmount -= claimTaxAmount;

        require(claimAmount > 0, "Claim amount should be greater than 0");

        _updateUserOasisProduction(msg.sender);

        uint256 canClaimAmount = _getTotalProductionOfUser(msg.sender);
        uint256 lastClaimedBonus = _getLastClaimedBonusPercentage(msg.sender);

        UserOasisProduction storage userOasisProduction = userToProductionInfo[
            msg.sender
        ];

        userOasisProduction.totalClaimed += claimAmount;
        userOasisProduction.lastAction = uint32(block.timestamp);

        claimAmount += (claimAmount * lastClaimedBonus) / 1000;

        require(
            canClaimAmount >= claimAmount,
            "Amounts are greater than claim amount"
        );

        uint256 ecoShare = ecoAmount * 1000 / (ecoAmount + walletAmount);
        uint256 walletShare = walletAmount * 1000 / (ecoAmount + walletAmount);

        uint256 newEcoAmount = ecoShare * claimAmount / 1000;
        uint256 newWalletAmount = walletShare * claimAmount / 1000;

        if (newEcoAmount > 0) {
            flowerFamEcoSystem.updateTotalAccumulatedProductionOfUser(
                msg.sender,
                newEcoAmount
            );
        }

        if (newWalletAmount > 0) {
            honeyCoinReserve.releaseFunds(newWalletAmount, msg.sender);
        }

        userToLastClaimInteraction[msg.sender] = block.timestamp;

        emit ClaimUnclaimedAmount(msg.sender, claimAmount, lastClaimedBonus);
    }

    function getUserLandsCount(address user) external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < oasisLandIds.length; i++) {
            count += userToLandSpots[user][oasisLandIds[i]];
        }
        return count;
    }

    function getUserLandDetail(address user, uint256 landId)
        external
        view
        returns (UserLandInfo memory)
    {
        require(oasisLands[landId].price != 0, "No land exists");

        UserLandInfo memory userLand = userLands[landId];

        userLand.landId = landId;
        userLand.price = oasisLands[landId].price;
        userLand.reward = oasisLands[landId].reward;
        userLand.landYield = _getUserLandYield(landId, user);
        userLand.landEarnings = _getUserLandEarnings(landId, user);
        userLand.landCount = userToLandSpots[user][landId];

        return userLand;
    }

    function getTotalProductionOfUser(address user)
        external
        view
        returns (uint256)
    {
        uint256 claimAmount = _getTotalProductionOfUser(user);
        uint256 lastClaimedBonus = _getLastClaimedBonusPercentage(user);
        return claimAmount + (claimAmount * lastClaimedBonus) / 100;
    }

    function getUserLands(address user)
        external
        view
        returns (UserLandInfo[] memory)
    {
        UserLandInfo[] memory lands = new UserLandInfo[](oasisLandIds.length);

        for (uint256 i = 0; i < oasisLandIds.length; i++) {
            uint256 landId = oasisLandIds[i];
            uint256 count = userToLandSpots[user][landId];
            if (count > 0) {
                lands[i] = userLands[landId];
                lands[i].landCount = count;
                lands[i].landYield = _getUserLandYield(landId, user);
                lands[i].landEarnings = _getUserLandEarnings(landId, user);
            }
        }

        return lands;
    }

    function isFlowerStakedInOasis(uint256 flowerId)
        external
        view
        returns (bool)
    {
        return flowerStakeInfo[flowerId];
    }

    function isBeeStakedInOasis(uint256 beeId) external view returns (bool) {
        return beeStakeInfo[beeId];
    }

    function addOrEditLand(
        uint256 landId,
        uint256 price,
        uint256 reward
    ) external onlyOwner {
        OasisLand storage land = oasisLands[landId];

        // @dev Assuming new land
        if (land.price == 0) {
            oasisLandIds.push(landId);
        }

        land.price = uint256(price);
        land.reward = uint256(reward);
    }

    function airdropLands(
        address[] calldata recipients,
        uint256[] calldata ids
    ) external onlyOwner {
        require(recipients.length > 0, "No recipients set");
        require(recipients.length == ids.length, "Ids dont match recipients");

        for (uint i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 landId = ids[i];

            require(oasisLands[landId].price > 0, "No land exists with id");

            userToLandSpots[recipient][landId] += 1;
            oasisLandToSale[landId] += 1;
            if (userToLastClaimInteraction[recipient] == 0) {
                userToLastClaimInteraction[recipient] = block.timestamp;
            }
            _updateUserOasisProduction(recipient);

            emit BuyLand(recipient, landId, 1);
        }
    }

    function setShares(uint256 _marketing, uint256 _liquidity)
        external
        onlyAuthorized
    {
        shareMarketing = _marketing;
        shareLiquidity = _liquidity;
    }

    function setActionActive(bool _active) external onlyAuthorized {
        actionActive = _active;
    }

    function accumulateShares(uint256 amount) internal {
        taxActionCounter++;
        allocMarketing += (amount * shareMarketing) / 100;
        allocLiquidity += (amount * shareLiquidity) / 100;
    }

    function shouldTriggerMarketing() internal view returns (bool) {
        return
            (taxActionCounter + marketingActionTriggerOffset) %
                taxActionTriggerMark ==
            0 &&
            allocMarketing > 0 &&
            actionActive;
    }

    function shouldTriggerLiquidity() internal view returns (bool) {
        return
            (taxActionCounter + liquidityActionTriggerOffset) %
                taxActionTriggerMark ==
            0 &&
            allocLiquidity > 0 &&
            actionActive;
    }

    function triggerMarketing() internal {
        if (shouldTriggerMarketing()) {
            honeyCoinReserve.sendToMarketing(allocMarketing);
            allocMarketing = 0;
        }
    }

    function triggerLiquidity() internal {
        if (shouldTriggerLiquidity()) {
            honeyCoinReserve.sendToLiquidity(allocLiquidity);
            allocLiquidity = 0;
        }
    }

    function setAffiliate(address affiliate) external onlyOwner {
        flowerFamAffiliate = IFlowerFamAffliliate(affiliate);
    }

    function setAllocations(uint256 _marketing, uint256 _liquidity)
        external
        onlyOwner
    {
        allocMarketing = _marketing;
        allocLiquidity = _liquidity;
    }

    function setTaxActionTrigger(uint256 newTrigger) external onlyOwner {
        taxActionTriggerMark = newTrigger;
    }

    function setCounter(uint256 _counter) external onlyOwner {
        taxActionCounter = _counter;
    }

    function setOasisLandSupply(uint256 landId, uint256 supply)
        external
        onlyOwner
    {
        require(oasisLands[landId].price > 0, "No land exists with id");
        oasisLandToSupply[landId] = supply;
    }

    function _getStakedAssetReward(address user)
        internal
        view
        returns (uint256)
    {
        uint256 count = userAssetsCount[user];
        if (count == 0) return 0;
        if (count == 1) return 100;
        if (count < 4) return 200;
        if (count < 6) return 250;
        if (count < 8) return 300;
        if (count < 12) return 350;
        if (count >= 12) return 400;
        return 0 ether;
    }

    function _getOasisLandCountReward(uint256 count)
        internal
        pure
        returns (uint256)
    {
        if (count < 2) return 0;
        if (count < 4) return 10;
        if (count < 8) return 20;
        if (count < 10) return 30;
        if (count < 20) return 40;
        if (count < 30) return 60;
        if (count < 40) return 80;
        if (count < 50) return 100;
        if (count < 60) return 120;
        if (count < 69) return 140;
        if (count >= 69) return 169;
        return 0;
    }

    function _getLastClaimedBonusPercentage(address user)
        internal
        view
        returns (uint256)
    {
        if (userToLastClaimInteraction[user] == 0)
            return 0;

        uint256 userLastInteractionDiff = (block.timestamp -
            userToLastClaimInteraction[user]) / 1 days;

        if (userLastInteractionDiff < 4) return 0;
        if (userLastInteractionDiff < 7) return 30;
        if (userLastInteractionDiff < 14) return 50;
        if (userLastInteractionDiff < 30) return 80;
        if (userLastInteractionDiff < 60) return 100;
        if (userLastInteractionDiff < 90) return 120;
        if (userLastInteractionDiff < 120) return 160;
        if (userLastInteractionDiff >= 120) return 200;
        return 0;
    }

    function _getTotalProductionPerDay(address user)
        internal
        view
        returns (uint256)
    {
        uint256 amount = 0;
        uint256 rewardAmount = 0;
        uint256 totalLandCount = 0;

        for (uint256 i = 0; i < oasisLandIds.length; i++) {
            uint256 landId = oasisLandIds[i];
            uint256 landCount = userToLandSpots[user][landId];
            if (landCount > 0) {
                amount += uint256((landCount * oasisLands[landId].reward));
                totalLandCount += landCount;
            }
        }

        if (userAssetsCount[user] > 0) {
            // Adding staked asset reward
            rewardAmount += (amount * _getStakedAssetReward(user)) / 1000;
        }

        if (totalLandCount > 0) {
            // Adding oasis land reward
            rewardAmount +=
                (amount * _getOasisLandCountReward(totalLandCount)) /
                1000;
        }

        return amount + rewardAmount;
    }

    function _getNotAccumulatedProduction(
        uint256 lastAction,
        uint256 totalProductionPerDay
    ) internal view returns (uint256) {
        return
            ((block.timestamp - lastAction) * totalProductionPerDay) / 1 days;
    }

    function _getTotalProductionOfUser(address user)
        internal
        view
        returns (uint256)
    {
        UserOasisProduction memory userOasisProduction = userToProductionInfo[
            user
        ];

        uint256 claimAmount = _getNotAccumulatedProduction(
            userOasisProduction.lastAction,
            userOasisProduction.totalProductionPerDay
        ) + userOasisProduction.totalAccumulated;
        uint256 claimedAmount = userOasisProduction.totalClaimed;

        if (claimedAmount > claimAmount) claimAmount = 0;
        else claimAmount -= claimedAmount;

        return claimAmount;
    }

    function _updateUserOasisProduction(address user) internal {
        UserOasisProduction storage userOasisProduction = userToProductionInfo[
            user
        ];

        uint256 unAccumulated = _getNotAccumulatedProduction(
            userOasisProduction.lastAction,
            userOasisProduction.totalProductionPerDay
        );

        userOasisProduction.lastAction = uint32(block.timestamp);
        userOasisProduction.totalAccumulated += uint112(unAccumulated);
        userOasisProduction.totalProductionPerDay = uint112(
            _getTotalProductionPerDay(user)
        );

        emit UpdateTotalProductionPerDay(
            msg.sender,
            userOasisProduction.totalAccumulated,
            userOasisProduction.totalProductionPerDay
        );
    }

    function _applyAffiliate(uint256 price, address affiliate)
        internal
        returns (uint256)
    {
        if (
            affiliate != address(0) &&
            affiliate != msg.sender &&
            !flowerFamAffiliate.affiliateRegistration(msg.sender)
        ) {
            flowerFamAffiliate.setUserRegistered(msg.sender);

            uint256 bonus = (price * flowerFamAffiliate.affiliatePercentage()) /
                100;
            //honeyCoinReserve.releaseFunds(bonus, affiliate);
            flowerFamEcoSystem.addInternalBalance(affiliate, uint112(bonus));
            flowerFamAffiliate.registerAffiliate(affiliate, bonus);
            price =
                (price * (100 - flowerFamAffiliate.affiliateKickback())) /
                100;           
        }
        return price;
    }

    function _getClaimTaxAmount(uint256 claimAmount) internal view returns(uint256) {
        if (claimAmount <= 19 ether)
            return claimAmount / 100;
        else if (claimAmount <= 99 ether)
            return claimAmount / 50;
        else if (claimAmount <= 499 ether)
            return claimAmount / 25;
        else if (claimAmount <= 999 ether)
            return claimAmount * 6 / 100;
        else if (claimAmount <= 1999 ether)
            return claimAmount * 8 / 100;
        else
            return claimAmount * 10 / 100;
    }
   
    // VIEW functions

    function _getUserLandYield(uint256 landId, address user)
        internal
        view
        returns (uint256)
    {
        uint256 count = userToLandSpots[user][landId];
        return uint256(count * oasisLands[landId].reward);
    }

    function _getUserLandEarnings(uint256 landId, address user)
        internal
        view
        returns (uint256)
    {
        uint256 totalReward = 0;
        uint256 yield = _getUserLandYield(landId, user);
        uint256 count = userToLandSpots[user][landId];

        totalReward += (yield * _getStakedAssetReward(user)) / 1000;
        totalReward += (yield * _getOasisLandCountReward(count)) / 1000;

        return totalReward + yield;
    }
}
