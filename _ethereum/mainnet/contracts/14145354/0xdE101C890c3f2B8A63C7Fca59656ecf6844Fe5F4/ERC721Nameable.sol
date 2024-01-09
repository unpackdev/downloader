// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";

abstract contract ERC721Nameable is ERC721 {
  uint256 public NAME_CHANGE_PRICE = 50 ether;

  mapping(uint256 => string) public names;
  mapping(string => bool) private _reservedNames;

  event NameChange(uint256 indexed tokenId, string newName);

  function changeName(uint256 tokenId, string memory newName) public virtual {
    require(msg.sender == ownerOf(tokenId), "ONLY_OWNER_ALLOWED");
    require(validateName(newName) == true, "NOT_VALID_NEW_NAME");
    require(
      sha256(bytes(newName)) != sha256(bytes(names[tokenId])),
      "SAME_NAME"
    );
    require(isNameReserved(newName) == false, "ALREADY_RESERVED");

    if (bytes(names[tokenId]).length > 0) {
      toggleReserveName(names[tokenId], false);
    }

    toggleReserveName(newName, true);
    names[tokenId] = newName;
    emit NameChange(tokenId, newName);
  }

  function setNameChangePrice(uint256 price) external virtual {
    NAME_CHANGE_PRICE = price;
  }

  /**
   * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
   */
  function toggleReserveName(string memory str, bool isReserve) internal {
    _reservedNames[toLower(str)] = isReserve;
  }

  /**
   * @dev Returns if the name has been reserved.
   */
  function isNameReserved(string memory nameString) public view returns (bool) {
    return _reservedNames[toLower(nameString)];
  }

  /**
   * @dev Returns name of the NFT at index.
   */
  function tokenNameByIndex(uint256 index) public view returns (string memory) {
    return names[index];
  }

  function validateName(string memory str) public pure returns (bool) {
    bytes memory b = bytes(str);
    if (b.length < 1) return false;
    if (b.length > 25) return false; // Cannot be longer than 25 characters
    if (b[0] == 0x20) return false; // Leading space
    if (b[b.length - 1] == 0x20) return false; // Trailing space

    bytes1 lastChar = b[0];

    for (uint256 i; i < b.length; i++) {
      bytes1 char = b[i];

      if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

      if (
        !(char >= 0x30 && char <= 0x39) && //9-0
        !(char >= 0x41 && char <= 0x5A) && //A-Z
        !(char >= 0x61 && char <= 0x7A) && //a-z
        !(char == 0x20) //space
      ) return false;

      lastChar = char;
    }

    return true;
  }

  /**
   * @dev Converts the string to lowercase
   */
  function toLower(string memory str) public pure returns (string memory) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint256 i = 0; i < bStr.length; i++) {
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
