// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IDecentralandEstate {
    function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function getFingerprint(uint256 estateId)
        external
        view
        returns (bytes32 result);

    function estateLandIds(uint256 estateId, uint256 index)
        external
        view
        returns (uint256);

    function transferLand(
        uint256 estateId,
        uint256 landId,
        address destinatary
    ) external;
}
