// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract Withdrawable is Ownable {
 
  event ERC20Withdrawal(address tokenContract, uint256 tokenQuantity, address destinationAddress);
  event ETHWithdrawal(uint256 ethQuantity, address destinationAddress);

  function withdrawERC20(address tokenContract, uint256 tokenQuantity, address destinationAddress) public onlyOwner  {

    require(tokenContract != address(0));
    require(tokenQuantity != 0);
    require(destinationAddress != address(0));

    IERC20 contractInterface = IERC20(tokenContract);
    //contractInterface.approve(address(this), tokenQuantity);
    contractInterface.transfer(destinationAddress, tokenQuantity);

    emit ERC20Withdrawal(tokenContract,tokenQuantity,destinationAddress);

  }

  function withdrawETH(uint256 ethQuantity, address destinationAddress) public onlyOwner {
    
    require(ethQuantity != 0);
    require(destinationAddress != address(0));

    (bool success, ) = destinationAddress.call{value: ethQuantity}("");

    if (success)
      emit ETHWithdrawal(ethQuantity, destinationAddress);

  }

}
