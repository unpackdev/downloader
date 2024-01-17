// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

struct WhiteListItem {
    uint256 price;
    uint256 usedCount;
    address addr;
    uint256 limit;
}

interface IWhiteList {
    function getCollectionWhiteListAddress(address token)
        external
        view
        returns (address[] memory);

    function getCollectionWhiteList(address token)
        external
        view
        returns (WhiteListItem[] memory);

    function getCollectionAllOpen(address token) external view returns (bool);

    function getCollectionWhiteListOpen(address token)
        external
        view
        returns (bool);

    function getCollectionWhiteListItem(address token, address addr)
        external
        view
        returns (WhiteListItem memory);

    function setWhiteList(
        address token,
        address[] calldata addressArray,
        uint256[] calldata priceArray,
        uint256[] calldata limitArray
    ) external;

    function setCollectionWhiteListOpen(address token, bool open) external;

    function setCollectionAllOpen(address token, bool open) external;

    function addWhiteListUsedCount(
        address token,
        address addr
    ) external returns(uint256);

    function isOpen(address token, address addr) external view returns (bool);

    function whiteListPrice(address token, address from) external view returns(uint256);
}
