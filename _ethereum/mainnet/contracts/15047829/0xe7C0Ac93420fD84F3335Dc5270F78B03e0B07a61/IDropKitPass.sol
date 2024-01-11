// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDropKitPass {
    /**
     * @dev Contract upgradeable initializer
     */
    function initialize(
        string memory name,
        string memory symbol,
        address treasury,
        address royalty,
        uint96 royaltyFee
    ) external;

    /**
     * @dev Mints a new token with a given fee rate
     */
    function mint(address to, uint96 feeRate) external;

    /**
     * @dev Batch mints tokens with a given fee rate
     */
    function batchAirdrop(
        address[] calldata recipients,
        uint96[] calldata feeRates
    ) external;

    /**
     * @dev Gets the fee rate for a given token id
     */
    function getFeeRate(uint256 tokenId) external view returns (uint96);

    /**
     * @dev Gets the fee rate for a given address
     */
    function getFeeRateOf(address owner) external view returns (uint96);
}
