// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./IERC721Enumerable.sol";


interface IGhostsProject is IERC721Enumerable {

    function getMaxGhosts() external pure returns (uint256);

    /// @notice Acknowledge contract is `GhostsProject`
    /// @return always true if the contract is in fact `GhostsProject`
    function isGhostsProject() external pure returns (bool);

    /// @notice Check whether ghost has memory or not
    /// @return boolean true if the ghost with tokenId has memory
    function hasMemory(uint256 _tokenId) external view returns (bool);

    /// @notice Get memory the ghost picked
    /// @return string memory phrase
    function memoryPicked(uint256 _tokenId) external view returns (string memory);

    function pickMemory(uint256 _tokenId, uint256 _memoryType, string memory _memoryPhrase) external;

    function getMemoryType(uint256 _tokenId) external view returns (uint256);
}
