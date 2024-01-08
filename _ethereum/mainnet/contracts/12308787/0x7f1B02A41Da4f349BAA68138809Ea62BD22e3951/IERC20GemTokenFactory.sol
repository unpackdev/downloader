// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface for a Bitgem staking pool
 */
interface IERC20GemTokenFactory {
    /**
     * @dev emitted when a new gem pool has been added to the system
     */
    event ERC20GemTokenCreated(
        address tokenAddress,
        address poolAddress,
        string tokenSymbol,
        string poolSymbol
    );

    function getItem(uint256 _symbolHash) external view returns (address);

    function allItems(uint256 idx) external view returns (address);

    function allItemsLength() external view returns (uint256);

    function createItem(
        string memory tokenSymbol,
        string memory tokenName,
        address poolAddress,
        address tokenAddress,
        uint8 decimals
    ) external returns (address payable);
}
