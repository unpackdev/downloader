// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IXToken {
    function getPricePerFullShare() external view returns (uint256);
}