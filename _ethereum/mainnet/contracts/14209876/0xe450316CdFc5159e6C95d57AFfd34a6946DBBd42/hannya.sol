// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./console.sol";

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";

/// @title Crypto Hannya ERC721 contract
/// @author Rob Grimes
contract CryptoHannya is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, PaymentSplitter, ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  /// @dev Max mint number
  uint16 private constant MAX_HANNYA = 10_000;
  /// @dev Token price in Wei
  uint256 public constant TOKEN_PRICE = 0.08 ether; 
  string private _baseTokenURI;

  /// @dev A mapping to keep track of hannyaIds minted
  uint[] private _mintedHannyaIds;
  mapping(uint => bool) private _hannyaIdMintStatus;
  mapping(uint => uint) private _tokenToHannyaIds;

  address[] private _team;

  event NewHNYAMinted(address sender, uint256 tokenId);

  /*
   * INIT
   */
  constructor(address[] memory _payees, uint256[] memory _shares, string memory baseURI) ERC721("Crypto Hannya", "HNYA") PaymentSplitter(_payees, _shares) payable {
    _setBaseURI(baseURI);
    // Start ID's at 1 
    _tokenIdCounter.increment();
  }

  function _setBaseURI(string memory baseURI) internal virtual {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  // See all tokens owned by _owner 
  function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  // Standard mint 
  function mintHannya(uint256 hannyaId) external payable whenNotPaused nonReentrant {
    require(_hannyaIdMintStatus[hannyaId] != true, "hannyaID has already been minted.");
    require(_tokenIdCounter.current() <= MAX_HANNYA, "All Hannya minted");
    require(msg.value >= TOKEN_PRICE, "$");

    uint256 tokenId = _tokenIdCounter.current();
    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, _createURI(hannyaId));
    _tokenIdCounter.increment();

    // Update trackers
    _mintedHannyaIds.push(hannyaId);
    _hannyaIdMintStatus[hannyaId] = true;
    _tokenToHannyaIds[tokenId] = hannyaId;

    emit NewHNYAMinted(msg.sender, tokenId);
  }

  // Mint free tokens for giveaways 
  function mintHannyaGiveaway(address to, uint256 hannyaId) external onlyOwner {
    require(_hannyaIdMintStatus[hannyaId] != true, "hannyaID has already been minted.");
    require(_tokenIdCounter.current() <= MAX_HANNYA, "All Hannya minted");
    
    uint256 tokenId = _tokenIdCounter.current();
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, _createURI(hannyaId));
    _tokenIdCounter.increment();

    // Update trackers
    _mintedHannyaIds.push(hannyaId);
    _hannyaIdMintStatus[hannyaId] = true;
    _tokenToHannyaIds[tokenId] = hannyaId;

    emit NewHNYAMinted(msg.sender, tokenId);
  }

  function withdraw(address payable to) external {
    release(to);
  }
  function prevReleased(address to) external view returns (uint256) {
    return released(to);
  }
  function totalPrevReleased() external view returns (uint256) {
    return totalReleased();
  }

  function mintedHannyaIds() external view returns (uint[] memory) {
    return _mintedHannyaIds;
  }


  // Private methods 
  function _intToString(uint256 value) private pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function _createURI(uint256 hannyaId) private pure returns (string memory){
    return string(abi.encodePacked(_intToString(hannyaId), '.json'));
  }

  // Overrides 
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }
  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }
  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
  
}