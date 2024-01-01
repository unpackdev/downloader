//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IAddressContract {

    function getDao() external view returns (address);
    
    function getTreasury() external view returns (address);
   
    function getPirateNFT() external view returns (address);
    
    function getPirate() external view returns (address);

    function getBounty() external view returns (address);
    
}
