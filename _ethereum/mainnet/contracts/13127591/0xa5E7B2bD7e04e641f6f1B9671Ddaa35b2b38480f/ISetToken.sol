pragma solidity 0.5.15;

interface ISetToken {
    function unitShares() external view returns(uint);
    function naturalUnit() external view returns(uint);
    function currentSet() external view returns(address);
    // function getUnits() external view returns (uint256[] memory);
}