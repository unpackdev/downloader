// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns(address);
}

contract ExternalTokenOperations is AccessControl{

    using Strings for uint256;

    address internal constant TEAM_ADDRESS1 = address(0x1d1b1e30a9d15dBA662f85119122e1D651090434);
    address internal constant TEAM_ADDRESS2 = address(0x91f6404daC4E86F69248ee437456730228Af816a);

    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

    event BatchTransferToMultiple(
        address indexed contractAddress,
        uint256 amount
    );

    struct TokenOwnership {
        uint256 tokenId;
        bool isOwned;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TEAM_ROLE, TEAM_ADDRESS1);
        _setupRole(TEAM_ROLE, TEAM_ADDRESS2);
        _setupRole(TEAM_ROLE, msg.sender);
    }

    function batchTransferToMultipleWallets(
        IERC721 erc721Contract,
        address sender,
        address[] calldata tos,
        uint256[] calldata tokenIds
    ) external onlyRole(TEAM_ROLE) {
        uint256 length = tokenIds.length;
        require(tos.length == length,"InvalidArguments : length");

        for (uint256 i; i < length; ) {
            uint256 tokenId = tokenIds[i];
            address to = tos[i];
            erc721Contract.transferFrom(sender, to, tokenId);
            unchecked {
                ++i;
            }
        }

    }

    function safeBatchTransferToMultipleWallets(
        IERC721 erc721Contract,
        address sender,
        address[] calldata tos,
        uint256[] calldata tokenIds
    ) external onlyRole(TEAM_ROLE) {
        uint256 length = tokenIds.length;
        require(tos.length == length,"InvalidArguments : length");

        for (uint256 i; i < length; ) {
            uint256 tokenId = tokenIds[i];
            address to = tos[i];
            erc721Contract.safeTransferFrom(sender, to, tokenId);
            unchecked {
                ++i;
            }
        }

    }

    function batchTransferToMultipleWalletsCheck2(
    IERC721 erc721Contract,
    address sender,
    address[] calldata tos,
    uint256[] calldata tokenIds
    ) external view returns(TokenOwnership[] memory) {
        uint256 length = tokenIds.length;
        require(tos.length == length, "InvalidArguments: length mismatch");

        TokenOwnership[] memory ownershipStatus = new TokenOwnership[](length);

        for (uint256 i = 0; i < length; i++) {
            ownershipStatus[i].tokenId = tokenIds[i];
            ownershipStatus[i].isOwned = (sender == erc721Contract.ownerOf(tokenIds[i]));
        }
        return ownershipStatus;
    }
}
