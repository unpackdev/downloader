// SPDX-License-Identifier: MIT
// Creator: base64.tech
pragma solidity ^0.8.13;

/*
 * Interface for SamuRiseStakingController for use in Samurise contract 
 */
interface IStakingController {
    function stakeFromTokenContract(uint256 tokenId, address originator) external;
}