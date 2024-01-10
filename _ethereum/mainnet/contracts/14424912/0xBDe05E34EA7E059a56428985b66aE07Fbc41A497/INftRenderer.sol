// SPDX-License-Identifier: UNLICENSED
/// @title INftRenderer
/// @notice NFT Renderer
/// @author CyberPnk <cyberpnk@cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.2;

interface INftRenderer {
    function getImage(uint256 itemId) external view returns(bytes memory);

    function getTokenURI(uint256 itemId, string memory texts) external view returns (string memory);
    function getTokenURI(uint256 itemId) external view returns (string memory);

    function getContractURI(address feePayee, uint8 feeAmount) external pure returns(string memory);
    function getContractURI(address feePayee) external pure returns(string memory);
    function getContractURI() external pure returns(string memory);
}