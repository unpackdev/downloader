// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

import "./IOracle.sol";

import "./Decimal.sol";
import "./Amount.sol";

import "./MozartTypes.sol";

/**
 * @title MoazartStorage
 * @author Kerman Kohli
 * @notice The storage contract that gets used inside MozartCoreV1.
 *         IMPORTANT:
 *         - DO NOT change the order of ANY variables
 *         - If you would like to add more variables, create a a new
 *           versioned contract (MozartStorageV99) and inherit from
 *           it via MozartStorage
 */
contract MozartCoreStorageV1 {

    /**
     * @notice Determines whether the contract is paused or not
     */
    bool public paused;

    /**
     * @notice An active counter of all the number of positions in the protocol
     */
    uint256 public positionCount;

    /**
     * @dev The details about a vault, identified by a unint256
     */
    mapping (uint256 => MozartTypes.Position) internal positions;

    /**
     * @dev Allow a position have multiple addresses act on its behalf
     */
    mapping (uint256 => mapping (address => bool)) internal positionOperators;

    /**
     * @dev Allow an address to act on behalf of any position.
     */
    mapping (address => bool) internal globalOperators;

    /**
     * @dev The instance of the oracle that reports prices for this synth
     */
    IOracle internal oracle;

    /**
     * @dev If a collateral asset is used that has less than 18 decimal places
     *      a precision scalar is required to calcualte the corect values.
     */
    uint256 internal precisionScalar;

    /**
     * @dev The actual address of the collateral used for this core system.
     */
    address internal collateralAsset;

    /**
     * @dev The address of the synthetic token where this core is approved to mint from
     */
    address internal syntheticAsset;

    /**
     * @dev The actual amount of collateral provided to the protocol. This amount
     *      will be multiplied by the precision scalar if the token has less than 18 d.p
     */
    uint256 internal totalSupplied;

    /**
     * @dev An account of the total amount being borrowed by all depositors. This includes
     *      the amount of interest accrued.
     */
    uint256 internal totalBorrowed;

    /**
     * @dev The accumulated borrow index. Each time a borrows, their borrow amount is expressed
     *      in relation to the borrow index.
     */
    uint256 internal borrowIndex;

    /**
     * @dev The last time the updateIndex() function was called. This helps to determine how much
     *      interest has accrued in the contract since a user interacted with the protocol.
     */
    uint256 internal indexLastUpdate;

    /**
     * @dev The interest rate charged to borrowers. Expressed as the interest rate per second and 18 d.p
     */
    uint256 internal interestRate;

    /**
     * @dev The ratio of how much collateral should have relative to its debt
     */
    Decimal.D256 internal collateralRatio;

    /**
     * @dev How much should the liquidation penalty be, expressed as a decimal.
     */
    Decimal.D256 internal liquidationUserFee;

    /**
     * @dev How much of the profit acquired from a liquidation should ARC receive
     */
    Decimal.D256 internal liquidationArcRatio;

    /**
     * @notice Which address can set interest rates for this contract
     */
    address internal interestSetter;

    /**
     * @dev The limit of how much collateral can be deposited from this contract.
     */
    uint256 internal collateralLimit;

    /**
     * @dev The amount of collateral a new position should have at the minimum
     */
    uint256 internal positionCollateralMinimum;
}

contract MozartCoreStorage is MozartCoreStorageV1 { /* solium-disable-line no-empty-blocks */ }
