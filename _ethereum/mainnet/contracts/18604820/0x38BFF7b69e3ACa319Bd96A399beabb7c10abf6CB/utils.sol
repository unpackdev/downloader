//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

    enum DistributionType {
        Presale,
        Quests,
        Team,
        Advisor,
        Lootbox
    }

    enum RarityNFT {
        Ordinary,
        Majestic,
        Epic,
        Legendary
    }

    enum RarityLootbox {
        Common,
        Rare,
        Epic,
        Legendary
    }


contract Utils {
    uint256 private randomNonce = 0;

    // @title Generate random number from 0 to _max-1
    function randomNum(uint256 _max)
    internal
    returns (uint256)
    {
        randomNonce++;
        return uint(keccak256(abi.encodePacked(randomNonce, msg.sender, block.prevrandao, block.number))) % _max;
    }

    // @title Check if value exists in array
    function valueExists(uint8[] memory _self, uint8 _value)
    internal pure
    returns (bool)
    {
        uint _length = _self.length;
        for (uint8 _i = 0; _i < _length; ++_i) if (_self[_i] == _value) return true;
        return false;
    }

    // @title Check if address exists in array
    function addressExists(address[] memory _self, address _value)
    internal pure
    returns (bool)
    {
        uint _length = _self.length;
        for (uint8 _i = 0; _i < _length; ++_i) if (_self[_i] == _value) return true;
        return false;
    }

    // @title Compare two strings
//	function strCompare(string memory str1, string memory str2) public pure returns (bool) {
//		if (bytes(str1).length != bytes(str2).length) {
//			return false;
//		}
//		return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
//	}

    // @title Check if value exists in array and return index
//	function indexOf(uint8[] memory _self, uint8 _value) internal pure returns (uint, bool) {
//		uint _length = _self.length;
//		for (uint8 _i = 0; _i < _length; ++_i) if (_self[_i] == _value) return (_i, true);
//		return (0, false);
//	}
}