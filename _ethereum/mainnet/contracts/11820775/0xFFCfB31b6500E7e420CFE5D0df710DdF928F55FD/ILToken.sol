// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC20.sol";

/**
 * @title Deri Protocol liquidity provider token interface
 */
interface ILToken is IERC20 {

    /**
     * @dev Set the pool address of this LToken
     * pool is the only controller of this contract
     * can only be called by current pool
     */
    function setPool(address newPool) external;

    /**
     * @dev Returns address of pool
     */
    function pool() external view returns (address);

    /**
     * @dev Mint LToken to `account` of `amount`
     *
     * Can only be called by pool
     * `account` cannot be zero address
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Burn `amount` LToken of `account`
     *
     * Can only be called by pool
     * `account` cannot be zero address
     * `account` must owns at least `amount` LToken
     */
    function burn(address account, uint256 amount) external;

}
