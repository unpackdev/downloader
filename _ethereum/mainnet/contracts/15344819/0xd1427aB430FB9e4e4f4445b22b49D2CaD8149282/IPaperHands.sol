// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPaperHands {

    function balanceOf(address) external view returns (uint256);

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) external;
    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory _data
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;
}
