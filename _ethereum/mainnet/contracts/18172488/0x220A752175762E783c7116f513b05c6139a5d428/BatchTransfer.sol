pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./Ownable.sol";

contract BatchTransfer is Ownable {

  function batchTransfer(
     address[] calldata recipients,
     uint256[] calldata amounts,
     address tokenAddress
   ) external payable onlyOwner {

        if(recipients.length != amounts.length) {
            revert("Array length mismatch recipient,amounts");
        }
        
        IERC20 token = IERC20(tokenAddress);

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            token.transferFrom(msg.sender, recipient, amounts[i]);
        }
    }
}