//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC1155Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./IERC2981.sol";

contract ClonableERC1155 is ERC1155Upgradeable, AccessControlUpgradeable, OwnableUpgradeable {

    mapping(uint256 => string) public tokenIdToURI;
    string public name;
    string public symbol;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public royaltyReceiver;
    uint16 public royaltyBasisPoints;

    function initialize(
      string memory _tokenName,
      string memory _tokenSymbol,
      string memory _tokenURI,
      address _admin,
      address _factory,
      address _minter
    ) public {
      name = _tokenName;
      symbol = _tokenSymbol;
      tokenIdToURI[1] = _tokenURI;
      _setupRole(DEFAULT_ADMIN_ROLE, _admin);
      _grantRole(DEFAULT_ADMIN_ROLE, _factory);
      _setupRole(MINTER_ROLE, _minter);
      _setURI(_tokenURI);
      _transferOwnership(_admin);
    }

    // We signify support for ERC2981, ERC1155, ERC1155MetadataURI & AccessControlUpgradeable
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
      return
        interfaceId == type(IERC2981).interfaceId ||
        interfaceId == type(IERC1155Upgradeable).interfaceId ||
        interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
        interfaceId == type(IAccessControlUpgradeable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function mint(address _recipient, uint256 _tokenId, uint96 _quantity) external onlyRole(MINTER_ROLE) {
      _mint(_recipient, _tokenId, _quantity, "");
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
      return tokenIdToURI[_tokenId];
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
      require(keccak256(bytes(tokenIdToURI[_tokenId])) == keccak256(bytes("")), "TOKEN_URI_ALREADY_SET");
      tokenIdToURI[_tokenId] = _tokenURI;
    }

    // ERC2981 logic

    function getPercentageOf(
      uint256 _amount,
      uint16 _basisPoints
    ) internal pure returns (uint256 value) {
      value = (_amount * _basisPoints) / 10000;
    }

    function updateRoyaltyInfo(address _royaltyReceiver, uint16 _royaltyBasisPoints) external onlyRole(DEFAULT_ADMIN_ROLE) {
      royaltyReceiver = _royaltyReceiver;
      royaltyBasisPoints = _royaltyBasisPoints;
    }

    // Takes a _tokenId and _price (in wei) and returns the royalty receiver's address and how much of a royalty the royalty receiver is owed
    function royaltyInfo(uint256 _tokenId, uint256 _price) external view returns (address receiver, uint256 royaltyAmount) {
      receiver = royaltyReceiver;
      royaltyAmount = getPercentageOf(_price, royaltyBasisPoints);
    }

}
