// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

enum ConduitItemType {
    NATIVE, // unused
    ERC20,
    ERC721,
    ERC1155
}

struct ConduitTransfer {
    ConduitItemType itemType;
    address collection;
    address from;
    address to;
    uint256 identifier;
    uint256 amount;
}

struct ConduitBatch1155Transfer {
    address collection;
    address from;
    address to;
    uint256[] ids;
    uint256[] amounts;
}

interface ICyanConduit {
    error ChannelClosed(address channel);
    error ChannelStatusAlreadySet(address channel, bool isOpen);
    error InvalidItemType();
    error InvalidAdmin();

    event ChannelUpdated(address indexed channel, bool open);

    function execute(ConduitTransfer[] calldata transfers) external returns (bytes4 magicValue);

    function executeBatch1155(ConduitBatch1155Transfer[] calldata batch1155Transfers)
        external
        returns (bytes4 magicValue);

    function executeWithBatch1155(
        ConduitTransfer[] calldata standardTransfers,
        ConduitBatch1155Transfer[] calldata batch1155Transfers
    ) external returns (bytes4 magicValue);

    function transferERC20(
        address from,
        address to,
        address token,
        uint256 amount
    ) external;

    function transferERC721(
        address from,
        address to,
        address collection,
        uint256 tokenId
    ) external;

    function transferERC1155(
        address from,
        address to,
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external;

    function updateChannel(address channel, bool isOpen) external;
}
