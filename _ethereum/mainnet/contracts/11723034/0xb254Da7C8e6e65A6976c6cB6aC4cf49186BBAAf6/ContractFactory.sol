pragma solidity ^0.6.0;

contract ContractFactory {
    
  event Deployed(address);
  
  function deploy(bytes memory _bytecode) public returns(address) {
    address addr;
    uint salt = block.timestamp;
      
    assembly {
      addr := create2(0, add(_bytecode, 0x20), mload(_bytecode), salt)
    }
    
    require(addr != address(0), "ContractFactory: not deployed");
    
    emit Deployed(addr);
    
    return addr;
  }
}