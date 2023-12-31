//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrawlerBearzConsumables {
    error NotConsumed();
    error InvalidOwner();
    error InvalidItemType();

    struct Consumable {
        uint256 itemId;
        string name;
        string description;
        uint256 consumedAt;
    }

    event Consumed(uint256 indexed tokenId, uint256 itemTokenId);

    event Activated(uint256 indexed tokenId, uint256 itemTokenId);

    event Deactivated(uint256 indexed tokenId, uint256 itemTokenId);

    function setParentContract(address contractAddress) external;

    function setVendorContract(address contractAddress) external;

    function getConsumables(
        uint256 tokenId
    ) external view returns (bytes[] memory);

    function consume(
        uint256 tokenId,
        uint256 itemTokenId,
        bool isEnabled
    ) external;

    function activate(uint256 tokenId, uint256 itemTokenId) external;

    function deactivate(uint256 tokenId, uint256 itemTokenId) external;

    function isActiveConsumable(
        uint256 tokenId,
        uint256 itemTokenId
    ) external returns (bool);

    function toConsumableProperties(
        uint256 tokenId
    ) external view returns (string memory);
}
