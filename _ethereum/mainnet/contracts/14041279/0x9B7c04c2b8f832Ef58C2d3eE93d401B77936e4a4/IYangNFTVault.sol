// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
pragma abicoder v2;

interface IYangNFTVault {
    function getTokenId(address recipient) external view returns (uint256);
}
