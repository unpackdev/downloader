// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";


interface IClayStorage {  
  function setStorage(uint256 id, uint128 key, uint256 value) external;
  function getStorage(uint256 id, uint128 key) external view returns (uint256);
}

// NOTE: Use 0 for uninitliased, 1 for false and 2 for true
// Likewise add 1 to every trait data when storing and subtract 1 when reading
contract ClayStorage is Ownable, IClayStorage {
  address public modifierContract;
  mapping (uint256 => mapping(uint128 => uint256)) public data;
  
  modifier onlyModifier() {
      require(modifierContract == _msgSender(), "onlyModifier: caller is not the modifier");
      _;
  }
  
  function setModifierContract(address _modifierContract) public onlyOwner {
    modifierContract = _modifierContract;
  }

  function setStorage(uint256 id, uint128 key, uint256 value) external onlyModifier {
    data[id][key] = value;
  }

  function getStorage(uint256 id, uint128 key) external view returns (uint256) {
    return data[id][key];
  }
}