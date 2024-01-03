// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./ISyntheticToken.sol";

import "./Amount.sol";
import "./Decimal.sol";

contract MozartSavingsStorageV1 {

    /**
     * @dev ERC20 Properties
     */
    string  internal _name;
    string  internal _symbol;
    uint256 internal _totalSupply;

    /**
     * @notice Synthetic token to mint
     */
    ISyntheticToken public synthetic;

    /**
     * @notice Enable/disable interactions with this contract
     */
    bool public paused;

    /**
     * @notice The savings index which is used to store the cumulative
     *         interest rate across all users
     */
    uint256 public savingsIndex;

    /**
     * @notice The savings interest rate at which the index grows by.
               This is expresed in seconds.
     */
    uint256 public savingsRate;

    /**
     * @notice The last time the index was updated
     */
    uint256 public indexLastUpdate;

    /**
     * @notice The total amount of synthetics supplied to this contract.
     *         This amount is the actual amount and not the principal amount.
     */
    uint256 public totalSupplied;

    /**
     * @notice How much of the interest earned ARC should take/keep.
     */
    Decimal.D256 public arcFee;

    /**
     * @dev Storage mapping of user's internal balances.
     */
    mapping (address => uint256) internal _balances;

    /**
     * @dev Storage mapping of user's allowances balances.
     */
    mapping (address => mapping (address => uint256)) internal _allowances;

}

/* solium-disable-next-line */
contract MozartSavingsStorage is MozartSavingsStorageV1 { }
