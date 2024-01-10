// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

uint8 constant MIN_ALPHA = 5;
uint8 constant MAX_ALPHA = 8;

uint8 constant POACHER = 1;
uint8 constant ANIMAL = 2;
uint8 constant APR = 3;

uint8 constant RHINO = 0;
uint8 constant CHEETAH = 1;

uint8 constant propertiesStart = 128;
uint8 constant propertiesSize = 128;

library SafariToken {
    // struct to store each token's traits
    struct Metadata {
        bytes32 _value;
    }

    function create(bytes32 raw) internal pure returns(Metadata memory) {
        Metadata memory meta = Metadata(raw);
	return meta;
    }

    function getCharacterType(Metadata memory meta) internal pure returns(uint8) {
        return uint8(bytes1(meta._value));
    }

    function setCharacterType(Metadata memory meta, uint8 characterType) internal pure {
        meta._value = (meta._value & 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | (bytes32(bytes1(characterType)));
    }

    function getAlpha(Metadata memory meta) internal pure returns(uint8) {
        return uint8(bytes1(meta._value << (8*1)));
    }

    function setAlpha(Metadata memory meta, uint8 alpha) internal pure {
        meta._value = (meta._value & 0xff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | (bytes32(bytes1(alpha)) >> (8*1));
    }

    function getCharacterSubtype(Metadata memory meta) internal pure returns(uint8) {
        return uint8(bytes1(meta._value << (8*2)));
    }

    function setCharacterSubtype(Metadata memory meta, uint8 subType) internal pure {
        meta._value = (meta._value & 0xffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | (bytes32(bytes1(subType)) >> (8*2));
    }

    function isSpecial(Metadata memory meta) internal pure returns(bool) {
        return bool(uint8(bytes1(meta._value << (8*3) & bytes1(0x01))) == 0x01);
    }

    function setSpecial(Metadata memory meta, bool _isSpecial) internal pure {
        bytes1 specialVal = bytes1(_isSpecial ? 0x01 : 0x00);
        meta._value = (meta._value & 0xfffffffeffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | (bytes32(specialVal) >> (8*3));
    }

    function getReserved(Metadata memory meta) internal pure returns(bytes29) {
        return bytes29(meta._value << (8*3));
    }

    function isPoacher(Metadata memory meta) internal pure returns(bool) {
        return getCharacterType(meta) == POACHER;
    }

    function isAnimal(Metadata memory meta) internal pure returns(bool) {
        return getCharacterType(meta) == ANIMAL;
    }

    function isRhino(Metadata memory meta) internal pure returns(bool) {
        return getCharacterType(meta) == ANIMAL && getCharacterSubtype(meta) == RHINO;
    }

    function isAPR(Metadata memory meta) internal pure returns(bool) {
        return getCharacterType(meta) == APR;
    }

    function setSpecial(Metadata memory meta, Metadata[] storage specials) internal {
	Metadata memory special = specials[specials.length-1];
	meta._value = special._value;
	specials.pop();
    }

    function setProperty(Metadata memory meta, uint256 fieldStart, uint256 fieldSize, uint256 value) internal view {
        setField(meta, fieldStart + propertiesStart, fieldSize, value);
    }

    function getProperty(Metadata memory meta, uint256 fieldStart, uint256 fieldSize) internal pure returns(uint256) {
        return getField(meta, fieldStart + propertiesStart, fieldSize);
    }

    function setField(Metadata memory meta, uint256 fieldStart, uint256 fieldSize, uint256 value) internal view {
        require(value < (1 << fieldSize), 'attempted to set a field to a value that exceeds the field size');
	uint256 shiftAmount = 256 - (fieldStart + fieldSize);
        bytes32 mask = ~bytes32(((1 << fieldSize) - 1) << shiftAmount);
	bytes32 fieldVal = bytes32(value << shiftAmount);
        meta._value = (meta._value & mask) | fieldVal;
    }

    function getField(Metadata memory meta, uint256 fieldStart, uint256 fieldSize) internal pure returns(uint256) {
	uint256 shiftAmount = 256 - (fieldStart + fieldSize);
        bytes32 mask = bytes32(((1 << fieldSize) - 1) << shiftAmount);
	bytes32 fieldVal = meta._value & mask;
	return uint256(fieldVal >> shiftAmount);
    }

    function getRaw(Metadata memory meta) internal pure returns(bytes32) {
        return meta._value;
    }
}
