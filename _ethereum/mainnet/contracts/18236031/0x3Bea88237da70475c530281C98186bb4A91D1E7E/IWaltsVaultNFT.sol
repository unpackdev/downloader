// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";

interface IWaltsVaultNFT is IERC721Upgradeable {
    function totalSupply() external view returns (uint256);
    function airdrop(
        address[] calldata to,
        uint256[] calldata amount
    ) external;
    
    function burnToken(uint256 tokenId) external;
}
