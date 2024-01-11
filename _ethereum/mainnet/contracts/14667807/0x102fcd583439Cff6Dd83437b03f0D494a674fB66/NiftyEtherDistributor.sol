// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Withdrawable.sol";
import "./ReentrancyGuard.sol";

contract NiftyEtherDistributor is Withdrawable, ReentrancyGuard {

    constructor(address niftyRegistryContract_) {
        initializeNiftyEntity(niftyRegistryContract_);
    }    

    function distributeEther(address[] calldata wallets, uint256[] calldata amounts) external payable nonReentrant {        
        require(wallets.length == amounts.length, "Input array size mismatch");        

        uint256 remainingEthValue = msg.value;
        uint256 i = 0;
        uint256 amount = 0;                

        while(i < wallets.length) {            
            amount = amounts[i];
            remainingEthValue -= amount;                        
            (bool success,) = wallets[i].call{value: amount}("");            
            require(success, "Transfer ETH Failed");
            ++i;
        }
                        
        (bool refundSuccess,) = msg.sender.call{value: remainingEthValue}("");
        require(refundSuccess, "Refund ETH Failed");        
    }           
}