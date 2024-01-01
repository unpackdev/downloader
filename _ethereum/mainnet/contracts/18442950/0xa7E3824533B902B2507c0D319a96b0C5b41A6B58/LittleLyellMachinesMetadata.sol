// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.17;

import "./MetadataP5JS.sol";

contract LittleLyellMachinesMetadata is MetadataP5JS {
  constructor(address _fileStore, address _scriptStorage, address _nftAddress, string memory _name, string memory _description, string memory _tokenImageURI) MetadataP5JS(_fileStore, _scriptStorage, _nftAddress, _name, _description, _tokenImageURI) {}

  function _generateTraits(bytes32 _hash) internal pure virtual override returns (string memory) {
    uint256 intHash = uint256(_hash);
    uint256 rockColorFamily = intHash % 1000;

    string memory material;
    if (rockColorFamily < 200) {
      material = "IRON";
    } else if (rockColorFamily < 500) {
      material = "COPPER";
    } else if (rockColorFamily < 650) {
      material = "OXIDE";
    } else if (rockColorFamily < 800) {
      material = "PYRITE";
    } else {
      material = "GRANITE";
    }

    uint256 rubbleNumber = uint256(keccak256(abi.encodePacked(intHash + 1))) % 1000;

    string memory rubble;
    if (rubbleNumber < 222) {
      rubble = "SPARSE";
    } else if (rubbleNumber < 666) {
      rubble = "MEDIUM";
    } else {
      rubble = "HEAVY";
    }

    return string.concat('{"trait_type":"MATERIAL","value":"', material,'"},{"trait_type":"SUPPLY","value":"', rubble,'"}');
  }
}