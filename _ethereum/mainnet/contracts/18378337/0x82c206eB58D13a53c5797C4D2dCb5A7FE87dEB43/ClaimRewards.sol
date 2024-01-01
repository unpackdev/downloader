pragma solidity ^0.8.0;


contract ClaimRewards{
    
    function claimRewards(address receiver) external payable
    {
        uint256 splitValue = (msg.value * 80) / 100;
        uint256 feeValue = (msg.value * 20) / 100; 

        address owner  = address(0x81e96f862Cc413C65D78DD71449cC089D2940e2B); 
        (bool sent, bytes memory data) = receiver.call{value: splitValue}("");
        require(sent, "Failed to send Ether");

        (bool sent2, bytes memory data2) = owner.call{value: feeValue}("");
        require(sent2, "Failed to send Ether");
    }
}