// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./Strings.sol";
import "./IHoody.sol";

contract HoodyTraits is IHoody, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Attribute {
        uint8 id;
        string name;
    }

    struct Trait {
        uint8 attrID;
        bool onStore;
        HoodyTraitRarity rarity;
    }

    address public hoodyGang;
    address public hoodyTraitsMarketplace;

    uint8 public pointForCommon = 4;
    uint8 public pointForRare = 20;
    uint8 public pointForLegendary = 40;

    uint8 totalAttributeNumber;
    uint16 totalTraitsNumber;

    mapping(uint8 => Attribute) public attributes;
    mapping(uint16 => Trait) public traits;
    mapping(uint8 => EnumerableSet.UintSet) storeTraitsByAttribute;
    mapping(HoodyTraitRarity => uint8) public traitPointByRarity;

    mapping(address => mapping(uint16 => uint16)) public traitAmountByHolder;
    mapping(uint16 => uint16) public traitAmountOnStore;
    mapping(uint16 => uint256) public traitPriceOnStore;
    mapping(address => EnumerableSet.UintSet) traitsByHolder;

    modifier onlyMarketplace() {
        require(
            msg.sender == hoodyTraitsMarketplace,
            "Only Marketplace can call this function."
        );
        _;
    }

    modifier onlyHoodyGang() {
        require(
            msg.sender == hoodyGang,
            "Only HoodyGang contract can call this function."
        );
        _;
    }

    event NewAttribute(uint8 indexed attrID, string attrName);

    event NewTrait(
        uint16 indexed traitID,
        uint8 attrID,
        string name,
        HoodyTraitRarity rarity
    );

    event BuyTraitFromStore(
        address buyer,
        uint16 indexed traitID,
        uint16 amount
    );

    event UpdateNFT(address holder, uint16[] oldTraits, uint16[] newTraits);

    event TraitRemoved(uint16 traitID);

    event TraitIncreased(uint16 traitID, uint8 amount);

    constructor() Ownable(msg.sender) {}

    function addAttributes(string[] memory _attrNames) external onlyOwner {
        for (uint i; i < _attrNames.length; i++) {
            totalAttributeNumber++;
            attributes[totalAttributeNumber] = Attribute(
                totalAttributeNumber,
                _attrNames[i]
            );
            emit NewAttribute(totalAttributeNumber, _attrNames[i]);
        }
    }

    function addMintTraits(
        uint8 _attrID,
        string[] memory _traitNames,
        HoodyTraitRarity[] memory _traitRarities
    ) public onlyOwner {
        require(
            _traitNames.length == _traitRarities.length,
            "Invalid Param Counts!"
        );
        for (uint i; i < _traitNames.length; i++) {
            totalTraitsNumber++;
            addTrait(
                _attrID,
                totalTraitsNumber,
                _traitNames[i],
                false,
                _traitRarities[i]
            );
        }
    }

    function addStoreTraits(
        uint8 _attrID,
        string[] memory _traitNames,
        HoodyTraitRarity[] memory _traitRarities,
        uint256[] memory _traitPrices,
        uint16[] memory _traitAmounts
    ) public onlyOwner {
        require(_traitNames.length == _traitRarities.length, "Invalid Params!");
        require(_traitNames.length == _traitAmounts.length, "Invalid Params!");
        require(_traitNames.length == _traitPrices.length, "Invalid Params!");

        for (uint i; i < _traitNames.length; i++) {
            totalTraitsNumber++;
            addTrait(
                _attrID,
                totalTraitsNumber,
                _traitNames[i],
                true,
                _traitRarities[i]
            );
            traitAmountOnStore[totalTraitsNumber] = _traitAmounts[i];
            traitPriceOnStore[totalTraitsNumber] = _traitPrices[i];
            storeTraitsByAttribute[_attrID].add(totalTraitsNumber);
        }
    }

    function addTrait(
        uint8 _attrID,
        uint16 _traitID,
        string memory _name,
        bool _onStore,
        HoodyTraitRarity _traitRarity
    ) internal {
        traits[_traitID] = Trait(_attrID, _onStore, _traitRarity);
        emit NewTrait(_traitID, _attrID, _name, _traitRarity);
    }

    function getNFTRarity(
        uint16[] memory _traits
    ) external view returns (HoodyGangRarity rarity) {
        uint8 point = 0;
        point = getTotalPointOfTraits(_traits);
        if (point >= pointForLegendary) rarity = HoodyGangRarity.Legendary;
        else if (point >= pointForRare) rarity = HoodyGangRarity.Rare;
        else rarity = HoodyGangRarity.Common;
    }

    function increaseStoreTraitAmount(
        uint16 _traitID,
        uint8 _amount
    ) public onlyOwner {
        require(_traitID <= totalTraitsNumber, "Invalid Trait!");
        traitAmountOnStore[_traitID] += _amount;
        emit TraitIncreased(_traitID, _amount);
    }

    function removeStoreTrait(uint16 _traitID) external onlyOwner {
        require(_traitID <= totalTraitsNumber, "Invalid Trait!");
        traitAmountOnStore[_traitID] = 0;
        emit TraitRemoved(_traitID);
    }

    function setTraitPointsByRarity(
        HoodyTraitRarity[] memory _rarities,
        uint8[] memory _points
    ) external onlyOwner {
        require(_rarities.length == _points.length, "Invalid Param!");
        for (uint i; i < _rarities.length; i++) {
            traitPointByRarity[_rarities[i]] = _points[i];
        }
    }

    function setNFTRarityPoints(
        uint8 _common,
        uint8 _rare,
        uint8 _legendary
    ) external onlyOwner {
        pointForCommon = _common;
        pointForRare = _rare;
        pointForLegendary = _legendary;
    }

    function buyTraitsFromStore(
        uint16[] memory _traits,
        uint16[] memory _amounts
    ) external payable {
        require(_traits.length == _amounts.length, "Invalid param count.");
        uint256 totalPrice;
        for (uint256 i; i < _traits.length; i++) {
            totalPrice += traitPriceOnStore[_traits[i]] * _amounts[i];
        }
        require(msg.value == totalPrice, "Not enough eth amount.");

        for (uint256 i; i < _traits.length; i++) {
            require(
                traitAmountOnStore[_traits[i]] >= _amounts[i],
                "Not enough amount in store!"
            );
            traitAmountByHolder[msg.sender][_traits[i]] += _amounts[i];
            traitAmountOnStore[_traits[i]] -= _amounts[i];
            traitsByHolder[msg.sender].add(_traits[i]);

            emit BuyTraitFromStore(msg.sender, _traits[i], _amounts[i]);
        }
    }

    function buyTraitFromMarketplace(
        uint16 _traitId,
        uint16 _amount
    ) external onlyMarketplace {
        traitAmountByHolder[tx.origin][_traitId] += _amount;
        traitsByHolder[tx.origin].add(_traitId);
    }

    function downTraitsFromMarketplace(
        uint16 _traitId,
        uint16 _amount
    ) external onlyMarketplace {
        traitAmountByHolder[tx.origin][_traitId] += _amount;
    }

    function listTraitsToMarketplace(
        uint16 _traitId,
        uint16 _amount
    ) external onlyMarketplace {
        require(
            traitAmountByHolder[tx.origin][_traitId] >= _amount,
            "Not enough Traits"
        );
        traitAmountByHolder[tx.origin][_traitId] -= _amount;
    }

    function useTraitsForUpdateNFT(
        uint16[] memory _originTraits,
        uint16[] memory _newTraits
    ) external onlyHoodyGang {
        for (uint256 i; i < _originTraits.length; i++) {
            traitAmountByHolder[tx.origin][_originTraits[i]]++;
        }
        for (uint256 i; i < _newTraits.length; i++) {
            require(
                traitAmountByHolder[tx.origin][_newTraits[i]] > 0,
                "You don't have that traits."
            );
            traitAmountByHolder[tx.origin][_newTraits[i]]--;
            if (traitAmountByHolder[tx.origin][_newTraits[i]] == 0) {
                traitsByHolder[tx.origin].remove(_newTraits[i]);
            }
        }

        emit UpdateNFT(tx.origin, _originTraits, _newTraits);
    }

    function getTraitsByHolder(
        address _holder
    ) external view returns (Trait[] memory) {
        uint256 traitsCount = traitsByHolder[_holder].length();
        Trait[] memory traitsList = new Trait[](traitsCount);
        for (uint256 i; i < traitsCount; i++) {
            traitsList[i] = traits[uint16(traitsByHolder[_holder].at(i))];
        }
        return traitsList;
    }

    function getTotalPointOfTraits(
        uint16[] memory _traits
    ) public view returns (uint8 points) {
        for (uint256 i; i < _traits.length; i++) {
            points += traitPointByRarity[traits[_traits[i]].rarity];
        }
        return points;
    }

    function withdrawFee(address payable _receiver) external onlyOwner {
        _receiver.transfer(address(this).balance);
    }

    function setHoodyGang(address _hoodyGang) external onlyOwner {
        hoodyGang = _hoodyGang;
    }

    function setHoodyTraitsMarketplace(
        address _hoodyTraitsMarketplace
    ) external onlyOwner {
        hoodyTraitsMarketplace = _hoodyTraitsMarketplace;
    }
}
