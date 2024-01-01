// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./BenCoinV2.sol";
import "./SafeERC20.sol";

/**
 * @title BenV1ToV2Migration
 * @author Ben Coin Collective
 * @dev BenV1ToV2Migration allows users to migrate their BenV1 tokens to BenV2 tokens.
 * This contract facilitates the migration process.
 * The treasury is responsible for initiating the final migration process.
 *
 * BenV1 tokens are exchanged for BenV2 tokens at a specified rate (from 420.69 trillion BenV1 to 888 billion BenV2 supply).
 * and any remaining BenV2 tokens after the migration are sent to the treasury.
 */
contract BenV1ToV2Migration {
  using SafeERC20 for IERC20;
  using SafeERC20 for BenCoinV2;

  uint8 public initializedStep;

  BenCoinV2 public benV2;
  IERC20 public immutable benV1;
  uint40 public immutable deadlineForMigration;
  address public immutable treasury;
  uint104 public immutable maxV2Supply;
  uint128 public immutable maxV1Supply;

  uint256 private constant previouslyBurntV1Supply = 14_000_000_000_000 ether;

  error AlreadyInitializedStep1();
  error AlreadyInitializedStep2();
  error NotInitializedStep1();
  error NotInitializedStep2OrTreasury();
  error CannotUseZeroAddress();
  error CannotUseZero();
  error CannotUseDeadlineInPast();
  error NoTokensToClaim();
  error DeadlinePassed();
  error DeadlineNotPassed();
  error OnlyTreasury();

  modifier initializedStep1() {
    if (initializedStep < 1) {
      revert NotInitializedStep1();
    }
    _;
  }

  modifier notInitializedStep1() {
    if (initializedStep > 0) {
      revert AlreadyInitializedStep1();
    }
    _;
  }

  modifier initializedStep2OrTreasury() {
    if (initializedStep < 2 && msg.sender != treasury) {
      revert NotInitializedStep2OrTreasury();
    }
    _;
  }

  modifier notInitializedStep2() {
    if (initializedStep > 1) {
      revert AlreadyInitializedStep2();
    }
    _;
  }

  modifier onlyTreasury() {
    if (msg.sender != treasury) {
      revert OnlyTreasury();
    }
    _;
  }

  /**
   * @param _benV1 BEN Coin V1 contract address
   * @param _maxV2Supply The maximum supply of BEN Coin V2
   * @param _deadlineForMigration The deadline for the migration of Ben V1 to V2
   * @param _treasury The treasury address
   *
   * Constructor initializes key parameters for the migration process.
   *
   * It also performs validation checks to ensure the provided addresses and values are valid.
   */
  constructor(address _benV1, uint104 _maxV2Supply, uint40 _deadlineForMigration, address _treasury) {
    if (_benV1 == address(0) || _treasury == address(0)) {
      revert CannotUseZeroAddress();
    }

    if (_maxV2Supply == 0) {
      revert CannotUseZero();
    }

    if (_deadlineForMigration < block.timestamp) {
      revert CannotUseDeadlineInPast();
    }

    benV1 = IERC20(_benV1);
    deadlineForMigration = _deadlineForMigration;
    treasury = _treasury;
    maxV1Supply = uint128(benV1.totalSupply());
    maxV2Supply = _maxV2Supply;
  }

  /**
   * @notice Convert Ben V1 to BEN Coin V2, requires Ben V1 approval
   * @dev This function is only callable by the treasury or after flood gates are open
   *
   * Users can convert their BenV1 tokens to BenV2 tokens at the specified rate.
   * To do this, users must approve this contract to spend their BenV1 tokens.
   * After successful conversion, BenV2 tokens are transferred to the user.
   */
  function claim() external initializedStep2OrTreasury {
    if (deadlineForMigration < block.timestamp) {
      revert DeadlinePassed();
    }

    uint256 balance = benV1.balanceOf(msg.sender);
    if (balance == 0) {
      revert NoTokensToClaim();
    }

    // Transfer benV1 to this contract and mint benV2 to the user at the appropriate rate
    benV1.safeTransferFrom(msg.sender, address(this), balance);
    benV2.safeTransfer(msg.sender, conversionRate(balance));
  }

  /**
   * @notice Finish the migration and send the remainder of the V2 tokens to the treasury
   * @dev This function can be called by anyone after the deadline has passed
   *
   * After the migration deadline has passed, this function can be called by anyone to
   * send any remaining BenV2 tokens to the treasury.
   */
  function finishMigration() external {
    if (deadlineForMigration > block.timestamp) {
      revert DeadlineNotPassed();
    }

    // Send the remainder of the V2 tokens to the treasury
    uint balance = benV2.balanceOf(address(this));
    if (balance > 0) {
      benV2.safeTransfer(treasury, balance);
    }
  }

  /**
   * @notice Calculate the conversion rate from Ben V1 to Ben V2
   * @param _amountOfBenV1 The amount of Ben V1 to convert
   * @return amountOfBenV2 The amount of Ben V2 that would be received after conversion
   *
   * This function calculates the conversion rate for exchanging BenV1 tokens to BenV2 tokens.
   * It helps users determine the number of BenV2 tokens they will receive for a given amount of BenV1 tokens.
   */
  function conversionRate(uint _amountOfBenV1) public view returns (uint amountOfBenV2) {
    return (_amountOfBenV1 * maxV2Supply) / maxV1Supply;
  }

  /**
   * @notice Can only be called once to initialize the migration process
   * @param _benV2 BEN Coin V2 contract address
   * @dev This function can be called by anyone
   *
   * This function initializes the first step of the migration process. The previously
   * burnt BenV1 tokens are minted to the treasury.
   */
  function initializeStep1(BenCoinV2 _benV2) external notInitializedStep1 {
    initializedStep = 1;

    if (address(_benV2) == address(0)) {
      revert CannotUseZeroAddress();
    }

    benV2 = _benV2;

    // Transfer the previously burnt V1 tokens to the treasury
    uint previouslyBurntV1SupplyAsV2 = conversionRate(previouslyBurntV1Supply);
    _benV2.transfer(treasury, previouslyBurntV1SupplyAsV2);
  }

  /**
   * @notice This opens the flood gates to allow all other users to start the migration process
   * @dev This function is only callable by the treasury after initializeStep1 is completed
   *
   * After step 1 is completed, the treasury can call this function to allow all other users to
   * start the migration process, converting their BenV1 tokens to BenV2 tokens.
   */
  function initializeStep2() external initializedStep1 notInitializedStep2 onlyTreasury {
    initializedStep = 2;
  }
}
