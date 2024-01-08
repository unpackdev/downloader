//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface IMetamaticiansAttributes {
   function getName(uint pieceOfPie) external view returns (string memory);
   function getSuffix(uint pieceOfPie) external view returns (string memory);
   function getGreek(uint pieceOfPie) external view returns (string memory);
   function getGreekName(uint pieceOfPie) external view returns (string memory);
   function getSVG(uint256 pieceOfPi, uint256 tokenId) external view returns (string memory);
}
