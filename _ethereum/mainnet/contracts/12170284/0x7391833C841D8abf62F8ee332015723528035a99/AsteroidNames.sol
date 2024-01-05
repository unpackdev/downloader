// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./Pausable.sol";
import "./IAsteroidToken.sol";


/**
 * @dev Allows the owner of an asteroid to set a name for it that will be included in ERC721 metadata
 */
contract AsteroidNames is Pausable {
  IAsteroidToken token;

  mapping (uint => string) private _asteroidNames;
  mapping (string => bool) private _usedNames;

  event NameChanged (uint indexed asteroidId, string newName);

  constructor(IAsteroidToken _token) {
    token = _token;
  }

  /**
   * @dev Change the name of the asteroid
   */
  function setName(uint _asteroidId, string memory _newName) external whenNotPaused {
    require(_msgSender() == token.ownerOf(_asteroidId), "ERC721: caller is not the owner");
    require(validateName(_newName) == true, "Invalid name");
    require(isNameUsed(_newName) == false, "Name already in use");

    // If already named, dereserve old name
    if (bytes(_asteroidNames[_asteroidId]).length > 0) {
      toggleNameUsed(_asteroidNames[_asteroidId], false);
    }

    toggleNameUsed(_newName, true);
    _asteroidNames[_asteroidId] = _newName;
    emit NameChanged(_asteroidId, _newName);
  }

  /**
   * @dev Retrieves the name of a given asteroid
   */
  function getName(uint _asteroidId) public view returns (string memory) {
    return _asteroidNames[_asteroidId];
  }

  /**
   * @dev Returns if the name is in use.
   */
  function isNameUsed(string memory nameString) public view returns (bool) {
    return _usedNames[toLower(nameString)];
  }

  /**
   * @dev Marks the name as used or unused
   */
  function toggleNameUsed(string memory str, bool isUsed) internal {
    _usedNames[toLower(str)] = isUsed;
  }

  /**
   * @dev Check if the name string is valid
   * Between 1 and 32 characters (Alphanumeric and spaces without leading or trailing space)
   */
  function validateName(string memory str) public pure returns (bool){
    bytes memory b = bytes(str);

    if(b.length < 1) return false;
    if(b.length > 32) return false; // Cannot be longer than 25 characters
    if(b[0] == 0x20) return false; // Leading space
    if (b[b.length - 1] == 0x20) return false; // Trailing space

    bytes1 lastChar = b[0];

    for (uint i; i < b.length; i++) {
      bytes1 char = b[i];

      if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

      if (
        !(char >= 0x30 && char <= 0x39) && //9-0
        !(char >= 0x41 && char <= 0x5A) && //A-Z
        !(char >= 0x61 && char <= 0x7A) && //a-z
        !(char == 0x20) //space
      ) {
        return false;
      }

      lastChar = char;
    }

    return true;
  }

  /**
   * @dev Converts the string to lowercase
   */
  function toLower(string memory str) public pure returns (string memory){
    bytes memory bStr = bytes(str);
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
