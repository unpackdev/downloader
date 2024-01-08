// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKaijuKingz {
    function RWaste() external view returns (address); // solhint-disable-line func-name-mixedcase

    function maxGenCount() external view returns (uint256);

    function babyCount() external view returns (uint256);

    function fusion(uint256 parent1, uint256 parent2) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address to, uint256 tokenId) external;
}
