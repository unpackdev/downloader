pragma solidity ^0.6.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BatchTransfer {

  function batchTransfer(IERC20 _token,address[] memory tos,uint256 amount ) public{
      for(uint i=0;i<tos.length;i++){
          _token.transferFrom(msg.sender,tos[i],amount);
      }
  }
  
}