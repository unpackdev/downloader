// SPDX-License-Identifier: MIT
// Cipher Mountain Contracts (last updated v0.0.1) (/Stakable.sol)

pragma solidity ^0.8.0;

interface IStakeable {

    event Stake(uint256 indexed tokenId, bool indexed available);

    /**
     * @dev Returns whether or not the current token is staked
     */
    function isStaked(uint256 tokenId) external view returns (bool);

    /**
     * @dev Pauses activity for the specific token
     */
    function stake(uint256 tokenId) external;

    /**
     * @dev Resumes activity for the specific token
     */
    function unstake(uint256 tokenId) external;
}

