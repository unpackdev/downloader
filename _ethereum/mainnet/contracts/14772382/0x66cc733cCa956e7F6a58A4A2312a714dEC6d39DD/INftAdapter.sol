// SPDX-License-Identifier: UNLICENSED
/// @title INftAdapter
/// @notice INftAdapter
/// @author CyberPnk <cyberpnk@pfpbg.cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.13;

interface INftAdapter {
    function getSvg(uint256 tokenId) external view returns(string memory);
    function getDataUriSvg(uint256 tokenId) external view returns(string memory);
    function getDataUriBase64(uint256 tokenId) external view returns(string memory);
    function getEmbeddableSvg(uint256 tokenId) external view returns(string memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getTraitsJsonValue(uint256 tokenId) external view returns(string memory);
    function name() external view returns(string memory);
}
