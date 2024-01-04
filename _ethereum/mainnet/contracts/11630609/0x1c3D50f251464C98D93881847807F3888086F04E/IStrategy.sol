// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @notice Interface of Strategy contract.
 * 
 * One strategy can only and always serve one vault. It shares the same
 * governance and strategist with the vault which manages this strategy.
 */
interface IStrategy {

    /**
     * @dev Returns the vault that uses the strategy.
     */
    function vault() external view returns (address);

    /**
     * @dev Returns the Controller that manages the vault.
     * Should be the same as Vault.controler().
     */
    function controller() external view returns (address);

    /**
     * @dev Returns the token that the vault pools to seek yield.
     * Should be the same as Vault.token().
     */
    function token() external view returns (address);

    /**
     * @dev Returns the governance of the Strategy.
     * Controller and its underlying vaults and strategies should share the same governance.
     */
    function governance() external view returns (address);

    /**
     * @dev Return the strategist which performs daily permissioned operations.
     * Vault and its underlying strategies should share the same strategist.
     */
    function strategist() external view returns (address);

    /**
     * @dev Return the percentage of fee charged on the generated yield.
     */
    function performanceFee() external view returns (uint256);

    /**
     * @dev Return the percentage of fee charged when asset is withdrawn from strategy.
     */
    function withdrawalFee() external view returns (uint256);

    /**
     * @dev Returns the total balance of want token in this Strategy.
     */
    function balanceOf() external view returns (uint256);

    /**
     * @dev Invests the free token balance in the strategy.
     */
    function deposit() external;

    /**
     * @dev Withdraws a portional amount of assets from the Strategy.
     */
    function withdraw(uint256 _amount) external;

    /**
     * @dev Withdraws all assets out of the Strategy.  Usually used in strategy migration.
     */
    function withdrawAll() external returns (uint256);

    /**
     * @dev Harvest yield from the market.
     */
    function harvest() external;
}
