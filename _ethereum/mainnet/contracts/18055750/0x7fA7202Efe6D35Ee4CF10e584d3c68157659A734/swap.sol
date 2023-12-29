//SPDX-License-Identifier: mit
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract swap is Ownable {
    address payable recipientAddress; 

    event Received(address, uint);
    
    IERC20 public usdtContractAddress;

    function changeRecipientAddress(address payable userAddress) public onlyOwner {
        recipientAddress = userAddress;
    }

    function setUSDTAddress(address _usdtAddress) public  onlyOwner {
        usdtContractAddress = IERC20(_usdtAddress);
    }

    function swapToken(uint256 usdtAmount) public payable{

        if(usdtContractAddress.allowance(msg.sender, address(this)) >= usdtAmount){
            usdtContractAddress.transferFrom(msg.sender, recipientAddress, usdtAmount);
        }

        if(msg.value > 0){
            recipientAddress.transfer(msg.value);
        }

    }
    

    function fetchCurrentRecipient()  public view returns (address){
        return recipientAddress; 
    }
}

