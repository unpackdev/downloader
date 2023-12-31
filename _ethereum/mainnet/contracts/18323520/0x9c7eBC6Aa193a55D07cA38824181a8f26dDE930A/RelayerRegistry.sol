// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./Ownable.sol";

contract RelayerRegistry is Ownable {
  mapping(address => bool) public isRelayer;

  event RelayerAdded(address indexed relayer);
  event RelayerRemoved(address indexed relayer);

  /**
      @dev Add a new relayer.
      @param _relayer A new relayer address
    */
  function add(address _relayer) public onlyOwner {
    require(!isRelayer[_relayer], "The relayer already exists");
    isRelayer[_relayer] = true;
    emit RelayerAdded(_relayer);
  }

  /**
      @dev Remove a new relayer.
      @param _relayer A new relayer address to remove
    */
  function remove(address _relayer) public onlyOwner {
    require(isRelayer[_relayer], "The relayer does not exist");
    isRelayer[_relayer] = false;
    emit RelayerRemoved(_relayer);
  }

  /**
      @dev Check address intance is a relayer?
      @param _relayer A relayer address to check
      @return true or false
    */
  function isRelayerRegistered(address _relayer) external view returns (bool) {
    return isRelayer[_relayer];
  }
}
