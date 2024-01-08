// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/// @author: manifold.xyz

import "./INFT2ERC20RateEngine.sol";

interface IASHRateEngineCore is INFT2ERC20RateEngine {

    event Enabled(address indexed admin, bool enabled);
    event ContractRateClassUpdate(address indexed admin, address indexed contract_, uint8 rateClass);
    event ContractTokenRateClassUpdate(address indexed admin, address indexed contract_, uint256 indexed tokenId, uint8 rateClass);

    /**
     * @dev update wether or not the rate engine is enabled
     */
    function updateEnabled(bool enabled) external;

    /**
     * @dev update whitelisted ERC721 contracts
     */
    function updateRateClass(address[] calldata contracts, uint8[] calldata rateClasses) external;

    /**
     * @dev update whitelisted ERC721 tokens of contracts
     */
    function updateRateClass(address[] calldata contracts, uint256[] calldata tokenIds, uint8[] calldata rateClasses) external;

}