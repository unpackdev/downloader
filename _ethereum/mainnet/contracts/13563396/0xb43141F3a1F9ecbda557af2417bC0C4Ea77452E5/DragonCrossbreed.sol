// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./Address.sol";
import "./BaseAuctionReceiver.sol";
import "./DragonInfo.sol";
import "./GenesLib.sol";
import "./Random.sol";
import "./DragonCreator.sol";
import "./DragonToken.sol";

contract DragonCrossbreed is BaseAuctionReceiver {

    using Address for address payable;

    uint constant HOURS_MAX_PERIOD = 24 * 100; //100 days
    uint constant THRESHOLD_DENOMINATOR = 100*1e8;

    uint[10] private _platformPrices;
    uint[10] private _bonusesCommonThresholds;
    uint[5] private _probabilityRareThresholds;
    uint[5] private _probabilityEpicThresholds;

    address private _dragonCreatorAddress;
    address private _dragonRandomnessAddress;

    mapping(address => uint) private _rewards;

    GenesLib.GenesRange private COMMON_RANGE;
    GenesLib.GenesRange private RARE_RANGE;
    GenesLib.GenesRange private EPIC_RANGE;

    event RewardAdded(address indexed operator, address indexed to, uint amount);
    event RewardClaimed(address indexed claimer, address indexed to, uint amount);

    constructor(
        address accessControl, 
        address dragonToken, 
        address dragonCreator, 
        uint fees100) BaseAuctionReceiver(accessControl, dragonToken, fees100) {
            
        _dragonCreatorAddress = dragonCreator;

        _platformPrices = [
            3*1e15, 5*1e15, 8*1e15, 10*1e15, 15*1e15, 
            20*1e15, 25*1e15, 30*1e15, 35*1e15, 40*1e15
        ];
        _bonusesCommonThresholds = [
            1953125, 3906250, 7812500, 15625000, 31250000,
            62500000, 125000000, 250000000, 500000000, 1000000000
        ];
        _probabilityRareThresholds = [1000000000, 500000000, 250000000, 125000000, 62500000];
        _probabilityEpicThresholds = [0, 15625000, 7812500, 3906250, 1953125];

        COMMON_RANGE = GenesLib.GenesRange({from: 0, to: 15});
        RARE_RANGE = GenesLib.GenesRange({from: 15, to: 20});
        EPIC_RANGE = GenesLib.GenesRange({from: 20, to: 25});
    }

    function maxTotalPeriod() internal override virtual pure returns (uint) {
        return HOURS_MAX_PERIOD;
    }

    function numOfPriceChangesPerHour() internal override virtual pure returns (uint) {
        return 30;
    }

    function dragonCreatorAddress() public view returns (address) {
        return _dragonCreatorAddress;
    }

    function setDragonCreatorAddress(address newAddress) external onlyRole(CEO_ROLE) {
        address previousAddress = _dragonCreatorAddress;
        _dragonCreatorAddress = newAddress;
        emit AddressChanged("dragonCreator", previousAddress, newAddress);
    }

    function platformPrice(uint genesCount) public view returns (uint) {
        return _platformPrices[genesCount];
    }

    function setPlatformPrices(uint[10] calldata newPlatformPrices) external onlyRole(CFO_ROLE) {
        _platformPrices = newPlatformPrices;
    }

    function bonusCommonThresholdAt(uint index) external view returns (uint) {
        return _bonusesCommonThresholds[index];
    } 

    function setBonusCommonThreshold(uint[10] calldata newBonusesCommonThresholds) external onlyRole(CFO_ROLE) {
        _bonusesCommonThresholds = newBonusesCommonThresholds;
    }

    function probabilityRareThresholdAt(uint index) external view returns (uint) {
        return _probabilityRareThresholds[index];
    } 

    function setProbabilityRareThreshold(uint[5] calldata newProbabilityRareThresholds) external onlyRole(CFO_ROLE) {
        _probabilityRareThresholds = newProbabilityRareThresholds;
    }

    function probabilityEpicThresholdAt(uint index) external view returns (uint) {
        return _probabilityEpicThresholds[index];
    } 

    function setProbabilityEpicThreshold(uint[5] calldata newProbabilityEpicThresholds) external onlyRole(CFO_ROLE) {
        _probabilityEpicThresholds = newProbabilityEpicThresholds;
    }

    function crossbreedPlatformPrice(uint dragon1Id, uint dragon2Id) external view returns (uint) {
        DragonToken dragonToken = DragonToken(tokenContract());
        uint genes1 = dragonToken.dragonInfo(dragon1Id).genes;
        uint genes2 = dragonToken.dragonInfo(dragon2Id).genes;
        (uint countRare, uint countEpic) = calcCommonRareEpicGenesCount(genes1, genes2);
        return platformPrice(countRare + countEpic);
    }

    function calcCommonRareEpicGenesCount(uint genes1, uint genes2) internal pure returns (uint, uint) {
        uint mask = DragonInfo.MASK;
        
        uint countRare = 0;
        uint countEpic = 0;

        for (uint i = 0; i < 10; i++) { //just Epic and Rare genes are important to count
            if (genes1 & mask > 0 && genes2 & mask > 0) {
                if (i < 5) {
                    countEpic++;
                }
                else {
                    countRare++;
                }
            }
            mask = mask >> 4;
        }
        return (countRare, countEpic);
    }

    function processERC721(address operator, address from, uint tokenId, bytes calldata data) 
        internal virtual override {
        DragonInfo.Details memory info = DragonToken(tokenContract()).dragonInfo(tokenId);
        require(info.dragonType != DragonInfo.Types.Legendary, "DragonCrossbreed: the dragon cannot be a Legendary-type");
        super.processERC721(operator, from, tokenId, data);
    }

    function breed(uint myDragonId, uint anotherDragonId, uint salt) external payable {
        DragonToken dragonToken = DragonToken(tokenContract());

        require(
            dragonToken.ownerOf(myDragonId) == _msgSender(), 
            "DragonCrossbreed: the caller is not an owner of the dragon"
        );
        require(
            isLocked(anotherDragonId) || dragonToken.ownerOf(anotherDragonId) == _msgSender(), 
            "DragonCrossbreed: another dragon is not locked nor doesn't belong to the caller"
        );

        DragonInfo.Details memory parent1 = dragonToken.dragonInfo(myDragonId);
        DragonInfo.Details memory parent2 = dragonToken.dragonInfo(anotherDragonId);

        (uint countRare, uint countEpic) = calcCommonRareEpicGenesCount(parent1.genes, parent2.genes);
        uint _platformPrice = platformPrice(countRare + countEpic);
        uint _rentPrice = 0;
        if (isLocked(anotherDragonId)) {
            _rentPrice = priceOf(anotherDragonId);
        }
        require(msg.value >= (_platformPrice + _rentPrice), "DragonCrossbreed: incorrect amount sent to the contract");
        
        uint newGenes = 0;
        uint randomValue = Random.rand(salt);
        uint derivedRandomValue = Random.rand(randomValue ^ salt ^ block.difficulty);
        if (parent1.dragonType == DragonInfo.Types.Common && parent2.dragonType == DragonInfo.Types.Common) {
            (uint y, uint z) = _randomCountOfNewRareEpic(randomValue);
            if (y > 0) {
                uint[] memory positions = GenesLib.randomGenePositions(RARE_RANGE, y, randomValue);
                newGenes = GenesLib.randomSetGenesToPositions(newGenes, positions, randomValue, false);
            }
            if (z > 0) {
                uint[] memory positions = GenesLib.randomGenePositions(EPIC_RANGE, z, randomValue);
                newGenes = GenesLib.randomSetGenesToPositions(newGenes, positions, randomValue, false);
            }
            if (newGenes == 0 && _randomNewRare(0, derivedRandomValue)) { //if the bonuses above were not triggered
                uint[] memory positions = GenesLib.randomGenePositions(RARE_RANGE, 1, derivedRandomValue);
                newGenes = GenesLib.randomSetGenesToPositions(newGenes, positions, derivedRandomValue, false);
            }
            newGenes = GenesLib.randomInheritGenesInRange(newGenes, parent1.genes, parent2.genes, COMMON_RANGE, randomValue, true);
        }
        else if (parent1.dragonType == DragonInfo.Types.Epic20 && parent2.dragonType == DragonInfo.Types.Epic20) {
            //add Epic gene
            uint[] memory positions = GenesLib.randomGenePositions(EPIC_RANGE, 1, randomValue);
            newGenes = GenesLib.randomSetGenesToPositions(newGenes, positions, randomValue, false);
            //inherit Common
            newGenes = GenesLib.randomInheritGenesInRange(newGenes, parent1.genes, parent2.genes, COMMON_RANGE, randomValue, true);
            //inherit Rare
            newGenes = GenesLib.randomInheritGenesInRange(newGenes, parent1.genes, parent2.genes, RARE_RANGE, randomValue, false);
        }
        else {
            //inherit Common
            newGenes = GenesLib.randomInheritGenesInRange(newGenes, parent1.genes, parent2.genes, COMMON_RANGE, randomValue, true);
            //inherit Rare
            newGenes = GenesLib.randomInheritGenesInRange(newGenes, parent1.genes, parent2.genes, RARE_RANGE, randomValue, false);
            //inherit Epic
            newGenes = GenesLib.randomInheritGenesInRange(newGenes, parent1.genes, parent2.genes, EPIC_RANGE, randomValue, false);

            if (countRare < 5 && _randomNewRare(countRare, randomValue)) {
                (uint count, uint[] memory positions) = GenesLib.zeroGenePositionsInRange(newGenes, RARE_RANGE);
                uint pos = Random.randFrom(positions, 0, count, derivedRandomValue);
                newGenes = GenesLib.setGeneLevelTo(newGenes, GenesLib.randomGeneLevel(derivedRandomValue, false), pos);
            }
            else if (countRare == 5 && countEpic < 5 && _randomNewEpic(countEpic, randomValue)) {
                (uint count, uint[] memory positions) = GenesLib.zeroGenePositionsInRange(newGenes, EPIC_RANGE);
                uint pos = Random.randFrom(positions, 0, count, derivedRandomValue);
                newGenes = GenesLib.setGeneLevelTo(newGenes, GenesLib.randomGeneLevel(derivedRandomValue, false), pos);
            }
        }

        if (_rentPrice > 0) {
            payable(holderOf(anotherDragonId))
                .sendValue(_rentPrice - calcFees(_rentPrice, feesPercent()));
        }
        DragonCreator(dragonCreatorAddress()).giveBirth(myDragonId, anotherDragonId, newGenes, _msgSender());
    }

    function addReward(address to, uint amount) external onlyRole(COO_ROLE) {
        require(!Address.isContract(to), "DragonCrossbreed: address cannot be contract");
        _rewards[to] += amount;
        emit RewardAdded(_msgSender(), to, amount);
    }

    function claimReward(address payable to, uint amount) external {
        require(!Address.isContract(to), "DragonCrossbreed: address cannot be contract");
        require(amount <= _rewards[_msgSender()], "DragonCrossbreed: the given amount exceeded the allowed reward");
        
        to.sendValue(amount);
        _rewards[_msgSender()] -= amount;

        emit RewardClaimed(_msgSender(), to, amount);
    }

    function _randomCountOfNewRareEpic(uint randomValue) internal view returns (uint, uint) {
        uint r = randomValue % THRESHOLD_DENOMINATOR;
        return 
            (r <= _bonusesCommonThresholds[0]) ? (5, 5) :
            (r <= _bonusesCommonThresholds[1]) ? (5, 4) :
            (r <= _bonusesCommonThresholds[2]) ? (5, 3) :
            (r <= _bonusesCommonThresholds[3]) ? (5, 2) :
            (r <= _bonusesCommonThresholds[4]) ? (5, 1) :
            (r <= _bonusesCommonThresholds[5]) ? (5, 0) :
            (r <= _bonusesCommonThresholds[6]) ? (4, 0) :
            (r <= _bonusesCommonThresholds[7]) ? (3, 0) :
            (r <= _bonusesCommonThresholds[8]) ? (2, 0) :
            (r <= _bonusesCommonThresholds[9]) ? (1, 0) :
            (0, 0);
    }

    function _randomNewRare(uint currentRareCount, uint randomValue) internal view returns (bool) {
        uint r = randomValue % THRESHOLD_DENOMINATOR;
        return r < _probabilityRareThresholds[currentRareCount];
    }

    function _randomNewEpic(uint currentEpicCount, uint randomValue) internal view returns (bool) {
        uint r = randomValue % THRESHOLD_DENOMINATOR;
        return r < _probabilityEpicThresholds[currentEpicCount];
    }
}