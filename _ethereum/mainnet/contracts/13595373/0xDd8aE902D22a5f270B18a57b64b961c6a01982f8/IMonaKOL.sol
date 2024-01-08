//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMonaKOL {

    function setSaleActive(bool active) external;
    
    function isOnMintList(address addr) external view returns (bool);

    function addToMintList(address[] calldata addresses) external;

    function removeFromMintList(address[] calldata addresses) external;

    function mint() payable external;

    function withdraw() external;    

}
