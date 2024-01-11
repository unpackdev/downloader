// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

import "./ERC721AF.sol";
import "./IWNS_Passes.sol";
import "./IWRLD_Name_Service_Bridge.sol";
import "./IWRLD_Name_Service_Metadata.sol";
import "./IWRLD_Name_Service_Resolver.sol";
import "./IWRLD_Name_Service_Registry.sol";
import "./StringUtils.sol";

contract WRLD_Name_Service_Registry is ERC721AF, IWRLD_Name_Service_Registry, IWRLD_Records, Ownable, ReentrancyGuard {
  using StringUtils for *;

  /**
   * @dev @iamarkdev was here
   * @dev @niftyorca was here
   * */

  IWRLD_Name_Service_Metadata metadata;
  IWRLD_Name_Service_Resolver resolver;
  IWRLD_Name_Service_Bridge bridge;

  uint256 private constant YEAR_SECONDS = 31536000;

  mapping(uint256 => WRLDName) public wrldNames;
  mapping(string => uint256) private nameTokenId;

  address private approvedWithdrawer;
  mapping(address => bool) private approvedRegistrars;

  struct WRLDName {
    string name;
    address controller;
    uint256 expiresAt;
  }

  constructor() ERC721AF("WRLD Name Service", "WNS") {}

  /************
   * Metadata *
   ************/

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return metadata.getMetadata(wrldNames[_tokenId].name, wrldNames[_tokenId].expiresAt);
  }

  /****************
   * Registration *
   ****************/

  function register(address _registerer, string[] calldata _names, uint16[] memory _registrationYears) external override isApprovedRegistrar {
    require(_names.length == _registrationYears.length, "Arg size mismatched");

    uint256 mintCount = 0;
    uint256 tokenStartId = _currentIndex;

    for (uint256 i = 0; i < _names.length; i++) {
      require(_registrationYears[i] > 0, "Years must be greater than 0");

      string memory name = _names[i].UTS46Normalize();
      uint256 expiresAt = block.timestamp + YEAR_SECONDS * _registrationYears[i];

      if (nameExists(name)) {
        require(getNameExpiration(name) < block.timestamp, "Unavailable name");

        uint256 existingTokenId = nameTokenId[name];

        wrldNames[existingTokenId].expiresAt = expiresAt;

        _safeTransferFromForced(getNameOwner(name), _registerer, existingTokenId, "");
      } else {
        uint256 newTokenId = tokenStartId + mintCount;

        wrldNames[newTokenId] = WRLDName({
          name: name,
          controller: _registerer,
          expiresAt: expiresAt
        });

        nameTokenId[name] = newTokenId;

        mintCount++;

        emit NameRegistered(name, name, _registrationYears[i]);
      }
    }

    if (mintCount > 0) {
      _safeMint(_registerer, mintCount);
    }
  }

  /*************
   * Extension *
   *************/

  function extendRegistration(string[] calldata _names, uint16[] calldata _additionalYears) external override isApprovedRegistrar {
    require(_names.length == _additionalYears.length, "Arg size mismatched");

    for (uint256 i = 0; i < _names.length; i++) {
      require(_additionalYears[i] > 0, "Years must be greater than zero");

      WRLDName storage wrldName = wrldNames[nameTokenId[_names[i]]];
      wrldName.expiresAt = wrldName.expiresAt + YEAR_SECONDS * _additionalYears[i];

      emit NameRegistrationExtended(_names[i], _names[i], _additionalYears[i]);
    }

    if (hasBridge()) {
      bridge.extendRegistration(_names, _additionalYears);
    }
  }

  /***********
   * Resolve *
   ***********/

  function nameAvailable(string memory _name) external view returns (bool) {
    return !nameExists(_name) || getNameExpiration(_name) < block.timestamp;
  }

  function nameExists(string memory _name) public view returns (bool) {
    return nameTokenId[_name] != 0;
  }

  function getNameTokenId(string calldata _name) external view override returns (uint256) {
    return nameTokenId[_name];
  }

  function getTokenName(uint256 _tokenId) external view returns (string memory) {
    return wrldNames[_tokenId].name;
  }

  function getName(string calldata _name) external view returns (WRLDName memory) {
    return wrldNames[nameTokenId[_name]];
  }

  function getNameOwner(string memory _name) public view returns (address) {
    return ownerOf(nameTokenId[_name]);
  }

  function getNameController(string memory _name) public view returns (address) {
    return wrldNames[nameTokenId[_name]].controller;
  }

  function getNameExpiration(string memory _name) public view returns (uint256) {
    return wrldNames[nameTokenId[_name]].expiresAt;
  }

  function getNameStringRecord(string calldata _name, string calldata _record) external view returns (StringRecord memory) {
    return resolver.getNameStringRecord(_name, _record);
  }

  function getNameStringRecordsList(string calldata _name) external view returns (string[] memory) {
    return resolver.getNameStringRecordsList(_name);
  }

  function getNameAddressRecord(string calldata _name, string calldata _record) external view returns (AddressRecord memory) {
    return resolver.getNameAddressRecord(_name, _record);
  }

  function getNameAddressRecordsList(string calldata _name) external view returns (string[] memory) {
    return resolver.getNameAddressRecordsList(_name);
  }

  function getNameUintRecord(string calldata _name, string calldata _record) external view returns (UintRecord memory) {
    return resolver.getNameUintRecord(_name, _record);
  }

  function getNameUintRecordsList(string calldata _name) external view returns (string[] memory) {
    return resolver.getNameUintRecordsList(_name);
  }

  function getNameIntRecord(string calldata _name, string calldata _record) external view returns (IntRecord memory) {
    return resolver.getNameIntRecord(_name, _record);
  }

  function getNameIntRecordsList(string calldata _name) external view returns (string[] memory) {
    return resolver.getNameIntRecordsList(_name);
  }

  function getStringEntry(address _setter, string calldata _name, string calldata _entry) external view returns (string memory) {
    return resolver.getStringEntry(_setter, _name, _entry);
  }

  function getAddressEntry(address _setter, string calldata _name, string calldata _entry) external view returns (address) {
    return resolver.getAddressEntry(_setter, _name, _entry);
  }

  function getUintEntry(address _setter, string calldata _name, string calldata _entry) external view returns (uint256) {
    return resolver.getUintEntry(_setter, _name, _entry);
  }

  function getIntEntry(address _setter, string calldata _name, string calldata _entry) external view returns (int256) {
    return resolver.getIntEntry(_setter, _name, _entry);
  }

  /***********
   * Control *
   ***********/

  function migrate(string calldata _name, uint256 _networkFlags) external isOwnerOrController(_name) {
    require(hasBridge(), "Bridge not set");

    bridge.migrate(_name, _networkFlags);
  }

  function setController(string calldata _name, address _controller) external {
    require(getNameOwner(_name) == msg.sender, "Sender is not owner");

    wrldNames[nameTokenId[_name]].controller = _controller;

    emit NameControllerUpdated(_name, _name, _controller);

    if (hasBridge()) {
      bridge.setController(_name, _controller);
    }
  }

  function setStringRecord(string calldata _name, string calldata _record, string calldata _value, string calldata _typeOf, uint256 _ttl) external isOwnerOrController(_name) {
    resolver.setStringRecord(_name, _record, _value, _typeOf, _ttl);

    emit ResolverStringRecordUpdated(_name, _name, _record, _value, _typeOf, _ttl, address(resolver));

    if (hasBridge()) {
      bridge.setStringRecord(_name, _record, _value, _typeOf, _ttl);
    }
  }

  function setAddressRecord(string memory _name, string memory _record, address _value, uint256 _ttl) external isOwnerOrController(_name) {
    resolver.setAddressRecord(_name, _record, _value, _ttl);

    emit ResolverAddressRecordUpdated(_name, _name, _record, _value, _ttl, address(resolver));

    if (hasBridge()) {
      bridge.setAddressRecord(_name, _record, _value, _ttl);
    }
  }

  function setUintRecord(string calldata _name, string calldata _record, uint256 _value, uint256 _ttl) external isOwnerOrController(_name) {
    resolver.setUintRecord(_name, _record, _value, _ttl);

    emit ResolverUintRecordUpdated(_name, _name, _record, _value, _ttl, address(resolver));

    if (hasBridge()) {
      bridge.setUintRecord(_name, _record, _value, _ttl);
    }
  }

  function setIntRecord(string calldata _name, string calldata _record, int256 _value, uint256 _ttl) external isOwnerOrController(_name) {
    resolver.setIntRecord(_name, _record, _value, _ttl);

    emit ResolverIntRecordUpdated(_name, _name, _record, _value, _ttl, address(resolver));

    if (hasBridge()) {
      bridge.setIntRecord(_name, _record, _value, _ttl);
    }
  }

  /***********
   * Entries *
   ***********/

  function setStringEntry(string calldata _name, string calldata _entry, string calldata _value) external {
    resolver.setStringEntry(msg.sender, _name, _entry, _value);

    emit ResolverStringEntryUpdated(msg.sender, _name, _entry, _name, _entry, _value);

    if (hasBridge()) {
      bridge.setStringEntry(msg.sender, _name, _entry, _value);
    }
  }

  function setAddressEntry(string calldata _name, string calldata _entry, address _value) external {
    resolver.setAddressEntry(msg.sender, _name, _entry, _value);

    emit ResolverAddressEntryUpdated(msg.sender, _name, _entry, _name, _entry, _value);

    if (hasBridge()) {
      bridge.setAddressEntry(msg.sender, _name, _entry, _value);
    }
  }

  function setUintEntry(string calldata _name, string calldata _entry, uint256 _value) external {
    resolver.setUintEntry(msg.sender, _name, _entry, _value);

    emit ResolverUintEntryUpdated(msg.sender, _name, _entry, _name, _entry, _value);

    if (hasBridge()) {
      bridge.setUintEntry(msg.sender, _name, _entry, _value);
    }
  }

  function setIntEntry(string calldata _name, string calldata _entry, int256 _value) external {
    resolver.setIntEntry(msg.sender, _name, _entry, _value);

    emit ResolverIntEntryUpdated(msg.sender, _name, _entry, _name, _entry, _value);

    if (hasBridge()) {
      bridge.setIntEntry(msg.sender, _name, _entry, _value);
    }
  }

  /*********
   * Owner *
   *********/

  function setApprovedWithdrawer(address _approvedWithdrawer) external onlyOwner {
    approvedWithdrawer = _approvedWithdrawer;
  }

  function setApprovedRegistrar(address _approvedRegistrar, bool _approved) external onlyOwner {
    approvedRegistrars[_approvedRegistrar] = _approved;
  }

  function setMetadataContract(address _metadata) external onlyOwner {
    IWRLD_Name_Service_Metadata metadataContract = IWRLD_Name_Service_Metadata(_metadata);

    require(metadataContract.supportsInterface(type(IWRLD_Name_Service_Metadata).interfaceId), "Invalid metadata contract");

    metadata = metadataContract;
  }

  function setResolverContract(address _resolver) external onlyOwner {
    IWRLD_Name_Service_Resolver resolverContract = IWRLD_Name_Service_Resolver(_resolver);

    require(resolverContract.supportsInterface(type(IWRLD_Name_Service_Resolver).interfaceId), "Invalid resolver contract");

    resolver = resolverContract;
  }

  function setBridgeContract(address _bridge) external onlyOwner {
    IWRLD_Name_Service_Bridge bridgeContract = IWRLD_Name_Service_Bridge(_bridge);

    require(bridgeContract.supportsInterface(type(IWRLD_Name_Service_Bridge).interfaceId), "Invalid bridge contract");

    bridge = bridgeContract;
  }

  /*************
   * Overrides *
   *************/

  function _startTokenId() internal pure override returns (uint256) {
    return 1; // must start at 1, id 0 is used as non-existant check.
  }

  function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
    for (uint256 i = 0; i < quantity; i++) {
      uint256 tokenId = startTokenId + i;
      WRLDName storage wrldName = wrldNames[tokenId];

      wrldName.controller = to;

      resolver.setAddressRecord(wrldName.name, "evm_default", to, 3600);
      emit ResolverAddressRecordUpdated(wrldName.name, wrldName.name, "evm_default", to, 3600, address(resolver));

      if (hasBridge()) {
        bridge.transfer(from, to, tokenId, wrldName.name);
      }
    }

    super._afterTokenTransfers(from, to, startTokenId, quantity);
  }

  /***********
   * Helpers *
   ***********/

  function hasBridge() private view returns (bool) {
    return address(bridge) != address(0);
  }

  /*************
   * Modifiers *
   *************/

  modifier isApprovedRegistrar() {
    require(approvedRegistrars[msg.sender], "msg sender is not registrar");
    _;
  }

  modifier isOwnerOrController(string memory _name) {
    require((getNameOwner(_name) == msg.sender || getNameController(_name) == msg.sender), "Sender is not owner or controller");
    _;
  }
}
