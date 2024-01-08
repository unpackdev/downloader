// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20Metadata.sol";
import "./ICozyInvest.sol";
import "./CozyInvestHelpers.sol";

interface IRariPool is IERC20 {
  function deposit(string calldata currencyCode, uint256 amount) external;

  function withdraw(string calldata currencyCode, uint256 amount) external returns (uint256);

  function rariFundToken() external view returns (address);
}

/**
 * @notice On-chain scripts for borrowing from the Cozy-DAI-Rari Trigger protection market, and
 * depositing it to the Rari DAI pool.
 * @dev This contract is intended to be used by delegatecalling to it from a DSProxy
 * @dev This contract won't work if `token` is like USDT in that it's `approve` method tries to mitigate the ERC-20
 * approval attack described here: https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
 */
contract CozyInvestRari is CozyInvestHelpers, ICozyInvest2, ICozyDivest2 {
  /// @notice The unprotected money market we borrow from / repay to
  address public immutable moneyMarket;
  /// @notice The protected version of the market
  address public immutable protectionMarket;
  /// @notice Rari pool manager
  address public immutable poolManager;
  /// @notice Rari receipt token
  address public immutable rariPoolToken;
  /// @notice Rari market this invest integration is for (e.g. DAI, USDC)
  address public immutable token;

  constructor(
    address _moneyMarket,
    address _protectionMarket,
    address _poolManager,
    address _token
  ) {
    moneyMarket = _moneyMarket;
    protectionMarket = _protectionMarket;
    poolManager = _poolManager;
    rariPoolToken = IRariPool(_poolManager).rariFundToken();
    token = _token;
  }

  /**
   * @notice invest method for borrowing from a given market address and then depositing to the Rari pool
   * @param _marketAddress Market address to borrow from
   * @param _borrowAmount Amount to borrow and deposit into the Rari pool
   */
  function invest(address _marketAddress, uint256 _borrowAmount) external {
    require((_marketAddress == moneyMarket || _marketAddress == protectionMarket), "Invalid borrow market");
    ICozyToken _market = ICozyToken(_marketAddress);

    // Borrow from market
    require(_market.borrow(_borrowAmount) == 0, "Borrow failed");

    // Approve the pool manager to spend. We only approve the borrow amount for security because
    // the pool mananger is an upgradeable proxy
    // Skip allowance check and just always approve, it's a minor swing in gas (0.08%) and makes it
    // cheaper to deploy
    TransferHelper.safeApprove(token, poolManager, _borrowAmount);

    // Deposit into the pool
    IRariPool(poolManager).deposit(IERC20Metadata(token).symbol(), _borrowAmount);
  }

  /**
   * @notice Protected divest method for exiting a position entered using this contract's `invest` method
   * @param _marketAddress Market address to repay to
   * @param _recipient Address where any leftover tokens should be transferred
   * @param _withdrawAmount Amount to withdraw
   * @param _excessTokens Quantity to transfer from the caller into this address to ensure
   * the borrow can be repaid in full. Only required if you want to repay the full borrow amount and the
   * amount obtained from withdrawing from Rari will not cover the full debt. A value of zero will not
   * attempt to transfer tokens from the caller, and the transfer will not be attempted if it's not required
   */
  function divest(
    address _marketAddress,
    address _recipient,
    uint256 _withdrawAmount,
    uint256 _excessTokens
  ) external {
    // Check trigger
    require((_marketAddress == moneyMarket || _marketAddress == protectionMarket), "Invalid borrow market");

    // Withdraw from pool
    IRariPool(poolManager).withdraw(IERC20Metadata(token).symbol(), _withdrawAmount);

    // Pay back as much of the borrow as possible, excess is refunded to `recipient`
    executeMaxRepay(_marketAddress, token, _excessTokens);

    // Transfer any remaining tokens to the user after paying back borrow
    TransferHelper.safeTransfer(token, _recipient, IERC20(token).balanceOf(address(this)));
  }
}
