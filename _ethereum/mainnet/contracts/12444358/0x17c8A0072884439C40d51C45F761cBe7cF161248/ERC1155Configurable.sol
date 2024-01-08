// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ERC1155Configurable {
    /**
     * @dev Emitted when `owner` sets a `configurationURI` for `tokenId`
     * there
     */
    event ConfigurationURI(
        uint256 indexed tokenId,
        address indexed owner,
        string configurationURI
    );

    // map of tokenId => interactiveConfURI.
    mapping(uint256 => mapping(address => string)) private _interactiveConfURIs;

    function _setInteractiveConfURI(
        uint256 tokenId,
        address owner,
        string calldata interactiveConfURI_
    ) internal virtual {
        _interactiveConfURIs[tokenId][owner] = interactiveConfURI_;
        emit ConfigurationURI(tokenId, owner, interactiveConfURI_);
    }

    /**
     * Configuration uri for tokenId
     */
    function interactiveConfURI(uint256 tokenId, address owner)
        public
        view
        virtual
        returns (string memory)
    {
        return _interactiveConfURIs[tokenId][owner];
    }
}
