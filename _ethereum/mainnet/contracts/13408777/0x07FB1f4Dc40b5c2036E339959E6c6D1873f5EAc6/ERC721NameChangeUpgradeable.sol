// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./IERC721NameChangeUpgradeable.sol";

/**
 * @title ERC721NameChangeUpgradeable
 */
abstract contract ERC721NameChangeUpgradeable is
  Initializable,
  ERC721Upgradeable,
  IERC721NameChangeUpgradeable
{
  function __ERC721NameChange_init(address nameChangeToken_, uint256 nameChangePrice_) internal {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __ERC721NameChange_init_unchained(nameChangeToken_, nameChangePrice_);
  }

  function __ERC721NameChange_init_unchained(address nameChangeToken_, uint256 nameChangePrice_)
    internal
  {
    _nameChangeToken = nameChangeToken_;
    _nameChangePrice = nameChangePrice_;
  }

  event NameChange(uint256 indexed tokenIndex, string newName);

  // Name change token
  address internal _nameChangeToken;

  // Name change price
  uint256 internal _nameChangePrice;

  // Per token name, settable by the token owner
  mapping(uint256 => string) private _tokenName;

  // Mapping if certain name string has already been reserved
  mapping(string => bool) private _nameReserved;

  /**
   * @dev Returns name change token address
   */
  function nameChangeToken() public view override returns (address) {
    return _nameChangeToken;
  }

  /**
   * @dev Returns name change price
   */
  function nameChangePrice() public view override returns (uint256) {
    return _nameChangePrice;
  }

  /**
   * @dev Returns name of the NFT at index.
   */
  function tokenNameByIndex(uint256 index) public view virtual returns (string memory) {
    return _tokenName[index];
  }

  /**
   * @dev Returns if the name has been reserved.
   */
  function isNameReserved(string memory nameString) public view virtual override returns (bool) {
    return _nameReserved[toLower(nameString)];
  }

  /**
   * @dev Changes the name for tokenId
   */
  function changeName(uint256 tokenId, string memory newName) public virtual override {
    address owner = ownerOf(tokenId);

    require(_msgSender() == owner, 'ERC721: caller is not the owner');
    require(validateName(newName) == true, 'Not a valid new name');
    require(
      sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])),
      'New name is same as the current one'
    );
    require(isNameReserved(newName) == false, 'Name already reserved');

    IERC20Upgradeable(_nameChangeToken).transferFrom(msg.sender, address(this), _nameChangePrice);
    // If already named, dereserve old name
    if (bytes(_tokenName[tokenId]).length > 0) {
      _toggleReserveName(_tokenName[tokenId], false);
    }
    _toggleReserveName(newName, true);
    _tokenName[tokenId] = newName;
    emit NameChange(tokenId, newName);
  }

  /**
   * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
   */
  function _toggleReserveName(string memory str, bool isReserve) internal virtual {
    _nameReserved[toLower(str)] = isReserve;
  }

  /**
   * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
   */
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

  uint256[46] private __gap;
}
