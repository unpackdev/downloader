// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";

using SafeERC20 for IERC20;

contract WolfMouth  {
 
  event ERC20Withdrawal(address tokenContract, uint256 tokenQuantity, address destinationAddress);
  event ETHWithdrawal(uint256 ethQuantity, address destinationAddress);

  function withdrawERC20(address tokenContract, uint256 tokenQuantity, address destinationAddress) public {

    require(tokenContract != address(0));
    require(tokenQuantity != 0);
    require(destinationAddress != address(0));

    IERC20 contractInterface = IERC20(tokenContract);    
    contractInterface.safeTransfer(destinationAddress, tokenQuantity);

    emit ERC20Withdrawal(tokenContract,tokenQuantity,destinationAddress);

  }

}
