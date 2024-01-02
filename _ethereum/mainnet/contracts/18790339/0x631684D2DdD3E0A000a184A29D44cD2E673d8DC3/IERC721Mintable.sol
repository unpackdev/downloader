// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.18;

interface IERC721Mintable {
    function mint(address _to, uint256[] memory _ids) external;

    function totalSupply() external returns (uint256);
}
