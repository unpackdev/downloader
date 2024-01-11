//SPDX-License-Identifier: un-licensed
pragma solidity ^0.8.0;

interface IERCX {
    event TransferUser(
        address indexed from,
        address indexed to,
        uint256 indexed itemId,
        address operator
    );
    event ApprovalForUser(
        address indexed user,
        address indexed approved,
        uint256 itemId
    );
    event TransferOwner(
        address indexed from,
        address indexed to,
        uint256 indexed itemId,
        address operator
    );
    event ApprovalForOwner(
        address indexed owner,
        address indexed approved,
        uint256 itemId
    );
    event LienApproval(address indexed to, uint256 indexed itemId);
    event TenantRightApproval(address indexed to, uint256 indexed itemId);
    event LienSet(address indexed to, uint256 indexed itemId, bool status);
    event TenantRightSet(
        address indexed to,
        uint256 indexed itemId,
        bool status
    );

    function balanceOfOwner(address owner) external view returns (uint256);

    function balanceOfUser(address user) external view returns (uint256);

    function userOf(uint256 itemId) external view returns (address);

    function ownerOf(uint256 itemId) external view returns (address);

    function safeTransferOwner(address from, address to, uint256 itemId) external;
    function safeTransferOwner(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) external;

    function safeTransferUser(address from, address to, uint256 itemId) external;
    function safeTransferUser(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) external;

    function approveForOwner(address to, uint256 itemId) external;
    function getApprovedForOwner(uint256 itemId) external view returns (address);

    function approveForUser(address to, uint256 itemId) external;
    function getApprovedForUser(uint256 itemId) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address requester, address operator)
        external
        view
        returns (bool);

    function approveLien(address to, uint256 itemId) external;
    function getApprovedLien(uint256 itemId) external view returns (address);
    function setLien(uint256 itemId) external;
    function getCurrentLien(uint256 itemId) external view returns (address);
    function revokeLien(uint256 itemId) external;

    function approveTenantRight(address to, uint256 itemId) external;
    function getApprovedTenantRight(uint256 itemId)
        external
        view
        returns (address);
    function setTenantRight(uint256 itemId) external;
    function getCurrentTenantRight(uint256 itemId)
        external
        view
        returns (address);
    function revokeTenantRight(uint256 itemId) external;
}
