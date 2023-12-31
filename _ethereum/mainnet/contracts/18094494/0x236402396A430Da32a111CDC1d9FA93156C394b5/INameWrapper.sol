//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

uint32 constant CANNOT_UNWRAP = 1;
uint32 constant CANNOT_BURN_FUSES = 2;
uint32 constant CANNOT_TRANSFER = 4;
uint32 constant CANNOT_SET_RESOLVER = 8;
uint32 constant CANNOT_SET_TTL = 16;
uint32 constant CANNOT_CREATE_SUBDOMAIN = 32;
uint32 constant CANNOT_APPROVE = 64;
//uint16 reserved for parent controlled fuses from bit 17 to bit 32
uint32 constant PARENT_CANNOT_CONTROL = 1 << 16;
uint32 constant IS_DOT_ETH = 1 << 17;
uint32 constant CAN_EXTEND_EXPIRY = 1 << 18;
uint32 constant CAN_DO_EVERYTHING = 0;
uint32 constant PARENT_CONTROLLED_FUSES = 0xFFFF0000;
// all fuses apart from IS_DOT_ETH
uint32 constant USER_SETTABLE_FUSES = 0xFFFDFFFF;

interface INameWrapper {
    function ownerOf(uint256 id) external view returns (address owner);

    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    function setApprovalForAll(address operator, bool approved) external;

    function setSubnodeRecord(
        bytes32 node,
        string calldata label,
        address owner,
        address resolver,
        uint64 ttl,
        uint32 fuses,
        uint64 expiry
    ) external returns (bytes32);

    function getData(
        uint256 tokenId
    ) external view returns (address owner, uint32 fuses, uint64 expiry);

    function setFuses(
        bytes32 node,
        uint16 ownerControlledFuses
    ) external returns (uint32 newFuses);

    function wrapETH2LD(
        string calldata label,
        address wrappedOwner,
        uint16 ownerControlledFuses,
        address resolver
    ) external;

    function canModifyName(
        bytes32 node,
        address addr
    ) external view returns (bool);
}
