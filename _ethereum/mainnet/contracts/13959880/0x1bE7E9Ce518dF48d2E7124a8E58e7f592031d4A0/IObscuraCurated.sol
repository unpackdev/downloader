// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IObscuraCurated {
    function mintTo(address to, uint256 projectId) external;

    function mintToBySelect(
        address to,
        uint256 projectId,
        uint256 tokenId
    ) external;

    function isSalePublic(uint256 projectId)
        external
        view
        returns (bool active);

    function getProjectMaxPublic(uint256 projectId)
        external
        view
        returns (uint256 maxPublic);

    function getProjectCirculatingPublic(uint256 projectId)
        external
        view
        returns (uint256 circulatingPublic);

    function getProjectPlatformReserve(uint256 projectId)
        external
        view
        returns (uint256 platformReserveAmount);
}
