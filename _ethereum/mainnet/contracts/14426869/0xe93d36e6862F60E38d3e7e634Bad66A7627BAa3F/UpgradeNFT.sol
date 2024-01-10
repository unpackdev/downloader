// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";

contract UpgradeNFT is Ownable {
    uint256 public nameChangePrice;
	uint256 public bioChangePrice;

    mapping(uint256 => string) public customName;
	mapping(uint256 => string) public bio;

	// Mapping if certain name string has already been reserved
	mapping(string => bool) private _nameReserved;

	event NameChange(uint256 indexed tokenId, string customName);
	event BioChange(uint256 indexed tokenId, string bio);

    constructor(uint256 _namePrice, uint256 _bioPrice) {
        nameChangePrice = _namePrice;
        bioChangePrice = _bioPrice;
    }

    function changeBio(uint256 _tokenId, string memory _bio) public virtual {
		bio[_tokenId] = _bio;
		emit BioChange(_tokenId, _bio);
	}

    function changeCustomName(uint256 _tokenId, string memory _newName) public virtual {
		require(_validateName(_newName) == true, "Not a valid name");
		require(sha256(bytes(_newName)) != sha256(bytes(customName[_tokenId])), "Name is same as the current");
		require(isNameReserved(_newName) == false, "Name reserved");

		// If already named, dereserve old name
		if (bytes(customName[_tokenId]).length > 0) {
			toggleReserveName(customName[_tokenId], false);
		}

		toggleReserveName(_newName, true);
        customName[_tokenId] = _newName;
		emit NameChange(_tokenId, _newName);
	}

    function setNameChangePrice(uint256 _nameChangePrice) external onlyOwner {
        nameChangePrice = _nameChangePrice;
    }

    function setbioChangePrice(uint256 _bioChangePrice) external onlyOwner {
        bioChangePrice = _bioChangePrice;
    }

    /**
	 * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
	 */
	function toggleReserveName(string memory _str, bool _isReserve) internal {
		_nameReserved[_toLower(_str)] = _isReserve;
	}

	/**
	 * @dev Returns name of the NFT at index.
	 */
	function tokenNameByIndex(uint256 _index) public view returns (string memory) {
		return customName[_index];
	}

	/**
	 * @dev Returns if the name has been reserved.
	 */
	function isNameReserved(string memory _nameString) public view returns (bool) {
		return _nameReserved[_toLower(_nameString)];
	}

	function _validateName(string memory __str) public pure returns (bool){
		bytes memory b = bytes(__str);
		if (b.length < 1) return false;
		if (b.length > 25) return false; // Cannot be longer than 25 characters
		if (b[0] == 0x20) return false; // Leading space
		if (b[b.length - 1] == 0x20) return false; // Trailing space

		bytes1 lastChar = b[0];

		for(uint i; i<b.length; i++){
			bytes1 char = b[i];

			if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

			if(
				!(char >= 0x30 && char <= 0x39) && //9-0
				!(char >= 0x41 && char <= 0x5A) && //A-Z
				!(char >= 0x61 && char <= 0x7A) && //a-z
				!(char == 0x20) //space
			)
				return false;

			lastChar = char;
		}

		return true;
	}

	 /**
	 * @dev Converts the string to lowercase
	 */
	function _toLower(string memory __str) public pure returns (string memory) {
		bytes memory bStr = bytes(__str);
		bytes memory bLower = new bytes(bStr.length);
		for (uint i = 0; i < bStr.length; i++) {
			// Uppercase character
			if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
				bLower[i] = bytes1(uint8(bStr[i]) + 32);
			} else {
				bLower[i] = bStr[i];
			}
		}
		return string(bLower);
	}
}