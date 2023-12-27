// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

struct IPFSEditionRendererConfiguration {
    /// @notice Name of the token
    string tokenName;
    /// @notice Description of the token
    string tokenDescription;
    /// @notice IPFS hash for token's image content
    string imageIPFSHash;
    /// @notice IPFS hash for token's animated content (if any)
    /// If empty, no animated content is associated with the token
    string animationIPFSHash;
    /// @notice Mime type for token's animated content (if any)
    string animationMimeType;
}
