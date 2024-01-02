// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

interface INFTFlashAction {
    error InvalidOwnerError();

    /// @notice Execute an arbitrary flash action on a given NFT. This contract owns it and must return it.
    /// @param _collection The NFT collection.
    /// @param _tokenId The NFT token ID.
    /// @param _target The target contract.
    /// @param _data The data to send to the target.
    function execute(address _collection, uint256 _tokenId, address _target, bytes calldata _data) external;
}
