// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface IASCIIGenerator {

    /** 
    * @notice Generates full metadata
    */
    function generateMetadata(string memory _legionName, uint256 _legion, string memory _fillChar, string memory _color) external view returns (string memory);


    /** 
    * @notice Generates the SVG image
    */
    function generateSVG(uint256 _legion, string memory _fillChar, string memory _color) external view returns (string memory);
}