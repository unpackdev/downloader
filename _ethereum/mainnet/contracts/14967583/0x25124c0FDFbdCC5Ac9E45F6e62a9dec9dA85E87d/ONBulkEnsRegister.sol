// SPDX-License-Identifier: MIT
// https://othername.xyz

pragma solidity ^0.8.14;

import "./ETHRegistrarController.sol";

contract ONBulkEnsRegister {

  address public RegistrarContract = 0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5;

  ETHRegistrarController controller = ETHRegistrarController(RegistrarContract);

  address owner;
  address withdrawAccount;

  constructor(address _withdrawAccount) {
    owner = msg.sender;
    withdrawAccount = _withdrawAccount;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "you are not owner.");
    _;
  }

  function getOwner() public view returns (address) {    
      return owner;
  }

  function _updateOwner(address _newOwner) external onlyOwner {
    owner = _newOwner;
  }

  function _withdraw() external onlyOwner {
    (bool success,) = withdrawAccount.call{value: address(this).balance}("");
    require(success, "Failed to send Ether");
  }

  function commit(string[] calldata _names, bytes32 _secret) external {
    require(_names.length > 0, "name list is empty");
    for ( uint i = 0; i < _names.length; ++i ) {
      bytes32 commitment = controller.makeCommitment(_names[i], msg.sender, _secret);
      controller.commit(commitment);
    }
  }

  function register(string[] calldata _names, uint256[] calldata _durations, bytes32 _secret) external payable { 
    require(_names.length == _durations.length, "number of names and durations are not equal");
    
    for( uint i = 0; i < _names.length; ++i ) {
      uint price = controller.rentPrice(_names[i], _durations[i]);
      controller.register{value: price}(_names[i], msg.sender, _durations[i], _secret);
    }
  }

  function renew(string[] calldata _names, uint256[] calldata _durations) external payable { 
    require(_names.length == _durations.length, "number of names and durations are not equal");
    
    for( uint i = 0; i < _names.length; ++i ) {
      uint price = controller.rentPrice(_names[i], _durations[i]);
      controller.renew{value: price}(_names[i], _durations[i]);
    }
  }

  function multiNamePrices(string[] calldata _names, uint256[] calldata _durations) external view returns(uint[] memory) {
    require(_names.length == _durations.length, "number of names and durations are not equal");
    uint[] memory prices = new uint[](_names.length);
    for (uint i = 0; i < _names.length; ++i) {
      bool available = controller.available(_names[i]);
      if (available) {
        prices[i] = controller.rentPrice(_names[i], _durations[i]);
      }
      else {
        prices[i] = 0;
      }
    }
    return prices;
  }

  function multiCall(address _who, bytes[] calldata _what) external returns(bytes[] memory results) {
    results = new bytes[](_what.length);
    for(uint i = 0; i < _what.length; ++i) {
        (bool success, bytes memory result) = _who.delegatecall(_what[i]);
        require(success);
        results[i] = result;
    }
    return results;
  }
}