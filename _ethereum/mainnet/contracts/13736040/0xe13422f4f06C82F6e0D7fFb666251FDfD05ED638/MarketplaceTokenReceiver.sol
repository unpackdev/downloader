// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC1155.sol";
import "./IMarketplaceTokenReceiver.sol";


/**
 * Token receiver for a given marketplace
 */
contract MarketplaceTokenReceiver is IMarketplaceTokenReceiver {
    
    address private _marketplace;
    
    // ERC1155: Mapping from token contracts to token IDs to account balances
    mapping (address => mapping(uint256 => mapping(address => uint256))) private _erc1155balances;

    constructor(address marketplace) {
        _marketplace = marketplace;
    }

    function decrementERC1155(address owner, address tokenAddress, uint256 tokenId, uint256 value) external virtual override {
        require(msg.sender == _marketplace, "Invalid caller");
        require(_erc1155balances[tokenAddress][tokenId][owner] >= value, "Invalid token amount");
        _erc1155balances[tokenAddress][tokenId][owner] -= value;
    }

    function transferERC1155(address tokenAddress, uint256 tokenId, uint256 value, address to) external virtual override {
        require(msg.sender == _marketplace, "Invalid caller");
        IERC1155(tokenAddress).safeTransferFrom(address(this), to, tokenId, value, "");
    }

    function withdrawERC1155(address tokenAddress, uint256 tokenId, uint256 value) external virtual override {
        require(_erc1155balances[tokenAddress][tokenId][msg.sender] >= value, "Invalid token amount");
        _erc1155balances[tokenAddress][tokenId][msg.sender] -= value;
        IERC1155(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId, value, "");
    }

    function onERC1155Received(address, address from, uint256 id, uint256 value, bytes calldata) external virtual override returns(bytes4) {
        _erc1155balances[msg.sender][id][from] += value;
        return this.onERC1155Received.selector;
    }
}