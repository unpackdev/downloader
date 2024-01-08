// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./Structs.sol";

interface IERC755 is IERC165 {
    event PaymentReceived(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        Structs.Policy[] transferRights,
        uint256 timestamp
    );
    event ArtworkCreated(
        uint256 tokenId,
        Structs.Policy[] creationRights,
        string tokenURI,
        uint256 editionOf,
        uint256 maxTokenSupply,
        uint256 timestamp
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        Structs.Policy[] rights,
        uint256 timestamp
    );

    event Approval(
        address indexed approver,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed approver,
        address indexed operator,
        bool approved
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies,
        bytes calldata data
    ) external payable;

    function payForTransfer(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) external payable;

    function approve(
        address to,
        uint256 tokenId
    ) external payable;

    function getApproved(
        address from,
        uint256 tokenId
    ) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function editions(uint256 tokenId) external view returns (uint256[] memory);

    function totalSupply() external view returns (uint256);

    function tokenSupply(uint256 tokenId) external view returns (uint256);

    function rights(uint256 tokenId) external view returns (Structs.Policy[] memory);

    function supportedActions() external view returns (string[] memory);

    function rightsOwned(
        address owner,
        Structs.Policy[] memory policies,
        uint256 tokenId
    ) external view returns (bool);
}