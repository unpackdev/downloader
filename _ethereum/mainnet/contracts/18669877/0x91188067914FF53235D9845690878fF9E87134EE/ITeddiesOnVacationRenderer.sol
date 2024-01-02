// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ToVInfos.sol";

interface IToVRenderer {
    function tokenURI(uint256 tokenId, ToVInfos.ToV memory tovData , ToVInfos.ContractData memory contractData) external view returns (string memory);
    function getMetaDataFromTokenID(uint256 tokenId, ToVInfos.ToV memory tovData) external view returns (string memory);
}