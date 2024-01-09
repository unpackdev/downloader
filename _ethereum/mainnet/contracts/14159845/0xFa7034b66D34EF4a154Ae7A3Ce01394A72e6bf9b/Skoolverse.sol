// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721Upgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

interface IScholarz {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function isApprovedForAll(address owner, address operator) external view returns (bool);
  function transferFrom(address from, address to, uint256 tokenId) external;  
}

contract Skoolverse is ERC721Upgradeable, ERC721PausableUpgradeable, OwnableUpgradeable {
  using StringsUpgradeable for uint256;
  using ECDSAUpgradeable for bytes32;
  IScholarz Scholarz;
  uint public totalClaimed;
  uint public activationTime;
  bool public claimStarted;
  bool public openHouse;
  address private _signer;
  string private _tokenBaseURI;
  mapping(uint => bool) public landActive;
  mapping(uint => uint) public homeOf;
  mapping(uint => uint) public tenantOf;
  mapping(uint => uint) public placedAt;
  mapping(uint => uint) public removedAt;
  mapping(uint => address) public placedBy;
  mapping(bytes32 => bool) public usedKey;  
  event Claimed(address indexed from, bytes32 indexed key, uint[] TokenIds, uint timestamp);  
  event Stay(address indexed from, uint indexed TenantId, uint timestamp);
  event Leave(address indexed from, uint indexed TenantId, uint timestamp);
  event Activated(address indexed from, bytes32 indexed key, uint[] LandIds, uint timestamp);

  function initialize() public initializer {
    __ERC721_init("Skoolverse", "SKV");
    __Ownable_init();
    _signer = 0xBc9eebF48B2B8B54f57d6c56F41882424d632EA7;
    activationTime = 2 weeks;
    removedAt[0] = 1;
  }

  // internal
  function claim(uint _tokenId) internal {
    require(_tokenId <= 2500, "Only Genesis allowed");
    require(Scholarz.ownerOf(_tokenId) == msg.sender, "You don't own this Scholarz ID");
    _safeMint(msg.sender, _tokenId);
    totalClaimed++;
  }
  
  function stay(uint _scholarzId, uint _landId) internal {
    require(_scholarzId <= 2500, "Only Genesis allowed");
    require(_landId <= 2500, "ID > 2500");
    require(ownerOf(_landId) == msg.sender, "Not owner of this land");
    require(homeOf[tenantOf[_landId]] != _landId || removedAt[tenantOf[_landId]] != 0, "Land is already occupied");
    Scholarz.transferFrom(msg.sender, address(this), _scholarzId);
    homeOf[_scholarzId] = _landId;
    tenantOf[_landId] = _scholarzId;
    placedAt[_scholarzId] = block.timestamp;
    removedAt[_scholarzId] = 0;
    placedBy[_scholarzId] = address(msg.sender);
    emit Stay(msg.sender, _scholarzId, block.timestamp);
  }

  function leave(uint _scholarzId) internal {
    require(placedBy[_scholarzId] == msg.sender, "Not owner of this Scholarz");
    Scholarz.transferFrom(address(this), msg.sender, _scholarzId);
    if (removedAt[_scholarzId] == 0) {
      // staking is active, set removedAt to now
      landActive[homeOf[_scholarzId]] = false;
      tenantOf[homeOf[_scholarzId]] = 0;  
      removedAt[_scholarzId] = block.timestamp;
    }
    homeOf[_scholarzId] = 0;
    placedBy[_scholarzId] = address(0);
    emit Leave(msg.sender, _scholarzId, block.timestamp);
  }

  function activate(uint _landId) internal {
    require(!landActive[_landId], "Land is already activated");
    require(ownerOf(_landId) == msg.sender, "Land is not yours");
    require(homeOf[tenantOf[_landId]] == _landId, "Tenant is not your scholarz");
    require(removedAt[tenantOf[_landId]] == 0, "Scholarz is not staked");
    require(block.timestamp - placedAt[tenantOf[_landId]] >= activationTime, "Land is not ready");
    landActive[_landId] = true;
  }

  function _beforeTokenTransfer(address from, address, uint256 tokenId) internal whenNotPaused override(ERC721Upgradeable, ERC721PausableUpgradeable) {
    if (from != address(0)) {
      landActive[tokenId] = false;
      if (removedAt[tenantOf[tokenId]] == 0) {
        removedAt[tenantOf[tokenId]] = block.timestamp;
      }
    }
    // super._beforeTokenTransfer(from, to, tokenId);
  }

  // external
  function claimMultiple(bytes32 key, bytes calldata signature, uint[] memory _tokenIds, uint timestamp) external {
    require(!usedKey[key], "Key has been used.");
    require(block.timestamp < timestamp, "Expired mint time.");
    require(keccak256(abi.encode(msg.sender, "claim", _tokenIds, timestamp, key)).toEthSignedMessageHash().recover(signature) == _signer, "Invalid signature");
    require(claimStarted, "Not yet started");
    for (uint i = 0; i < _tokenIds.length; i++) {
      claim(_tokenIds[i]);
    }
    usedKey[key] = true;
    emit Claimed(msg.sender, key, _tokenIds, block.timestamp);
  }

  function stayTogether(uint[] memory _scholarzIds, uint[] memory _landIds) external {
    require(openHouse, "Not yet started");
    require(Scholarz.isApprovedForAll(msg.sender, address(this)), "Contract is not approved");
    require(_scholarzIds.length == _landIds.length, "Amount does not match");
    for (uint i = 0; i < _scholarzIds.length; i++) {
      stay(_scholarzIds[i], _landIds[i]);
    }
  }
  
  function leaveTogether(uint[] memory _scholarzIds) external {
    require(Scholarz.isApprovedForAll(msg.sender, address(this)), "Contract is not approved");
    for (uint i = 0; i < _scholarzIds.length; i++) {
      leave(_scholarzIds[i]);
    }
  }

  function activateMultiple(bytes32 key, bytes calldata signature, uint[] memory _landIds, uint timestamp) external {
    require(!usedKey[key], "Key has been used.");
    require(block.timestamp < timestamp, "Expired mint time.");
    require(keccak256(abi.encode(msg.sender, "activate", _landIds, timestamp, key)).toEthSignedMessageHash().recover(signature) == _signer, "Invalid signature");
    for (uint i = 0; i < _landIds.length; i++) {
      activate(_landIds[i]);
    }
    usedKey[key] = true;
    emit Activated(msg.sender, key, _landIds, block.timestamp);
  }

  // onlyOwner
  function setScholarzAddress(address _address) public onlyOwner {
    Scholarz = IScholarz(_address);
  }

  function setSignerAddress(address _address) public onlyOwner {
    _signer = _address;
  }

  function setBaseURI(string memory URI) public onlyOwner {
    _tokenBaseURI = URI;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function toggleClaimStart() public onlyOwner {
    claimStarted = !claimStarted;
  }

  function toggleStakeStart() public onlyOwner {
    openHouse = !openHouse;
  }

  function setActivationTime(uint _seconds) public onlyOwner {
    activationTime = _seconds;
  }

  // view
  function isClaimed(uint _landId) external view returns (bool) {
    return (_exists(_landId));
  }

  function lastStayDuration(uint _scholarzId) external view returns(uint) {
    if (removedAt[_scholarzId] == 0 && placedAt[_scholarzId] != 0) {
      return block.timestamp - placedAt[_scholarzId];
    } else {
      return removedAt[_scholarzId] - placedAt[_scholarzId];
    }
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
  }

}
