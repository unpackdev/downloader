// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IWRLD_Name_Service_Resolver.sol";
import "./IWRLD_Name_Service_Registry.sol";

contract WRLD_NameService_Resolver_V1 is IWRLD_Name_Service_Resolver {
  IWRLD_Name_Service_Registry immutable nameServiceRegistry;

  mapping(uint256 => mapping(string => StringRecord)) private wrldNameStringRecords;
  mapping(uint256 => string[]) private wrldNameStringRecordsList;

  mapping(uint256 => mapping(string => AddressRecord)) private wrldNameAddressRecords;
  mapping(uint256 => string[]) private wrldNameAddressRecordsList;

  mapping(uint256 => mapping(string => UintRecord)) private wrldNameUintRecords;
  mapping(uint256 => string[]) private wrldNameUintRecordsList;

  mapping(uint256 => mapping(string => IntRecord)) private wrldNameIntRecords;
  mapping(uint256 => string[]) private wrldNameIntRecordsList;

  mapping(bytes32 => string) private wrldNameStringEntries;
  mapping(bytes32 => address) private wrldNameAddressEntries;
  mapping(bytes32 => uint) private wrldNameUintEntries;
  mapping(bytes32 => int) private wrldNameIntEntries;

  constructor(address _nameServiceRegistry) {
    nameServiceRegistry = IWRLD_Name_Service_Registry(_nameServiceRegistry);
  }

  /******************
   * Record Setters *
   ******************/

  function setStringRecord(string calldata _name, string calldata _record, string calldata _value, string calldata _typeOf, uint256 _ttl) external override onlyNameServiceRegistry {
    wrldNameStringRecords[_getNameTokenId(_name)][_record] = StringRecord({
      value: _value,
      typeOf: _typeOf,
      ttl: _ttl
    });

    wrldNameStringRecordsList[_getNameTokenId(_name)].push(_record);

    emit StringRecordUpdated(_name, _name, _record, _value, _typeOf, _ttl);
  }

  function setAddressRecord(string memory _name, string memory _record, address _value, uint256 _ttl) external override onlyNameServiceRegistry {
    wrldNameAddressRecords[_getNameTokenId(_name)][_record] = AddressRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameAddressRecordsList[_getNameTokenId(_name)].push(_record);

    emit AddressRecordUpdated(_name, _name, _record, _value, _ttl);
  }

  function setUintRecord(string calldata _name, string calldata _record, uint256 _value, uint256 _ttl) external override onlyNameServiceRegistry {
    wrldNameUintRecords[_getNameTokenId(_name)][_record] = UintRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameUintRecordsList[_getNameTokenId(_name)].push(_record);

    emit UintRecordUpdated(_name, _name, _record, _value, _ttl);
  }

  function setIntRecord(string calldata _name, string calldata _record, int256 _value, uint256 _ttl) external override onlyNameServiceRegistry {
    wrldNameIntRecords[_getNameTokenId(_name)][_record] = IntRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameIntRecordsList[_getNameTokenId(_name)].push(_record);

    emit IntRecordUpdated(_name, _name, _record, _value, _ttl);
  }

  /******************
   * Record Getters *
   ******************/

  function getNameStringRecord(string calldata _name, string calldata _record) external view override returns (StringRecord memory) {
    return wrldNameStringRecords[_getNameTokenId(_name)][_record];
  }

  function getNameStringRecordsList(string calldata _name) external view override returns (string[] memory) {
    return wrldNameStringRecordsList[_getNameTokenId(_name)];
  }

  function getNameAddressRecord(string calldata _name, string calldata _record) external view override returns (AddressRecord memory) {
    return wrldNameAddressRecords[_getNameTokenId(_name)][_record];
  }

  function getNameAddressRecordsList(string calldata _name) external view override returns (string[] memory) {
    return wrldNameAddressRecordsList[_getNameTokenId(_name)];
  }

  function getNameUintRecord(string calldata _name, string calldata _record) external view override returns (UintRecord memory) {
    return wrldNameUintRecords[_getNameTokenId(_name)][_record];
  }

  function getNameUintRecordsList(string calldata _name) external view override returns (string[] memory) {
    return wrldNameUintRecordsList[_getNameTokenId(_name)];
  }

  function getNameIntRecord(string calldata _name, string calldata _record) external view override returns (IntRecord memory) {
    return wrldNameIntRecords[_getNameTokenId(_name)][_record];
  }

  function getNameIntRecordsList(string calldata _name) external view override returns (string[] memory) {
    return wrldNameIntRecordsList[_getNameTokenId(_name)];
  }

  /*****************
   * Entry Setters *
   *****************/

  function setStringEntry(address _setter, string calldata _name, string calldata _entry, string calldata _value) external override onlyNameServiceRegistry {
    wrldNameStringEntries[_getEntryHash(_setter, _name, _entry)] = _value;
  }

  function setAddressEntry(address _setter, string calldata _name, string calldata _entry, address _value) external override onlyNameServiceRegistry {
    wrldNameAddressEntries[_getEntryHash(_setter, _name, _entry)] = _value;
  }

  function setUintEntry(address _setter, string calldata _name, string calldata _entry, uint256 _value) external override onlyNameServiceRegistry {
    wrldNameUintEntries[_getEntryHash(_setter, _name, _entry)] = _value;
  }

  function setIntEntry(address _setter, string calldata _name, string calldata _entry, int256 _value) external override onlyNameServiceRegistry {
    wrldNameIntEntries[_getEntryHash(_setter, _name, _entry)] = _value;
  }

  /*****************
   * Entry Getters *
   *****************/

  function getStringEntry(address _setter, string calldata _name, string calldata _entry) external view override returns (string memory) {
    return wrldNameStringEntries[_getEntryHash(_setter, _name, _entry)];
  }

  function getAddressEntry(address _setter, string calldata _name, string calldata _entry) external view override returns (address) {
    return wrldNameAddressEntries[_getEntryHash(_setter, _name, _entry)];
  }

  function getUintEntry(address _setter, string calldata _name, string calldata _entry) external view override returns (uint256) {
    return wrldNameUintEntries[_getEntryHash(_setter, _name, _entry)];
  }

  function getIntEntry(address _setter, string calldata _name, string calldata _entry) external view override returns (int256) {
    return wrldNameIntEntries[_getEntryHash(_setter, _name, _entry)];
  }

  /**********
   * ERC165 *
   **********/

  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == type(IWRLD_Name_Service_Resolver).interfaceId;
  }

  /***********
   * Helpers *
   ***********/

  function _getNameTokenId(string memory _name) private view returns (uint256) {
    return nameServiceRegistry.getNameTokenId(_name);
  }

  function _getEntryHash(address _setter, string memory _name, string memory _entry) private pure returns (bytes32) {
    return keccak256(abi.encode(_setter, _name, _entry));
  }

  /*************
   * Modifiers *
   *************/

  modifier onlyNameServiceRegistry() {
    require(msg.sender == address(nameServiceRegistry), "Sender is not name service.");
    _;
  }
}
