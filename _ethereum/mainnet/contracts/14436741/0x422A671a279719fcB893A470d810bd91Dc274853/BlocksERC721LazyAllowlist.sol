// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: BLOCKS
/// @author: manifold.xyz

import "./AdminControl.sol";

import "./BlocksERC721LazyAllowlistBase.sol";
import "./IBlocksERC721LazyAllowlist.sol";

/**
 * BlocksERC721LazyAllowlist v1.1 - Lazy Mint with Whitelist for ERC721 tokens + additional Blocks functions
 */
 
contract BlocksERC721LazyAllowlist is BlocksERC721LazyAllowlistBase, AdminControl, IBlocksERC721LazyAllowlist {

    constructor(address creator, string memory prefix, uint256 mintPrice, uint256 maxMints) {
        _initialize(creator, prefix, mintPrice, maxMints);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, BlocksERC721LazyAllowlistBase) returns (bool) {
        return interfaceId == type(IBlocksERC721LazyAllowlist).interfaceId || AdminControl.supportsInterface(interfaceId) || BlocksERC721LazyAllowlistBase.supportsInterface(interfaceId);
    }

    function premint(address[] memory to) external override adminRequired {
        _premint(to);
    }

    function mint(bytes32[] memory merkleProof) external override payable {
        _mint(merkleProof);
    }

    function setAllowList(bytes32 merkleRoot) external override adminRequired {
        _setAllowList(merkleRoot);
    }

    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    function setMintPrice(uint256 mintPrice) external override adminRequired {
        _setMintPrice(mintPrice);
    }

    function setMaxMints(uint256 maxMints) external override adminRequired {
        _setMaxMints(maxMints);
    }

    function withdraw(address to, uint amount) external override adminRequired {
        _withdraw(to, amount);
    }
    
}
