//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ToggleableSale.sol";
import "./WhitelistVerifier.sol";
import "./ERC721Referralable.sol";

contract CottonballCuddles is Ownable, ERC721Enumerable, ToggleableSale, WhitelistVerifier {
  string public PROVENANCE_HASH = '';
  uint256 public MAX_ITEMS;
  uint256 public PUBLIC_ITEMS;
  uint256 public COMMUNITY_ITEMS;

  string public baseUri;
  uint256 public communityMinted;
  uint256 public presaleMinted;
  address public provenanceProvider;

  uint256 public mintPrice;
  uint256 public presaleMintPrice;
  uint256 public maxPerMint;

  constructor() ERC721('Cottonball Cuddles', 'CBC') {
    //TEST VALUES
    MAX_ITEMS = 7777;
    COMMUNITY_ITEMS = 200;
    PUBLIC_ITEMS = MAX_ITEMS - COMMUNITY_ITEMS;

    mintPrice = 0.01 ether;
    presaleMintPrice = 0.007 ether;
    maxPerMint = 20;
    baseUri = '';
  }

  event SetBaseUri(string indexed baseUri);

  // -----------------
  // External functions
  // -----------------

  function mint(uint256 amount) external payable whenSaleActive {
    uint256 publicMinted = totalSupply() - communityMinted;

    require(maxPerMint == 0 || amount <= maxPerMint, 'Amount exceeds max per mint');
    require(publicMinted + amount <= PUBLIC_ITEMS, 'Purchase would exceed public cap');
    require(mintPrice * amount <= msg.value, 'Ether value sent is not correct');

    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenId = getNextId(totalSupply());
      if (publicMinted < PUBLIC_ITEMS) {
        _safeMint(msg.sender, tokenId);
      }
    }
  }

  function presaleMint(uint256 amount) external payable whenPresaleActive {
    uint256 publicMinted = totalSupply() - communityMinted;
    require(publicMinted + amount <= PUBLIC_ITEMS, 'Purchase would exceed public cap');

    require(presaleMintPrice * amount <= msg.value, 'Ether value sent is not correct');
    require(canClaim(msg.sender, amount), 'You cannot mint this many tokens in presale');

    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenId = getNextId(totalSupply());
      if (publicMinted < PUBLIC_ITEMS) {
        addClaimed(msg.sender, 1);
        presaleMinted += 1;
        _safeMint(msg.sender, tokenId);
      }
    }
  }

  // -----------------
  // Utility functions
  // -----------------

  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for (uint256 i = 0; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensId;
  }

  function exists(uint256 _tokenId) public view returns (bool) {
    return _exists(_tokenId);
  }

  function getNextId(uint256 currentId) internal view returns (uint256) {
    uint256 tokenId = currentId + 1;
    require(tokenId <= MAX_ITEMS, 'Failed to generate token id. Please try again.');

    if (_exists(tokenId)) {
      return getNextId(tokenId);
    }

    return tokenId;
  }

  function mintCommunitySpecific(address _to, uint256 tokenId) private {
    require(!_exists(tokenId), 'Token with this id already exists!');
    require(_to != address(0), 'Cannot mint to zero address.');
    require(totalSupply() < MAX_ITEMS, 'Minting would exceed cap');
    require(communityMinted < COMMUNITY_ITEMS, 'Minting would exceed community cap');

    if (totalSupply() < MAX_ITEMS && communityMinted < COMMUNITY_ITEMS) {
      _safeMint(_to, tokenId);
      communityMinted = communityMinted + 1;
    }
  }

  // -----------------
  // Overrides
  // -----------------

  function _baseURI() internal view override returns (string memory) {
    return baseUri;
  }

  // -----------------
  // Admin functions
  // -----------------

  function setBaseUri(string memory _baseUri) external onlyOwner {
    baseUri = _baseUri;
    emit SetBaseUri(baseUri);
  }

  function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
    maxPerMint = _maxPerMint;
  }

  function setMintPrice(uint256 _mintPrice) external onlyOwner {
    mintPrice = _mintPrice;
  }

  function setPresaleMintPrice(uint256 _mintPrice) external onlyOwner {
    presaleMintPrice = _mintPrice;
  }

  function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
    PROVENANCE_HASH = _provenanceHash;
  }

  function setProvenanceProvider(address _addr) external onlyOwner {
    provenanceProvider = _addr;
  }

  function mintForCommunity(address _to) external onlyOwner {
    uint256 tokenId = getNextId(totalSupply());
    mintCommunitySpecific(_to, tokenId);
  }

  function mintRandomForCommunity(address _to) external onlyOwner {
    uint256 pseudoRandom = uint256(
      keccak256(abi.encodePacked(block.difficulty, block.timestamp, totalSupply()))
    );
    uint256 randomId = pseudoRandom % MAX_ITEMS;
    uint256 tokenId = getNextId(randomId);
    mintCommunitySpecific(_to, tokenId);
  }

  function withdraw() public payable onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, 'No ether left to withdraw');

    (bool success, ) = (msg.sender).call{ value: balance }('');
    require(success, 'Transfer failed.');
  }
}
