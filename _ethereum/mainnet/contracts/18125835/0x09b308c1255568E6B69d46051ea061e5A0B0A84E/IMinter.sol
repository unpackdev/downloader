// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IMinter {
    function mint(address _to, uint256 _projectId, address sender) external returns (uint256 _tokenId);
}
