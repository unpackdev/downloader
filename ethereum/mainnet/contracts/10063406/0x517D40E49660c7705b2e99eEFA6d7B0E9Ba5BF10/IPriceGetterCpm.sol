pragma solidity ^0.6.6;

interface IPriceGetterCpm {
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256);
}