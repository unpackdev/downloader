// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

interface IBatcher {
    //    function isDarkAge() external view returns(bool);
//
//    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function multiTokenReinforce(uint32[] memory _tokenIds, uint80[4][] memory _currentLevels, uint80[4][] memory _extraLevels, uint8[] memory _highest, uint80 _baseCost) external payable;
    function multiLevelReinforce(uint32 _tokenId, uint80[4] memory _currentLevels, uint80[4] memory _extraLevels, uint80 _highest, uint80 _baseCost) external payable;
}