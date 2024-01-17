// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOpenBound {
    function mint(uint256 tokenID) external returns (uint256);

    function claim(uint256 tokenID, uint256 cid) external;

    function burn(uint256 tokenID) external;

    function getMyTokenID(uint256 cid) external view returns (uint256);

    function getTokenID(address addr, uint256 cid) external view returns (uint256 tokenID);

    function getCID(uint256 tokenID) external view returns (uint256);
}
