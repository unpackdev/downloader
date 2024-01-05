pragma solidity >=0.5.0;

interface IMintRegulator {

    function getScale() external view returns (uint256 _molecular, uint256 _denominator);
}