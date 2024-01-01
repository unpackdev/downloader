// SPDX-License-Identifier: GPL-3.0

// Presented by Wildxyz

pragma solidity ^0.8.17;

import "./Ownable.sol";

import "./LibraryStorage_v1_0.sol";

abstract contract MetadataBase is Ownable {
  struct ScriptData {
    LibraryStorage_v1_0 libraryStorage;
    LibraryStorage_v1_0 scriptStorage;
    string libraryName;
  }

  ScriptData public scriptData;

  constructor(address _libraryStorage, address _scriptStorage, string memory libraryName) {
    if (_libraryStorage != address(0)) _setLibraryStorage(_libraryStorage);
    if (_scriptStorage != address(0)) _setScriptStorage(_scriptStorage);
    
    scriptData.libraryName = libraryName;
  }

  // string bytes util
  function _toHex16(bytes16 data) internal pure returns (bytes32 result) {
    result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
      (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
    result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
      (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
    result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
      (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
    result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
      (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
    result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
      (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
    result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
      uint256 (result) +
      (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
      0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 7);
  }

  function _toHex(bytes32 data) internal pure returns (string memory) {
    return string (abi.encodePacked ('0x', _toHex16(bytes16 (data)), _toHex16(bytes16 (data << 128))));
  }
  // eof string bytes util

  function _setLibraryStorage(address _libraryStorage) internal {
    scriptData.libraryStorage = LibraryStorage_v1_0(_libraryStorage);
  }

  function _setScriptStorage(address _scriptStorage) internal {
    scriptData.scriptStorage = LibraryStorage_v1_0(_scriptStorage);
  }

  function getLibrary() public view returns (string memory) {
    return scriptData.libraryStorage.readLibrary(scriptData.libraryName);
  }

  function getScript() public view returns (string memory) {
    return scriptData.scriptStorage.readLibrary('script');
  }

  function getLibraryName() public view returns (string memory) {
    return scriptData.libraryName;
  }

  // implement in parent contract
  function tokenURI(uint256 _tokenId) public view virtual returns (string memory);

  // optional setters to be implemented in parent contract
  function setScriptStorage(address _scriptStorage) public virtual;
  function setLibraryStorage(address _libraryStorage) public virtual;
}