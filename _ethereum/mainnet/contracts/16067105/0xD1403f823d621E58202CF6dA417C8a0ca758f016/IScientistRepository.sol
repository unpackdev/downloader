// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "./ScientistData.sol";

/**
 * @title Interface for interaction with particular scientist
 */
interface IScientistRepository {
    event AddScientist(uint256 tokenId, ScientistData.Scientist scientist, uint256 timestamp);
    event UpdateScientist(
        uint256 tokenId,
        ScientistData.Scientist currentScientist,
        ScientistData.Scientist newScientist,
        uint256 timestamp
    );
    event RemoveScientist(uint256 _tokenId, ScientistData.Scientist _scientist, uint256 _timestamp);

    function addScientist(address _account, uint256 _tokenId) external;

    function removeScientist(uint256 _tokenId, address _owner) external;

    /**
     * @dev Returns meta scientist id's for particular user
     */
    function getUserMetascientistsIndexes(address _user)
        external
        view
        returns (uint256[] memory);

    function updateScientist(
        uint256 _tokenId,
        ScientistData.Scientist memory scientistData,
        address _account
    ) external;

    function getScientist(uint256 _tokenId)
        external
        view
        returns (ScientistData.Scientist memory);
}
