// SPDX-License-Identifier: MIT
// infant level solidity, be gentle.
// lcfr.eth && @lcfr_eth

pragma solidity ^0.8.7;

import "./ETHRegistrarController.sol";

contract ENSBulkRegister {

  event log_named_string       (string key, string val);

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
    (bool sent, bytes memory data) = _payee.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }

  function doCommitloop(bytes32[] memory _commitments) external {
    for ( uint i = 0; i < _commitments.length; ++i ) {
      controller.commit(_commitments[i]);
    }
  }

  function doRegisterloop(string[] memory _names, bytes32[] memory _secrets, uint256 _duration) external payable { 

    uint256 totalPrice = rentPriceLoop(_names, _duration);

    require(_names.length == _secrets.length, "names/secrets length mismatch");
    require(msg.value >= totalPrice, "not enough eth sent.");
        
    for( uint i = 0; i < _names.length; ++i ) {
      uint price = controller.rentPrice(_names[i], _duration);
      controller.register{value: price}(_names[i], msg.sender, _duration, _secrets[i]);
      emit log_named_string("NameRegistered: ", _names[i]);
    }
        
    // refund extra funds back to the user.  
    if(msg.value > totalPrice) {
      //couldnt get the below to work so used call() :shrug: 
      //payable(msg.sender).transfer(msg.value - totalPrice);
      (bool sent, bytes memory data) = msg.sender.call{value: msg.value - totalPrice}("");
      require(sent, "refund failed.");
    }   
        
  }

  function rentPriceLoop(string[] memory _name, uint256 _duration) public view returns(uint total) {
    uint256 total;
    for (uint i = 0; i < _name.length; ++i) {
      total += controller.rentPrice(_name[i], _duration);
    }
    return total;
  }

}