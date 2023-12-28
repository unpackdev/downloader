pragma solidity ^0.6.6;

interface IExtendedAggregator {
    function getToken() external view returns (address);
    function getTokenType() external view returns (uint256);
    function getPlatformId() external view returns (uint256);
    function getSubTokens() external view returns(address[] memory);
    function latestAnswer() external view returns (int256);
}