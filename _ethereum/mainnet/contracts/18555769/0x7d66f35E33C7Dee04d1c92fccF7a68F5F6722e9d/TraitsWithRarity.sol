// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./console.sol";

contract TraitsWithRarity {
    struct TokenTrait {
        uint16 rarityIndex;
        uint256 valueIndex;
        string traitName;
        string traitKey;
        string valueName;
    }

    struct TraitValue {
        uint256 rarity;
        string name;
    }

    uint16 internal _rarityIndexSize;
    uint16 internal _traitCount;
    mapping(string => TraitValue[]) internal _traitValues;
    mapping(string => string) internal _traitNames;
    mapping(string => uint8) internal _traitOffset;
    mapping(uint16 => string) internal _traitKeys;

    constructor(uint16 __rarityIndexSize) {
        _rarityIndexSize = __rarityIndexSize;
    }

    function traitValueIndexOf(string memory traitKey, uint16 rarityIndex) public view returns (uint256 index) {
        require(rarityIndex < _rarityIndexSize, "Rarity index out of bounds");
        require(_traitValues[traitKey].length > 0, "Trait not found");

        uint256 cumulatedRarity = 0;
        uint256 _index = 0;

        do {
            cumulatedRarity += _traitValues[traitKey][_index].rarity;
            _index++;
        } while (rarityIndex >= cumulatedRarity && _index < _traitValues[traitKey].length);

        return _index - 1;
    }

    function traitRarityIndexOf(string memory traitKey, uint256 tokenHash) public view returns (uint16 rarityIndex) {
        uint16 __traitOffset = _traitOffset[traitKey];
        return uint16((tokenHash >> __traitOffset) % _rarityIndexSize);
    }

    function getTraitKeys() public view returns (string[] memory) {
        string[] memory keys = new string[](_traitCount);
        for (uint16 i = 0; i < _traitCount;) {
            keys[i] = _traitKeys[i];

            unchecked { i++; }
        }
        return keys;
    }

    function getTrait(string memory traitKey, uint256 tokenHash) public view returns (TokenTrait memory tokenTrait) {
        uint16 __rarityIndex = traitRarityIndexOf(traitKey, tokenHash);
        uint256 _valueIndex = traitValueIndexOf(traitKey, __rarityIndex);

        return TokenTrait({
            rarityIndex: __rarityIndex,
            valueIndex: _valueIndex,
            traitKey: traitKey,
            traitName: _traitNames[traitKey],
            valueName: _traitValues[traitKey][_valueIndex].name
        });
    }

    function _initTrait(string memory key, string memory name, uint8 offset) internal returns (TraitValue[] storage) {
        _traitNames[key] = name;
        _traitOffset[key] = offset;
        _traitKeys[_traitCount] = key;
        ++_traitCount;
        return _traitValues[key];
    }

    function _getTraitAsERC721JsonProperty(string memory traitKey, uint256 tokenHash)
        internal
        view
        returns (string memory)
    {
        TokenTrait memory trait = getTrait(traitKey, tokenHash);
        return string(
            abi.encodePacked("{\"trait_type\":\"", trait.traitName, "\",", "\"value\":\"", trait.valueName, "\"}")
        );
    }
}
