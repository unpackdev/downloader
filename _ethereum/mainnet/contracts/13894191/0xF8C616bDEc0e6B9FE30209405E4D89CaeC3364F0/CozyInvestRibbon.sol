// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./ICozy.sol";
import "./ICozyInvest.sol";
import "./CozyInvestHelpers.sol";
import "./Address.sol";

interface IRibbon {
  function depositETH() external payable;

  function initiateWithdraw(uint256 numShares) external;

  function withdrawInstantly(uint256 amount) external;

  function completeWithdraw() external;
}

/**
 * @notice On-chain scripts for borrowing from Cozy and using the borrowed funds to
 * supply to curve and then deposit into Ribbon
 * @dev This contract is intended to be used by delegatecalling to it from a DSProxy
 */
contract CozyInvestRibbon is CozyInvestHelpers, ICozyInvest2 {
  using Address for address payable;
  using SafeERC20 for IERC20;

  /// @notice The unprotected money market we borrow from / repay to
  address public immutable moneyMarket;

  /// @notice The protection market we borrow from / repay to
  address public immutable protectionMarket;

  /// @notice Maximillion contract for repaying ETH debt
  IMaximillion public constant maximillion = IMaximillion(0xf859A1AD94BcF445A406B892eF0d3082f4174088);

  /// @notice Ribbon ETH theta vault contract address
  address public immutable ribbon = 0x25751853Eab4D0eB3652B5eB6ecB102A2789644B;

  constructor(address _moneyMarket, address _protectionMarket) {
    moneyMarket = _moneyMarket;
    protectionMarket = _protectionMarket;
  }

  /**
   * @notice Invest method for borrowing ETH and depositing it to Ribbon
   * @param _market Address of the market to borrow from
   * @param _borrowAmount Amount of underlying to borrow and invest
   */
  function invest(address _market, uint256 _borrowAmount) external {
    require((_market == address(moneyMarket) || _market == address(protectionMarket)), "Invalid borrow market");
    require(ICozyToken(_market).borrow(_borrowAmount) == 0, "Borrow failed");

    IRibbon _ribbon = IRibbon(ribbon);
    _ribbon.depositETH{value: _borrowAmount}();
  }

  /**
   * @notice Instantly withdraws funds from Ribbon that are available to withdraw.
   * @param _market Address of the market to repay debt to
   * @param _recipient Address where any leftover funds should be transferred
   * @param _withdrawAmount Amount of Curve receipt tokens to redeem
   */
  function withdrawInstantly(
    address _market,
    address _recipient,
    uint256 _withdrawAmount
  ) external payable {
    // 1. Borrow underlying from cozy
    require((_market == address(moneyMarket) || _market == address(protectionMarket)), "Invalid borrow market");

    // 2. Withdraws instantly from ribbon
    IRibbon _ribbon = IRibbon(ribbon);
    _ribbon.withdrawInstantly(_withdrawAmount);

    // 3. Pay back as much of the borrow as possible, excess ETH is refunded to `recipient`
    maximillion.repayBehalfExplicit{value: address(this).balance}(address(this), ICozyEther(_market));

    // 4. Transfer any remaining funds to the user
    payable(_recipient).sendValue(address(this).balance);
  }

  /**
   * @notice Initiates two-step divest method from Ribbon. completeWithdraw() must be called later once the next round has started.
   * @param _numShares Number of shares to divest
   */
  function divest(uint256 _numShares) external {
    IRibbon _ribbon = IRibbon(ribbon);
    _ribbon.initiateWithdraw(_numShares);
  }

  /**
   * @notice Instantly withdraws funds from Ribbon that are available to withdraw. divest() must be called beforehand.
   * @param _market Address of the market to repay debt to
   * @param _recipient Address where any leftover funds should be transferred
   */
  function completeWithdraw(address _market, address _recipient) external {
    require((_market == address(moneyMarket) || _market == address(protectionMarket)), "Invalid borrow market");

    // 1. Completes withdraw from Ribbon
    IRibbon _ribbon = IRibbon(ribbon);
    _ribbon.completeWithdraw();

    // 2. Pay back as much of the borrow as possible, excess ETH is refunded to `recipient`
    maximillion.repayBehalfExplicit{value: address(this).balance}(address(this), ICozyEther(_market));

    // 3. Transfer any remaining funds to the user
    payable(_recipient).sendValue(address(this).balance);
  }
}
