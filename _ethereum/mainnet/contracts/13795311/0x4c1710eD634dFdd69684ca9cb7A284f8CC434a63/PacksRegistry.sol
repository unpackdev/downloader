// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./ERC165Checker.sol";

/// @title PacksRegistry
/// @notice PacksRegistry is a registry defining permissions for the Packs
contract PacksRegistry is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;
  using ERC165Checker for address;

  EnumerableSet.AddressSet allowed721Contracts;
  EnumerableSet.AddressSet allowed1155Contracts;

  address public creatorAddress = msg.sender;

  constructor() {  }

  function add721Contract(address _contract) external onlyOwner {
    allowed721Contracts.add(_contract);
  }

  function add1155Contract(address _contract) external onlyOwner {
    allowed1155Contracts.add(_contract);
  }

  function remove721Contract(address _contract) external onlyOwner {
    allowed721Contracts.remove(_contract);
  }

  function remove1155Contract(address _contract) external onlyOwner {
    allowed1155Contracts.remove(_contract);
  }

  function isValidContract(address _contract) external view returns (bool) {
    return isValid721Contract(_contract) || isValid1155Contract(_contract);
  }

  function isValid721Contract(address _contract) public view returns (bool) {
    return allowed721Contracts.contains(_contract);
  }

  function isValid1155Contract(address _contract) public view returns (bool) {
    return allowed1155Contracts.contains(_contract);
  }
}