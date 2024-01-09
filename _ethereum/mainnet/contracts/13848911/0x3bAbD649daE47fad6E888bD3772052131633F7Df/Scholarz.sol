// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

interface IGenTraitFactory {
  function roll(uint seed) external pure returns (uint[9] memory);
}

contract Scholarz is ERC721EnumerableUpgradeable, ERC721PausableUpgradeable, OwnableUpgradeable {
  using StringsUpgradeable for uint256;
  using ECDSAUpgradeable for bytes32;
  uint public constant MAX_GENESIS_AMOUNT = 2500;
  uint public constant MAX_UNIQUE_AMOUNT = 25;
  uint public constant UNIT_PRICE = 0.125 ether;
  uint public whitelistCount;
  uint public uniqueCount;
  uint public lastTokenId;
  uint public startingTime;
  uint private _randomSeed;
  uint private _randomNonce;
  bool public privateSaleActive;
  bool public publicSaleActive;
  uint[9][MAX_GENESIS_AMOUNT + 1] internal _genTraits;
  mapping(address => bool) public eligible;
  mapping(string => bool) private usedString; // no longer used
  mapping(address => uint) public genBalance;
  mapping(address => uint) private solvedCount;
  string private _contractURI;
  string private _revealedBaseURI;
  string private _tokenBaseURI;
  address private _signer;
  IGenTraitFactory genTraitFactory;
  mapping(uint => uint) private tokenSeed;
  mapping(bytes32 => bool) public usedKey;
  event MintedWithExp(address indexed sender, bytes32 indexed key);

  function initialize() public initializer {
    __ERC721_init("Scholarz", "SCZ");
    __ERC721Enumerable_init();
    __Ownable_init();
    setBaseURI("ipfs://QmaSt52oWa8WcyG5tN6qAWsSTTK5nUN1zrX8p3RMmNhUkS");
    _randomSeed = 10000000000000666666666666600000007;
    _randomNonce = 70000000666666666666600000000000001;
    _signer = 0xBc9eebF48B2B8B54f57d6c56F41882424d632EA7;
  }

  function setFactoryAddress(address adr) public onlyOwner {
    genTraitFactory = IGenTraitFactory(adr);
  }

  function setSignerAddress(address adr) public onlyOwner {
    _signer = adr;
  }

  function togglePublicSale() public onlyOwner {
    if (!publicSaleActive) {
      startingTime = block.timestamp;
    }
    publicSaleActive = !publicSaleActive;
  }

  function _getRandomSeed() internal view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, _randomSeed, block.timestamp, _randomNonce, msg.sender, totalSupply())));
  }

  function getTraits(uint tokenId) public view returns (uint[9] memory) {
    require(_exists(tokenId), "Token does not exist.");
    if (tokenSeed[tokenId] != 0) {
      return genTraitFactory.roll(tokenSeed[tokenId]);
    } else {
      return _genTraits[tokenId];
    }
  }

  function _rollUnique(uint seed) internal view returns (bool) {
    uint val = seed % (MAX_GENESIS_AMOUNT - totalSupply());
    return val < MAX_UNIQUE_AMOUNT - uniqueCount;
  }
  
  function _generateUniqueTrait(uint tokenId, uint uniqueId) internal {
    _genTraits[tokenId][0] = 0;
    for (uint j = 1; j < 9; j++) {
      _genTraits[tokenId][j] = uniqueId;
    }
  }

  function _mintScholarz(address minter, uint inputId, bool early) private {
    if (early) {
      _safeMint(minter, inputId);
      genBalance[minter]++;
      return;
    }
    uint seed = _getRandomSeed();
    _randomSeed = seed;
    _randomNonce++;
    uint tokenId = lastTokenId + 1;
    if (inputId == 0) {
      while (_exists(tokenId)) {
        tokenId++;
      }
      lastTokenId = tokenId;
    } else {
      tokenId = inputId;
    }
    // check for uniques
    if (_rollUnique(seed)) {
      uniqueCount++;
      _generateUniqueTrait(tokenId, uniqueCount);
    } else {
      tokenSeed[tokenId] = seed;
    }
    _safeMint(minter, tokenId);
    genBalance[minter]++;
  }
  
  function earlyMint(uint amount, uint[] calldata inputIds, uint[9][] calldata genes) public onlyOwner {
    require(amount == inputIds.length, "Amount does not match.");
    require(amount == genes.length, "Amount does not match.");
    for (uint i = 0; i < amount; i++) {
      require(!_exists(inputIds[i]), 'Token ID already exists.');
    }
    for (uint i = 0; i < amount; i++) {
      _mintScholarz(msg.sender, inputIds[i], true);
      _genTraits[inputIds[i]] = genes[i];
    }
  }

  function mintWithExp(bytes32 key, bytes calldata signature, uint amount, uint timestamp) public {
    require(publicSaleActive, "Public sale has not started.");
    require(msg.sender == tx.origin, "Contracts are not allowed to purchase.");
    require(totalSupply() < MAX_GENESIS_AMOUNT, "Purchase exceeds total genesis.");
    require(!usedKey[key], "Key has been used.");
    require(block.timestamp < timestamp, "Expired mint time.");
    require(keccak256(abi.encode(msg.sender, "EXP", amount, timestamp, key)).toEthSignedMessageHash().recover(signature) == _signer, "Invalid signature");
    for (uint i = 0; i < amount; i++) {
      _mintScholarz(msg.sender, 0, false);
    }
    usedKey[key] = true;
    emit MintedWithExp(msg.sender, key);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override {
    if (tokenId <= MAX_GENESIS_AMOUNT) {
      genBalance[from]--;
      genBalance[to]++;
    }
    ERC721Upgradeable.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
    if (tokenId <= MAX_GENESIS_AMOUNT) {
      genBalance[from]--;
      genBalance[to]++;
    }
    ERC721Upgradeable.safeTransferFrom(from, to, tokenId, _data);
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setContractURI(string memory URI) public onlyOwner {
    _contractURI = URI;
  }

  function setBaseURI(string memory URI) public onlyOwner {
    _tokenBaseURI = URI;
  }

  function setRevealedBaseURI(string memory URI) public onlyOwner {
    _revealedBaseURI = URI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if (tokenId <= MAX_GENESIS_AMOUNT) {
      return bytes(_revealedBaseURI).length > 0 ? string(abi.encodePacked(_revealedBaseURI, tokenId.toString())) : _tokenBaseURI;
    } else {
      // placeholder for gen+
      return "";
    }
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  } 

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

}  
