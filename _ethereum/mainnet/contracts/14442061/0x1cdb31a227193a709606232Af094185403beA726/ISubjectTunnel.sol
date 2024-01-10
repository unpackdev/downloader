// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISubjectTunnel {
    function moveThroughWormhole(uint256 tokenId) external;

    function setDaoAddress(address payable daoAddress) external;
}
