// SPDX-License-Identifier: ISC
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IVestingEscrow.sol";
import "./ILyra.sol";
import "./IStakedLyra.sol";
import "./UpgradeableBeacon.sol";
import "./BeaconProxy.sol";

/**
 * @title VestingEscrowFactory
 * @author Lyra
 * @dev Deploy VestingEscrow proxy contracts to distribute ERC20 tokens and acts as a beacon contract to determine
 * their implementation contract.
 */
contract VestingEscrowFactory2 is UpgradeableBeacon {
  /**
   * @dev Structs used to group escrow related data used in `deployVestingEscrow` function
   *
   * `recipient` The address of the recipient that will be receiving the tokens
   * `admin` The address of the admin that will have special execution permissions in the escrow contract.
   * `vestingAmount` Amount of tokens being vested for `recipient`
   * `vestingBegin` Epoch time when tokens begin to vest
   * `vestingCliff` Duration after which the first portion vests
   * `vestingEnd` Epoch Time until all the amount should be vested
   */
  struct EscrowData {
    address recipient;
    address admin;
    uint256 vestingAmount;
    uint256 vestingBegin;
    uint256 vestingCliff;
    uint256 vestingEnd;
  }

  uint256 public immutable deploymentTimestamp;
  IStakedLyra public stakedToken;

  event VestingEscrowCreated(
    address indexed funder,
    address indexed token,
    address indexed recipient,
    address admin,
    address escrow,
    uint256 amount,
    uint256 vestingBegin,
    uint256 vestingCliff,
    uint256 vestingEnd
  );

  event StakedTokenSet(address indexed stakedToken);

  /**
   * @dev Stores the implementation target for the proxies.
   *
   * Sets ownership to the account that deploys the contract.
   *
   * @param implementation_ The address of the target implementation
   */
  constructor(address implementation_) UpgradeableBeacon(implementation_) {
    deploymentTimestamp = block.timestamp;
  }

  /**
   * @dev Sets stakedToken address which will be used as a beacon for all the escrow contracts.
   * This is necessary as the safety module could be introduced after the deployment of the
   * escrow contracts.
   *
   * Requirements:
   *
   * - the caller must be the owner.
   * - `stakedToken_` should not be the zero address.
   *
   * @param stakedToken_ The address of the staked token implementation
   */
  function setStakedToken(address stakedToken_) external onlyOwner {
    require(stakedToken_ != address(0), "stakedToken is zero address");
    emit StakedTokenSet(stakedToken_);
    stakedToken = IStakedLyra(stakedToken_);
  }

  /**
   * @dev Deploys a proxy, initialize the vesting data and fund the escrow contract.
   *
   * @param escrowData Escrow related data
   * @return The address of the deployed contract
   */
  function deployVestingEscrow(EscrowData memory escrowData) external returns (address) {
    // Create the escrow contract
    address vestingEscrow = address(new BeaconProxy(address(this), ""));

    // Initialize the contract with the vesting data
    require(
      IVestingEscrow(vestingEscrow).initialize(
        escrowData.recipient,
        escrowData.vestingAmount,
        escrowData.vestingBegin,
        escrowData.vestingCliff,
        escrowData.vestingEnd
      ),
      "initialization failed"
    );

    // Transfer the ownership to the admin
    IVestingEscrow(vestingEscrow).transferOwnership(escrowData.admin);

    ILyra token = IVestingEscrow(vestingEscrow).token();

    // Transfer funds to the escrow contract
    token.transferFrom(msg.sender, vestingEscrow, escrowData.vestingAmount);

    emit VestingEscrowCreated(
      msg.sender,
      address(token),
      escrowData.recipient,
      escrowData.admin,
      vestingEscrow,
      escrowData.vestingAmount,
      escrowData.vestingBegin,
      escrowData.vestingCliff,
      escrowData.vestingEnd
    );

    return vestingEscrow;
  }
}
