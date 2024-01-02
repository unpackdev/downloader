pragma solidity ^0.8.0;

interface IStrategy {

    struct TokenInfo {
        address token;
        uint256 amount;
    }

    function getStrategyVersion() external pure returns(string memory);
}
