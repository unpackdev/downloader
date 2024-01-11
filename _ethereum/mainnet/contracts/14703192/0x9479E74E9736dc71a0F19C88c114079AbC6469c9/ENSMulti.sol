// SPDX-License-Identifier: o0o0o0o0o00o
// Infant level solidity
// lcfr.eth
// birdapp: @lcfr_eth, github: lcfr_eth

pragma solidity ^0.8.7;

import "./ETHRegistrarController.sol";

contract ENSBulkRegister {

  event log       (string key, string val);

  address ETHRegistrarControllerContract = 0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5;
  ETHRegistrarController controller = ETHRegistrarController(ETHRegistrarControllerContract);

  address owner;

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "not owner.");
    _;
  }

  function _updateETHRegistrarControllerContract(address _newRegistrar) external onlyOwner {
    ETHRegistrarControllerContract = _newRegistrar;  
  }

  function _updateContractOwner(address _newOwner) external onlyOwner {
    owner = _newOwner;
  }

  function _emergencyWithdraw(address _payee) external onlyOwner {
    (bool sent,) = _payee.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }

  function doCommitloop(bytes32[] calldata _commitments) external {
    for ( uint i = 0; i < _commitments.length; ++i ) {
      controller.commit(_commitments[i]);
    }
  }

  function doRegisterloop(string[] calldata _names, bytes32[] calldata _secrets, uint256 _duration) external payable { 

    require(_names.length == _secrets.length, "names/secrets length mismatch");

    for( uint i = 0; i < _names.length; ++i ) {
      uint price = controller.rentPrice(_names[i], _duration);
      controller.register{value: price}(_names[i], msg.sender, _duration, _secrets[i]);
      emit log("Name Registered:", _names[i]);
    }
        
    payable(msg.sender).transfer(address(this).balance);
        
  }

  function rentPriceLoop(string[] calldata _names, uint256 _duration) external view returns(uint total) {
    for (uint i = 0; i < _names.length; ++i) {
      total += controller.rentPrice(_names[i], _duration);
    }
  }


}