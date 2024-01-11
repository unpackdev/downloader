// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract AmazingHorses is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string private baseURI;
  string private baseExtension = ".json";
  string private notRevealedUri;
  uint256 private maxSupplyPubSale = 9999;
  uint256 private nftPerSessionLimit = 2;
  uint256 private nftPerWalletLimitPubSale = 2;
  uint256 private publicSaleStartsAt = 0;
  bool private locked = false;
  bool private startPublicSale = false;
  bool private paused = false;
  bool private revealed = false;
  mapping(address => uint256) private addressMintedBalance;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    uint256 _publicSaleStartsAt
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    setPublicSaleStartsAt(_publicSaleStartsAt);
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    require(isPubSale(), "sale not started yet");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= nftPerSessionLimit, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupplyPubSale, "max NFT limit exceeded");
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + _mintAmount <= nftPerWalletLimitPubSale, "max NFT per address exceeded");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function tokenOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function totalBalance() public view returns(uint256) {
    return address(this).balance;
  }

  function isPubSale() public view returns (bool) {
    return startPublicSale || (publicSaleStartsAt != 0 && getTime() >= publicSaleStartsAt);
  }

  // internal

  /**
    * @dev Current block timestamp as seconds since unix epoch.
    */
  function getTime() internal view returns (uint256) {
    return block.timestamp;
  }

  function getPublicSaleStartsAt() public view returns (uint256) {
    return publicSaleStartsAt;
  }

  // OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)
  /**
    * @dev Converts a `uint256` to its ASCII `string` decimal representation.
    */
  function toString(uint256 value) internal pure returns (string memory) {
      // Inspired by OraclizeAPI's implementation - MIT licence
      // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // only callable by owner
  function ownerMint(uint256 _mintAmount) public onlyOwner {
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupplyPubSale, "max NFT limit exceeded");
    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function setPublicSaleStartsAt(uint256 _newPublicSaleStartsAt) public onlyOwner {
    publicSaleStartsAt = _newPublicSaleStartsAt;
  }

  function setStartPublicSale(bool _newStartPublicSale) public onlyOwner {
    startPublicSale = _newStartPublicSale;
  }

  function setNftPerWalletLimitPubSale(uint256 _newNftPerWalletLimitPubSale) public onlyOwner {
    nftPerWalletLimitPubSale = _newNftPerWalletLimitPubSale;
  }

  function setNftPerSessionLimit(uint256 _newNftPerSessionLimit) public onlyOwner {
    nftPerSessionLimit = _newNftPerSessionLimit;
  }

  function setPause(bool _newPauseState) public onlyOwner {
    paused = _newPauseState;
  }
 
  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  // sensitive data - can not be changed onces contract is locked
  modifier ifNotLocked {
      require(locked == false, 'contract is locked, this value can no longer be changed');
      _;
   }

  function lockContract() public onlyOwner {
    locked = true;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner ifNotLocked {
    baseURI = _newBaseURI;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner ifNotLocked {
    notRevealedUri = _notRevealedURI;
  }

  function setMaxSupplyPubSale(uint256 _maxSupplyPubSale) public onlyOwner ifNotLocked {
    maxSupplyPubSale = _maxSupplyPubSale;
  }

  function setReveal(bool _newRevealState) public onlyOwner ifNotLocked {
      revealed = _newRevealState;
  }
}
