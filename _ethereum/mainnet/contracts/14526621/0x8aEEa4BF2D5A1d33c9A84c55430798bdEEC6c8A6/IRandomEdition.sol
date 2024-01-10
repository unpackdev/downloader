//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
interface IRandomEdition 
{ 
    function _Mint(address Recipient, uint Amount) external returns(uint tokenID); //Mints Random Edition
    function tokenURI(uint256 tokenId) external view returns (string memory); //Returns IPFS Metadata
}
