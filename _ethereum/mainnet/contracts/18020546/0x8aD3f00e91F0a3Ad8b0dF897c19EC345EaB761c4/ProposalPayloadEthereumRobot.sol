// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAaveCLRobotOperator.sol";
import "./AaveV3Ethereum.sol";
import "./AaveV2Ethereum.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeCast.sol";

/**
 * @title ProposalPayloadEthereumRobot
 * @author BGD Labs
 * @dev Proposal to fund Chainlink Keeper for Governance Automation (gov v2) and compensate bgd labs for previous spendings on robot.
 * - Transfer aLink tokens from collector to the short executor
 * - Withdraw aLink to get link token from the Aave v2 Pool
 * - Refill the Chainlink Keeper with link via the operator contract
 * - Transfer link tokens from short executor to bgd labs
 */
contract ProposalPayloadEthereumRobot {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  address public immutable ROBOT_OPERATOR;
  uint256 public immutable LINK_AMOUNT_TO_KEEPER;
  uint256 public immutable KEEPER_ID;

  address public constant BGD_RECIPIENT = 0xb812d0944f8F581DfAA3a93Dda0d22EcEf51A9CF;
  uint256 public constant LINK_AMOUNT_TO_BGD = 600e18;

  /**
   * @dev constructor of the proposal
   * @param keeperId the chainlink id of the pre-registered keeper.
   * @param robotOperator the address of the aave chainlink robot operator
   * @param amountToFund the amount of link tokens to fund the keeper
   */
  constructor(uint256 keeperId, address robotOperator, uint256 amountToFund) {
    KEEPER_ID = keeperId;
    ROBOT_OPERATOR = robotOperator;
    LINK_AMOUNT_TO_KEEPER = amountToFund;
  }

  function execute() external {
    // transfer aLink from collector to the short executor
    AaveV3Ethereum.COLLECTOR.transfer(
      address(AaveV2EthereumAssets.LINK_A_TOKEN),
      address(this),
      LINK_AMOUNT_TO_KEEPER + LINK_AMOUNT_TO_BGD
    );

    // withdraw aLink from the Aave V2 Pool
    AaveV2Ethereum.POOL.withdraw(
      address(AaveV2EthereumAssets.LINK_UNDERLYING),
      LINK_AMOUNT_TO_KEEPER + LINK_AMOUNT_TO_BGD,
      address(this)
    );

    // approve link to the operator in order to refill the keeper
    IERC20(AaveV2EthereumAssets.LINK_UNDERLYING).forceApprove(
      ROBOT_OPERATOR,
      LINK_AMOUNT_TO_KEEPER
    );

    // refills the keeper with link
    IAaveCLRobotOperator(ROBOT_OPERATOR).refillKeeper(
      KEEPER_ID,
      LINK_AMOUNT_TO_KEEPER.toUint96()
    );

    // transfer link token to bgd labs to compensate for previous spendings on robot
    IERC20(AaveV2EthereumAssets.LINK_UNDERLYING).safeTransfer(
      BGD_RECIPIENT,
      LINK_AMOUNT_TO_BGD
    );
  }
}
