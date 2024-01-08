// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./ERC721Enumerable.sol";
import "./CollaborativeOwnable.sol";
import "./ProxyRegistry.sol";

contract TheGauntlet is ERC721Enumerable, CollaborativeOwnable, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address;
  using Strings for uint256;

  uint256 public maxSupply = 5002;

  string public baseURI = "";
  address public proxyRegistryAddress = address(0);
  
  uint256 public mintPrice = 30000000000000000;
  uint256 public mintLimit = 10;
  bool public mintIsActive = false;
  uint256 public totalMinted = 0;

  address public collaboratorWithdrawAddress = address(0);
  uint256 public developerPercentage = 20;

  bool public gauntletStarted = false;
  uint256 public constant survivorCount = 10;
  uint256 public constant survivorCutPercentage = 65;
  uint256 public survivorCut = 0;
  mapping(address => bool) private _claimed;
  uint256 public unclaimedCount = 10;

  uint256[] private _unburnedTokens; // token id
  mapping(uint256 => uint256) private _unburnedTokensIndex; // token id to array position
  uint256 public totalBurned = 0;

  address public withdrawAddress0 = address(0);
  address public withdrawAddress1 = address(0);

  uint256 private randomSeed = 0;

  constructor(address _proxyRegistryAddress, address _withdrawAddress0, address _withdrawAddress1) ERC721("The Gauntlet", "GAUNTLET") {
    proxyRegistryAddress = _proxyRegistryAddress;
    withdrawAddress0 = _withdrawAddress0;
    withdrawAddress1 = _withdrawAddress1;
  }

  //
  // Public / External
  //

  function mint(uint256 quantity) external payable nonReentrant {
    require(mintIsActive, "inactive");
    require(!gauntletStarted, "started");
    require(quantity > 0, "quantity");
    require(quantity <= mintLimit, "limit");

    uint256 ts = totalSupply();
    require((ts + quantity) <= maxSupply, "supply");
    require(mintPrice.mul(quantity) <= msg.value, "value");

    for (uint i = 0; i < quantity; i++) {
      uint256 tokenId = ts + i;
      _safeMint(_msgSender(), tokenId);
      _addTokenToUnburnedEnumeration(tokenId);
    }

    totalMinted = totalMinted.add(quantity);
  }
  
  function claim() external nonReentrant {
    require(totalSupply() == survivorCount, "incomplete");
    uint256 balance = balanceOf(_msgSender());
    require(balance > 0, "holder");
    require(!_claimed[_msgSender()], "claimed");

    uint256 cut = survivorCut.mul(balance);

    _claimed[_msgSender()] = true;
    unclaimedCount = unclaimedCount.sub(balance);

    payable(_msgSender()).transfer(cut);
  }

  // Override ERC721
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  // Override ERC721
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "invalid token");
        
    string memory __baseURI = _baseURI();
    return bytes(__baseURI).length > 0 ? string(abi.encodePacked(__baseURI, tokenId.toString(), ".json")) : '.json';
  }

  // Override ERC721
  function isApprovedForAll(address owner, address operator) override public view returns (bool) {
    if (address(proxyRegistryAddress) != address(0)) {
      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
      if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
      }
    }
    return super.isApprovedForAll(owner, operator);
  }

  //
  // Private
  //
  function _addTokenToUnburnedEnumeration(uint256 tokenId) private {
    _unburnedTokensIndex[tokenId] = _unburnedTokens.length;
    _unburnedTokens.push(tokenId);
  }

  function _removeTokenFromUnburnedEnumeration(uint256 tokenId) private {
    uint256 lastTokenIndex = _unburnedTokens.length - 1;
    uint256 tokenIndex = _unburnedTokensIndex[tokenId];

    uint256 lastTokenId = _unburnedTokens[lastTokenIndex];

    _unburnedTokens[tokenIndex] = lastTokenId;
    _unburnedTokensIndex[lastTokenId] = tokenIndex;

    delete _unburnedTokensIndex[tokenId];
    _unburnedTokens.pop();
  }

  function _random() internal returns (uint256) {
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _msgSender(), randomSeed)));
    randomSeed = randomNumber;
    return randomNumber;
  }

  function _getRandomTokenId() internal returns (uint256) {
    uint256 randomIndex = _random() % _unburnedTokens.length;
    return _unburnedTokens[randomIndex];
  }

  //
  // Collaborator Access
  //

  function burn(uint256 newRandomSeed, uint256 quantity) external onlyCollaborator {
    require((_unburnedTokens.length - quantity) >= survivorCount, "quantity");
    require(newRandomSeed != 0, "zero");

    randomSeed = newRandomSeed;

    for (uint256 i = 0; i < quantity; i++) {
      uint256 tokenId = _getRandomTokenId();
      _burn(tokenId);
      _removeTokenFromUnburnedEnumeration(tokenId);
      totalBurned++;
    }
  }

  function setBaseURI(string memory uri) external onlyCollaborator {
    baseURI = uri;
  }

  function startGauntlet() external onlyCollaborator {
    require(!gauntletStarted, "started");
    
    mintIsActive = false;
    gauntletStarted = true;

    uint256 balance = address(this).balance;
    
    survivorCut = balance.mul(survivorCutPercentage).div(1000);
  }

  function reduceMintPrice(uint256 newPrice) external onlyCollaborator {
    require(newPrice >= 0 && newPrice < mintPrice);
    mintPrice = newPrice;
  }

  function reduceMaxSupply(uint256 newMaxSupply) external onlyCollaborator {
    require(newMaxSupply >= 0 && newMaxSupply < maxSupply);
    require(newMaxSupply >= totalSupply());
    require(!gauntletStarted);
    maxSupply = newMaxSupply;
  }

  function setMintIsActive(bool active) external onlyCollaborator {
    mintIsActive = active;
  }

  function setMintLimit(uint256 limit) external onlyCollaborator {
    require(limit > 0, "limit");
    mintLimit = limit;
  }

  function setProxyRegistryAddress(address prAddress) external onlyCollaborator {
    proxyRegistryAddress = prAddress;
  }

  function withdraw() external onlyCollaborator nonReentrant {
    require(gauntletStarted, "not started");
    uint256 balance = address(this).balance;
    uint256 reserved = survivorCut.mul(unclaimedCount);
    require(balance > reserved, "reserved");
    uint256 remaining = balance.sub(reserved);
    require(balance > 0, "zero");

    uint256 cut = remaining.div(2);

    payable(withdrawAddress0).transfer(cut);
    payable(withdrawAddress1).transfer(cut);
  }
}