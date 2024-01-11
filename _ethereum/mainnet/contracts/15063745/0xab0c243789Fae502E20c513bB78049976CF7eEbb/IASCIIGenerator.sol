// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IASCIIGenerator {

    /** 
    * @notice Generates full metadata
    */
    function generateMetadata(uint256 tokenId, uint256 _maxSupply) external view returns (string memory);

}