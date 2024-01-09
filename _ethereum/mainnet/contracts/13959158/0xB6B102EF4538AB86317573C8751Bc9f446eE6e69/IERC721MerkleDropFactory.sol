// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC721MerkleDropFactory {
    event ERC721MerkleDropCloneDeployed(
        address clone,
        address indexed owner,
        bytes32 indexed merkleRoot,
        address indexed token
    );

    function create(
        address owner_,
        address tributary_,
        bool paused_,
        bytes32 merkleRoot_,
        uint256 claimDeadline_,
        address recipient_,
        address token_,
        address tokenOwner_,
        uint256 startTokenId_,
        uint256 endTokenId_
    ) external returns (address clone);

    function predictDeterministicAddress(address logic_, bytes32 salt)
        external
        view
        returns (address);
}
