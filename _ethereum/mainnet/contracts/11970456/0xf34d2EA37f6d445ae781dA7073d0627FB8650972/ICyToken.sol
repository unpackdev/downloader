pragma solidity ^0.7.0;

interface CYToken {
    function exchangeRateStored() external view returns (uint256);
}
