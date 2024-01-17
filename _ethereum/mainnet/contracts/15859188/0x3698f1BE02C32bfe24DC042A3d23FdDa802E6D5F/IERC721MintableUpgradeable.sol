// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// prettier-ignore
interface IERC721MintableUpgradeable {
    function exists(uint256 _tokenId) external view returns (bool);
    function mint(address _to, uint256 _tokenId) external;
    function bulkMint(address[] memory _tos, uint256[] memory _tokenIds) external;
}
