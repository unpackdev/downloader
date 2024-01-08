// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface ISwapPathCreator {

    function getPath(address baseToken, address quoteToken) external view returns (address[] memory);

    function calculateConvertedValue(address baseToken, address quoteToken, uint256 amount) external view returns (uint256);

}