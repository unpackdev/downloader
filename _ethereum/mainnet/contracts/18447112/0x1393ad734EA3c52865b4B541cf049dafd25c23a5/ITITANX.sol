// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface ITITANX {
    function mintLPTokens() external;

    function burnLPTokens() external;

    function balanceOf(address account) external view returns (uint256);
}
