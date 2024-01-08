// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBridge {
    event Bridge(address indexed from, uint256 amount);
    event BridgeERC20(address indexed from, address indexed token, uint256 amount);
    event BridgeERC721(address indexed from, address indexed token, uint256 indexed tokenId);
    event BridgeERC1155(address indexed from, address indexed token, uint256[] tokenId, uint256[] amount);

    function committee() external view returns (address);

    function withdraw(uint256 amount) external;

    function withdrawERC20(address token, uint256 amount) external;

    function withdrawERC721(address token, uint256 tokenId) external;

    function withdrawERC1155(
        address token,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    function bridge() external payable;

    function bridgeERC20(address token, uint256 amount) external;

    function bridgeERC721(address token, uint256 tokenId) external;

    function bridgeERC1155(
        address token,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;
}
