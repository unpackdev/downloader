// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./IERC721.sol";

import "./AncientBatz.sol";

interface IAncientBatz is IERC721 {
  function maxBites(uint256 tokenId) external view returns (uint256);
}

contract MegaMutantBatz is Ownable, ERC721A, ERC2981 {
  // EVENTS *****************************************************

  event ConfigUpdated(bytes32 config, bytes value);
  event ConfigLocked(bytes32 config);
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

  // ERRORS *****************************************************

  error InvalidConfig(bytes32 config);
  error ConfigIsLocked(bytes32 config);
  error MustOwnAncientBat();
  error OutOfBites();
  error NonExistentToken(uint256 tokenId);

  // Storage *****************************************************

  /// @dev The AncientBatz contract
  AncientBatz public ancientBatz;

  /// @notice The number of bites that each AncientBat has made
  mapping(uint256 => uint256) public bites;

  /// @notice BaseURI for token metadata
  string public baseURI = "https://nft-metadata.eleventhstudio.xyz/collection/megamutants/";

  /// @notice Contract metadata URI
  string public contractURI = "ipfs://bafkreiek35v34ln7nmrjy663knmovqumdgsj3bxb2kvk6hiprcp7dy75ja";

  mapping(bytes32 => bool) configLocked;

  // Constructor *****************************************************

  constructor(address ancientBatzAddress) ERC721A("MegaMutantBatz", "MMBATZ") {
    _setDefaultRoyalty(0x28922783a6A0C419C413f8592cBb1cEa1CdFb42a, 750); // 7.5% royalties
    ancientBatz = AncientBatz(ancientBatzAddress);
  }

  // Owner Methods *****************************************************

  function updateConfig(bytes32 config, bytes calldata value) external onlyOwner {
    if (configLocked[config]) revert ConfigIsLocked(config);
    if (config == "baseURI") {
      baseURI = abi.decode(value, (string));
      emit BatchMetadataUpdate(1, type(uint256).max);
    } else if (config == "contractURI") contractURI = abi.decode(value, (string));
    else if (config == "royalty") {
      (address recipient, uint96 numerator) = abi.decode(value, (address, uint96));
      _setDefaultRoyalty(recipient, numerator);
    } else revert InvalidConfig(config);

    emit ConfigUpdated(config, value);
  }

  function lockConfig(bytes32 config) external onlyOwner {
    configLocked[config] = true;

    emit ConfigLocked(config);
  }

  // Public Methods *****************************************************

  function bite(uint256 ancientBatzId, uint256 amount) external {
    if (ancientBatz.ownerOf(ancientBatzId) != msg.sender) revert MustOwnAncientBat();
    if (bites[ancientBatzId] + amount > ancientBatz.maxBites(ancientBatzId)) revert OutOfBites();

    bites[ancientBatzId] += amount;

    _mint(msg.sender, amount);
  }

  // Override Methods *****************************************************

  /// @notice Returns the metadata URI for a given token
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) revert NonExistentToken(tokenId);

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721A) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }
}
