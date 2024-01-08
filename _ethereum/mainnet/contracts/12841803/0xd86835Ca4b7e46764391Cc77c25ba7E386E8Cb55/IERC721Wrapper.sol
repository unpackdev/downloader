// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author jpegmint.xyz

import "./IERC721.sol";
import "./IERC721Receiver.sol";

/**
 * @title ERC721 token wrapping interface.
 */
 interface IERC721Wrapper is IERC721, IERC721Receiver {
    /**
     * @dev Emitted when `tokenId` token wrapped by `from`.
     */
    event Wrapped(address indexed from, uint256 tokenId);

    /**
     * @dev Emitted when `tokenId` token is unwrapped by `from`.
     */
    event Unwrapped(address indexed from, uint256 tokenId);

    /**
     * @dev Wraps `tokenId` by receiving token and minting matching token.
     * Emits a {Wrapped} event.
     */
    function wrap(address contract_, uint256 tokenId) external;

    /**
     * @dev Unwraps `tokenId` by burning wrapped and returning original token.
     * Emits a {Unwrapped} event.
     */
    function unwrap(address contract_, uint256 tokenId) external;

    /**
     * @dev Checks and returns whether the tokenId is wrappable.
     */
    function isWrappable(address contract_, uint256 tokenId) external view returns (bool);

    /**
     * @dev Updates and maintains approved contract/tokenIds that contract can wrap.
     */
    function updateApprovedTokenRanges(address contract_, uint256 minTokenId, uint256 maxTokenId) external;
}
