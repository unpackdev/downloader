// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./INFTRegistry.sol";
import "./INFTOperator.sol";

interface INFT {
    function initialize(
        string memory name_,
        string memory symbol_,
        INFTRegistry registry_,
        INFTOperator operator_
    ) external;

    function setRegistry(INFTRegistry registry) external;

    function setRegistryDisabled(bool registryDisabled) external;

    function setOperator(INFTOperator operator_) external;

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external;

    function mint(uint256 tokenId, address receiver, string calldata tokenURI) external;

    function burn(uint256 tokenId) external;

    function transferOwnership(address newOwner) external;
}
