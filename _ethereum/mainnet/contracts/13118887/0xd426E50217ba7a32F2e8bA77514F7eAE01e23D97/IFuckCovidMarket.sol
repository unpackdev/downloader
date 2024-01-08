// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IFuckCovidMarket {
    function tokenPrice() external view returns (uint256);
    function buyToken(address _to) external payable returns (uint16 _tokenId);
    function buyTokens(address _to, uint16 _amount) external payable returns (uint16 _tokenId);
    function setTokenPrice(uint256 _tokenPrice) external;
}
