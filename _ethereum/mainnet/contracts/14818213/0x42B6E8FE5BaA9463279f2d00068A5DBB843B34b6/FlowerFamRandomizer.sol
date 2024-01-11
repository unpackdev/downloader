// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./SimpleAccess.sol";

contract FlowerFamRandomizer is SimpleAccess {

    uint256 private seed;

    /**
     * @dev Each flower's species
     * is denoted by 8 bits. Each uint256
     * can hold the species data of 32 flowers.
     * In total we need to fill the array up with
     * 218 integers to accomodate 6969 species.
     *
     * To find the species of a flower with ID x we first
     * need to find the 32 species slot it falls in. The
     * formula for this is: slot = (x - 1) * 8 / 256.
     * 
     * To find the 8 bits in the 256 bits within the slot of
     * flower with ID x we need to use the following formula:
     * offset = (x - 1) * 8 % 256. Then we left shift the integer (<<)
     * with the offset and take the next 8 bits. The number we get
     * is the species.
     */
    mapping(uint256 => uint256) private species;

    constructor(uint256 _seed) {
        seed = _seed;
    }

    function rng(address _address) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp, seed, _address)));
    }

    function rngDecision(address _address, uint256 probability, uint256 base) external view returns (bool) {
        uint256 randNum = rng(_address);

        uint256 decisionNum = randNum % base;

        return decisionNum < probability;
    }

    function _getSlotOfId(uint256 id)  internal pure returns (uint256) {
        return (id - 1) * 8 / 256;
    }

    function _getOffsetOfId(uint256 id) internal pure returns (uint256) {
        return (id - 1) * 8 % 256;
    }

    function getSpeciesOfId(uint256 id) external view returns (uint8) {
        require(id > 0, "Id must be greater than 0");
        
        uint256 slot = _getSlotOfId(id);
        uint256 offset = _getOffsetOfId(id);

        uint256 slotData = species[slot];
        return uint8(slotData >> offset);
    }

    function setSlotData(uint256[] calldata slots, uint256[] calldata datas) external onlyOwner {
        require(slots.length > 0, "Please provide a filled array");
        require(slots.length == datas.length, "Slots & data lengths not the same");

        for (uint i = 0; i < slots.length; i++) {
            species[slots[i]] = datas[i];
        }
    }

    function getSlotOfId(uint256 id)  external pure returns (uint256) {
        _getSlotOfId(id);
    }

    function getOffsetOfId(uint256 id) external pure returns (uint256) {
        return _getOffsetOfId(id);
    }

    function withdrawAll(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "NO ETHER TO WITHDRAW");
        payable(_to).transfer(contractBalance);
    }

    receive() external payable {}
}