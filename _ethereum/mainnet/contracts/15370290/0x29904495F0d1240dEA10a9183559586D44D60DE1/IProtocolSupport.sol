//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IProtocolSupport {
    function quote(bytes memory) external returns (uint256 _returns, bytes memory);

    function tokensQuote(bytes memory) external returns (uint256 _returns, bytes memory);

    function swap(uint256, bytes memory) external payable returns (uint256 _returns);
}
