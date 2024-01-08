// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFUDFamiglia {
    function  mintMafia(uint amount) external payable;
    
    function giftMafia(address _to, uint amount) external;
    
    function airdrop(string memory code) external;
    
    function massiveCodeCreation(bytes32[] memory hashed_code) external; 
      
    function setActive() external; 
    
    function setNonActive() external; 
    
    function withdraw(uint256 amount) external;
    
    function withdrawAll() external;
    
    function disableAirdrop() external;
     
    function revealAttribute(string memory baseURI) external;
    
    function setPrice(uint256 newprice) external;

    function reserveIndexZero() external;
}