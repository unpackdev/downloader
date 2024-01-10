// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721Upgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

interface IScholarz {
  function ownerOf(uint tokenId) external view returns (address);
  function getTraits(uint tokenId) external view returns (uint[9] memory);
  function isApprovedForAll(address owner, address operator) external view returns (bool);  
}

interface ISkoolverse {
  function placedBy(uint tokenId) external view returns (address);
}

contract PixelScholarz is ERC721Upgradeable, ERC721PausableUpgradeable, OwnableUpgradeable {
  using StringsUpgradeable for uint256;
  using ECDSAUpgradeable for bytes32;
  IScholarz public Scholarz;
  ISkoolverse public Skoolverse;
  uint public MAX_UNIQUE_TRAIT;
  uint public MAX_SUPPLY;
  uint public currentSupply;

  // verification
  address private _signer;
  mapping(bytes32 => bool) private _usedKey; 

  // traits
  // pixel Scholarz follows the traits of Genesis Scholarz, but if they roll a special trait
  struct TokenMetadata {
    uint128 scholarzId; // inherit which genesis trait
    uint128 uniqueIndex; // unique index: 1 - 13
  }
  mapping(uint => TokenMetadata) public tokenIdToTokenMetadata;
  mapping(uint => bool) public claimed;
  uint128 public currentUniqueCount;

  // tokenURI
  string private _tokenBaseURI;

  event NewNormalBabies(address indexed from, bytes32 indexed key, uint128[] OwnedIds, uint timestamp);
  event NewSpecialBabies(address indexed from, bytes32 indexed key, uint128[] OwnedIds, uint timestamp);

  function initialize() public initializer {
    __ERC721_init("PixelScholarz", "PSCZ");
    __Ownable_init();
    _signer = 0xBc9eebF48B2B8B54f57d6c56F41882424d632EA7;
    Scholarz = IScholarz(0xdd67892E722bE69909d7c285dB572852d5F8897C);
    Skoolverse = ISkoolverse(0x790d870C0D8443b56269bE283AB4023f6F069dB2);
    MAX_SUPPLY = 1033;
    MAX_UNIQUE_TRAIT = 13;
  }

  // internal functions
  function getRandomSeed() internal view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, currentSupply, block.timestamp, currentUniqueCount, msg.sender)));
  }

  function createPixelBaby(uint128 _tokenId, bool _special) internal {
    require(Scholarz.ownerOf(_tokenId) == msg.sender || Skoolverse.placedBy(_tokenId) == msg.sender, "You don't own this Scholarz ID");
    require(currentSupply < MAX_SUPPLY, "Maximum amount has been reached");
    require(!claimed[_tokenId], "Pixel has been claimed");
    // set token id to claimed
    claimed[_tokenId] = true;

    // assign pixel scholarz traits to its counterpart
    tokenIdToTokenMetadata[++currentSupply].scholarzId = _tokenId;
    
    // special roll
    if (_special) {
      uint val = getRandomSeed() % (MAX_SUPPLY - currentSupply + 1);
      if (val < MAX_UNIQUE_TRAIT - currentUniqueCount) {
        // congrats
        tokenIdToTokenMetadata[currentSupply].uniqueIndex = ++currentUniqueCount;
      }
    }
    _mint(msg.sender, currentSupply);
    
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721Upgradeable, ERC721PausableUpgradeable) {
    // super._beforeTokenTransfer(from, to, tokenId);
  }

  // external functions
  function createNormalBabies(bytes32 _key, bytes calldata _signature, uint128[] memory _ownedIds, uint _timestamp) external whenNotPaused {
    require(!_usedKey[_key], "Key has been used");
    require(block.timestamp < _timestamp, "Expired claim time");
    require(keccak256(abi.encode(msg.sender, "normal", _ownedIds, _timestamp, _key)).toEthSignedMessageHash().recover(_signature) == _signer, "Invalid signature");
    _usedKey[_key] = true;
    for (uint i = 0; i < _ownedIds.length; i++) {
      createPixelBaby(_ownedIds[i], false);
    }
    emit NewNormalBabies(msg.sender, _key, _ownedIds, block.timestamp);
  }

  function createSpecialBabies(bytes32 _key, bytes calldata _signature, uint128[] memory _ownedIds, uint _timestamp) external whenNotPaused {
    require(!_usedKey[_key], "Key has been used");
    require(block.timestamp < _timestamp, "Expired claim time");
    require(keccak256(abi.encode(msg.sender, "special", _ownedIds, _timestamp, _key)).toEthSignedMessageHash().recover(_signature) == _signer, "Invalid signature");
    _usedKey[_key] = true;
    for (uint i = 0; i < _ownedIds.length; i++) {
      createPixelBaby(_ownedIds[i], true);
    }
    emit NewSpecialBabies(msg.sender, _key, _ownedIds, block.timestamp);
  }

  // owner functions
  function setScholarzAddress(address _address) public onlyOwner {
    Scholarz = IScholarz(_address);
  }

  function setSkoolverseAddress(address _address) public onlyOwner {
    Skoolverse = ISkoolverse(_address);
  }

  function setSignerAddress(address _address) public onlyOwner {
    _signer = _address;
  }

  function setBaseURI(string memory _URI) public onlyOwner {
    _tokenBaseURI = _URI;
  }

  function setMaxAmount(uint _amount) public onlyOwner {
    MAX_SUPPLY = _amount;
  }

  function setMaxUniqueAmount(uint _amount) public onlyOwner {
    MAX_UNIQUE_TRAIT = _amount;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  // view
  function getTraits(uint tokenId) public view returns (uint[9] memory) {
    uint[9] memory traits = Scholarz.getTraits(tokenIdToTokenMetadata[tokenId].scholarzId);
    if (tokenIdToTokenMetadata[tokenId].uniqueIndex != 0) {
      // special suit
      traits[7] = 40 + tokenIdToTokenMetadata[tokenId].uniqueIndex;
      traits[5] = 0;
    }
    // remove all extra items
    traits[8] = 0;
    return traits;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
  }
}