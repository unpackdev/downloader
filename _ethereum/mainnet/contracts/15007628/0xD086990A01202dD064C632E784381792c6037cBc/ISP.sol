// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISP {  
  event CollaboratorAdded(address collaborator, uint256 split);
  event PaymentTransferred(address collaborator, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

    function initialize(address[] memory collaborators, uint256[] memory splits) external;

   function splitPaymentERC20(address from, address tokenAddress, uint256 totalAmount) external;

   function splitPayment(address from) external payable;

   function getTotalSplits() external returns(uint256);

}