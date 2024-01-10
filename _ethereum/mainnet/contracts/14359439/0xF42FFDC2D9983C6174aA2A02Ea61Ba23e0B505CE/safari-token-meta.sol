// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.5;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Strings.sol";
import "./Base64.sol";

import "./token-metadata.sol";

contract SafariTokenMeta is UUPSUpgradeable, OwnableUpgradeable {
    using SafariToken for SafariToken.Metadata;
    using Strings for uint256;

    struct TraitInfo {
        uint16 weight;
        uint16 end;
	bytes28 name;
    }

    struct PartInfo {
        uint8 fieldSize;
        uint8 fieldOffset;
        bytes28 name;
    }

    PartInfo[] public partInfo;

    mapping(uint256 => TraitInfo[]) public partTraitInfo;

    struct PartCombo {
        uint8 part1;
        uint8 trait1;
        uint8 part2;
	uint8 traits2Len;
        uint8[28] traits2;
    }

    PartCombo[] public mandatoryCombos;
    PartCombo[] public forbiddenCombos;

    function initialize() public initializer {
      __Ownable_init_unchained();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


    function buildSpecial(uint256[] calldata traits) external view returns(bytes32) {
        require(traits.length == partInfo.length, string(abi.encodePacked('need ', partInfo.length.toString(), ' elements')));
        SafariToken.Metadata memory newData;
	PartInfo storage _partInfo;
        uint256 i;
        for (i=0; i<partInfo.length; i++) {
            _partInfo = partInfo[i];
            newData.setProperty(_partInfo.fieldOffset, _partInfo.fieldSize, traits[i]);
        }
	return newData._value;
    }

    function setMandatoryCombos(uint256[] calldata parts1, uint256[] calldata traits1, uint256[] calldata parts2, uint256[][] calldata traits2) external onlyOwner {
        require(parts1.length == traits1.length && parts1.length == parts2.length && parts1.length == traits2.length, 'all arguments must be arrays of the same length');

        delete mandatoryCombos;

        uint256 i;
        for (i=0; i<parts1.length; i++) {
            addMandatoryCombo(parts1[i], traits1[i], parts2[i], traits2[i][0]);
        }
    }

    function addMandatoryCombo(uint256 part1, uint256 trait1, uint256 part2, uint256 trait2) internal {
        mandatoryCombos.push();
        PartCombo storage combo = mandatoryCombos[mandatoryCombos.length-1];
        combo.part1 = uint8(part1);
        combo.trait1 = uint8(trait1);
        combo.part2 = uint8(part2);
	combo.traits2Len = uint8(1);
        combo.traits2[0] = uint8(trait2);
    }

    // this should only be used to correct errors in trait names
    function setPartTraitNames(uint256[] calldata parts, uint256[] calldata traits, string[] memory names) external onlyOwner {
        require(parts.length == traits.length && parts.length == names.length, 'all arguments must be arrays of the same length');
        uint256 i;
        for (i=0; i<parts.length; i++) {
            require(partTraitInfo[parts[i]].length > traits[i], 'you tried to set the name of a property that does not exist');
            partTraitInfo[parts[i]][traits[i]].name = stringToBytes28(names[i]);
        }
    }

    // set the odds of getting a trait. dividing the weight of a trait by the sum of all trait weights yields the odds of minting that trait
    function setPartTraitWeights(uint256[] calldata parts, uint256[] calldata traits, uint256[] calldata weights) external onlyOwner {
        require(parts.length == traits.length && parts.length == weights.length, 'all arguments must be arrays of the same length');
        uint256 i;
        for (i=0; i<parts.length; i++) {
            require(partTraitInfo[parts[i]].length < traits[i], 'you tried to set the odds of a property that does not exist');
            partTraitInfo[parts[i]][traits[i]].weight = uint16(weights[i]);
        }
	_updatePartTraitWeightRanges();
    }

    // after trait weights are changed this runs to update the ranges
    function _updatePartTraitWeightRanges() internal {
        uint256 offset;
        TraitInfo storage traitInfo;

        uint256 i;
        uint256 j;
        for (i=0; i<partInfo.length; i++) {
            offset = 0;
            for (j=0; j<partTraitInfo[i].length; j++) {
                traitInfo = partTraitInfo[i][j];
                offset += traitInfo.weight;
		traitInfo.end = uint16(offset);
            }
        }
    }

    function addPartTraits(uint256[] calldata parts, uint256[] calldata weights, string[] calldata names) external onlyOwner {
        require(parts.length == weights.length && parts.length == names.length, 'all arguments must be arrays of the same length');
        uint256 i;
        for (i=0; i<parts.length; i++) {
            _addPartTrait(parts[i], weights[i], names[i]);
        }
	_updatePartTraitWeightRanges();
    }

    function _addPartTrait(uint256 part, uint256 weight, string calldata name) internal {
	TraitInfo memory traitInfo;

	traitInfo.weight = uint16(weight);
	traitInfo.name = stringToBytes28(name);

	partTraitInfo[part].push(traitInfo);
    }

    function addParts(uint256[] calldata fieldSizes, string[] calldata names) external onlyOwner {
        require(fieldSizes.length == names.length, 'all arguments must be arrays of the same length');

        PartInfo memory _partInfo;
        uint256 fieldOffset;
        if (partInfo.length > 0) {
            _partInfo = partInfo[partInfo.length-1];
            fieldOffset = _partInfo.fieldOffset + _partInfo.fieldSize;
        }

        uint256 i;
        for (i=0; i<fieldSizes.length; i++) {
            _partInfo.name = stringToBytes28(names[i]);   
	    _partInfo.fieldOffset = uint8(fieldOffset);
            _partInfo.fieldSize = uint8(fieldSizes[i]);
            partInfo.push(_partInfo);
            fieldOffset += fieldSizes[i];
        }
    }

    function getMeta(SafariToken.Metadata memory tokenMeta, uint256 tokenId, string memory baseURL) external view returns(string memory) {
        bytes memory metaStr = abi.encodePacked(
            '{',
                '"name":"SafariBattle #', tokenId.toString(), '",',
		'"image":"', baseURL, _getSpecificURLPart(tokenMeta), '",',
		'"attributes":[', _getAttributes(tokenMeta), ']'
            '}'
        );
	return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metaStr)
            )
        );
    }

    function _getSpecificURLPart(SafariToken.Metadata memory tokenMeta) internal view returns(string memory) {
        bytes memory result = abi.encodePacked('?');
	PartInfo storage _partInfo;

        bool isFirst = true;

        uint256 i;
        for (i=0; i<partInfo.length; i++) {
	    if (!isFirst) {
                result = abi.encodePacked(result, '&');
            }
	    isFirst = false;

            _partInfo = partInfo[i];

            result = abi.encodePacked(
                result, bytes28ToString(_partInfo.name),
                '=',
                bytes28ToString(partTraitInfo[i][tokenMeta.getProperty(_partInfo.fieldOffset, _partInfo.fieldSize)].name)
            );
        }

	return string(result);
    }

    function _getAttributes(SafariToken.Metadata memory tokenMeta) internal view returns(string memory) {
        bytes memory result;

	PartInfo storage _partInfo;

        bool isFirst = true;
        string memory traitValue;

        uint256 i;
        for (i=0; i<partInfo.length; i++) {
            _partInfo = partInfo[i];
            traitValue = bytes28ToString(partTraitInfo[i][tokenMeta.getProperty(_partInfo.fieldOffset, _partInfo.fieldSize)].name);

            if (bytes(traitValue).length == 0) {
                continue;
            }

            if (!isFirst) {
                result = abi.encodePacked(result, ',');
            }
	    isFirst = false;

            result = abi.encodePacked(
                result,
		'{',
		    '"trait_type":"', bytes28ToString(_partInfo.name), '",',
                    '"value":"', traitValue, '"',
                '}'
            );
        }
	return string(result);
    }

    function generateProperties(uint256 randomVal, uint256 tokenId) external view returns(SafariToken.Metadata memory) {
        SafariToken.Metadata memory newData;
	PartInfo storage _partInfo;

        uint256 trait;

        uint256 i;
        for (i=0; i<partInfo.length; i++) {
            _partInfo = partInfo[i];
            trait = genPart(i, randomVal);
            newData.setProperty(_partInfo.fieldOffset, _partInfo.fieldSize, trait);
            randomVal >>= 8;
        }

        PartCombo storage combo;

        for (i=0; i<mandatoryCombos.length; i++) {
            combo = mandatoryCombos[i];
            _partInfo = partInfo[combo.part1];
            if (newData.getProperty(_partInfo.fieldOffset, _partInfo.fieldSize) != combo.trait1) {
                continue;
            }
            _partInfo = partInfo[combo.part2];
            if (newData.getProperty(_partInfo.fieldOffset, _partInfo.fieldSize) != combo.traits2[0]) {
                newData.setProperty(_partInfo.fieldOffset, _partInfo.fieldSize, combo.traits2[0]);
            }
        }

        uint256 j;
        bool bad;

        for (i=0; i<forbiddenCombos.length; i++) {
            combo = forbiddenCombos[i];

            _partInfo = partInfo[combo.part1];
            if (newData.getProperty(_partInfo.fieldOffset, _partInfo.fieldSize) != combo.trait1) {
                continue;
            }

            _partInfo = partInfo[combo.part2];

            trait = newData.getProperty(_partInfo.fieldOffset, _partInfo.fieldSize);

	    // generate a new trait until one is found that doesn't conflict
            while (true) {
                bad = false;
                for (j=0; j<combo.traits2.length; j++) {
                    if (trait == combo.traits2[i]) {
                        bad = true;
                        break;
                    }
                }
                if (!bad) {
                    break;
                }
                trait = genPart(combo.part2, randomVal);
                newData.setProperty(_partInfo.fieldOffset, _partInfo.fieldSize, trait);
                randomVal >>= 8;
            }
        }

        return newData;
    }

    function genPart(uint256 part, uint256 randomVal) internal view returns(uint256) {
        TraitInfo storage traitInfo;

	traitInfo = partTraitInfo[part][partTraitInfo[part].length-1];
	uint256 partTotalWeight = traitInfo.end;

        uint256 selected = randomVal % partTotalWeight;

	uint256 start = 0;
        uint256 i;
	for (i=0; i<partTraitInfo[part].length; i++) {
            traitInfo = partTraitInfo[part][i];
	    if (selected >= start && selected < traitInfo.end) {
                return i;
            }
	    start = traitInfo.end;
        }
	require(false, string(abi.encodePacked('did not find a trait: part: ', part.toString(), ', total weight: ', partTotalWeight.toString(), ', selected: ', selected.toString())));
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a <= b ? a : b;
    }

    function bytes28ToString(bytes28 _bytes28) public pure returns (string memory) {
        uint256 i = 0;
        // find the end of the string
        while(i < 28 && _bytes28[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 28 && _bytes28[i] != 0; i++) {
            bytesArray[i] = _bytes28[i];
        }
        return string(bytesArray);
    }

    function stringToBytes28(string memory _string) public pure returns (bytes28) {
        bytes28 _bytes28;
        bytes memory bytesArray = bytes(_string);
	
        require(bytesArray.length <= 28, 'string is longer than 28 bytes');

        uint256 i = 0;
        for (i = 0; i<bytesArray.length; i++) {
            _bytes28 |= bytes28(bytesArray[i]) >> (i*8);
        }
        return _bytes28;
    }
}
