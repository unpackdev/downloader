pragma solidity 0.5.15;

interface ISetAssetBaseCollateral {
    function getComponents() external view returns(address[] memory);
    function naturalUnit() external view returns(uint);
    function getUnits() external view returns (uint256[] memory);
}