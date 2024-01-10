// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IObscuraCurated {
    function mintTo(
        address to,
        uint256 projectId,
        uint256 tokenId
    ) external;

    function setProjectCID(uint256 projectId, string calldata cid) external;

    function setTokenCID(uint256 tokenId, string calldata cid) external;

    function setDefaultPendingCID(string calldata defaultPendingCID) external;

    function getProjectMaxPublic(uint256 projectId) external view returns (uint256);

    function isSalePublic(uint256 projectId)
        external
        view
        returns (bool active);

       function mintToBySelect(
        address to,
        uint256 projectId,
        uint256 tokenId
    ) external ;
}
