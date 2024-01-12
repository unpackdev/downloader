// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC1155Supply.sol";
import "./AccessLock.sol";

/// @title BHSerum - BagHolderz Mutant Serum
/// @author 0xhohenheim <contact@0xhohenheim.com>
/// @notice ERC1155 MultiToken Contract
contract BHSerum is ERC1155Supply, AccessLock {
    mapping(uint256 => string) private _URIs;

    constructor() ERC1155("") {}

    /// @notice Mint NFT
    /// @dev callable only by admin
    /// @param recipient mint to
    function mint(
        address recipient,
        uint256 tokenId,
        uint256 quantity
    ) external onlyAdmin {
        _mint(recipient, tokenId, quantity, "");
    }

    /// @notice Fetch token URI
    /// @param tokenId token ID
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _URIs[tokenId];
    }

    /// @notice Set URI for a token
    /// @dev callable only by admin
    /// @param tokenId token ID
    /// @param _URI URI to set for tokenId
    function setURI(uint256 tokenId, string calldata _URI) external onlyAdmin {
        _URIs[tokenId] = _URI;
        emit URI(_URI, tokenId);
    }
}
