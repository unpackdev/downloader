pragma solidity ^0.5.16;

interface WstEthOracleInterface {
    function getPrice() external view returns (uint256);
}
