// SPDX-License-Identifier: MIT
// https://othername.xyz
// Special thanks to @lcfr_eth for original work, the implementation of this contract was inspired by it.

pragma solidity ^0.8.14;

import "./ETHRegistrarController.sol";

contract ONBulkEnsRegister {

  address private _controllerAddress;
  address private _owner;

  constructor() {
    _owner = msg.sender;
    _controllerAddress = 0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5;
  }

  modifier onlyOwner {
    require(msg.sender == _owner, "Caller of the function is not the owner.");
    _;
  }

  function getOwner() public view returns (address) {    
      return _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _owner = newOwner;
  }

  function getControllerAddress() public view returns (address) {
    return _controllerAddress;
  }

  function updateControllerAddress(address newControllerAddress) public onlyOwner {
    _controllerAddress = newControllerAddress;
  }

  function withdraw() external onlyOwner {
    (bool success,) = _owner.call{value: address(this).balance}("");
    require(success, "Failed to withdraw");
  }

  function commit(string[] calldata names, bytes32 secret) external {
    require(names.length > 0, "Name list is empty");
    ETHRegistrarController controller = ETHRegistrarController(_controllerAddress);
    for ( uint i = 0; i < names.length; ++i ) {
      bytes32 commitment = controller.makeCommitment(names[i], msg.sender, secret);
      controller.commit(commitment);
    }
  }

  function register(string[] calldata names, uint256[] calldata durations, bytes32 secret) external payable { 
    require(names.length == durations.length, "Number of names and durations are not equal");
    ETHRegistrarController controller = ETHRegistrarController(_controllerAddress);
    for( uint i = 0; i < names.length; ++i ) {
      uint price = controller.rentPrice(names[i], durations[i]);
      controller.register{value: price}(names[i], msg.sender, durations[i], secret);
    }
  }

  function renew(string[] calldata names, uint256[] calldata durations) external payable { 
    require(names.length == durations.length, "Number of names and durations are not equal");
    ETHRegistrarController controller = ETHRegistrarController(_controllerAddress);
    for( uint i = 0; i < names.length; ++i ) {
      uint price = controller.rentPrice(names[i], durations[i]);
      controller.renew{value: price}(names[i], durations[i]);
    }
  }

  function multiNamePrices(string[] calldata names, uint256[] calldata durations) external view returns(uint[] memory) {
    require(names.length == durations.length, "Number of names and durations are not equal");
    ETHRegistrarController controller = ETHRegistrarController(_controllerAddress);
    uint[] memory prices = new uint[](names.length);
    for (uint i = 0; i < names.length; ++i) {
      bool available = controller.available(names[i]);
      if (available) {
        prices[i] = controller.rentPrice(names[i], durations[i]);
      }
      else {
        prices[i] = 0;
      }
    }
    return prices;
  }
}