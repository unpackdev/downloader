// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./Address.sol";

import "./ICozy.sol";
import "./ICozyInvest.sol";

interface IRariPool is IERC20 {
  function deposit(string calldata currencyCode, uint256 amount) external;

  function withdraw(string calldata currencyCode, uint256 amount) external returns (uint256);

  function rariFundToken() external view returns (address);
}

/**
 * @notice On-chain scripts for borrowing from the Cozy-DAI-Rari Trigger protection market, and
 * depositing it to the Rari DAI pool.
 * @dev This contract is intended to be used by delegatecalling to it from a DSProxy
 */
contract CozyInvestRari is ICozyInvest2, ICozyDivest2 {
  using Address for address payable;
  using SafeERC20 for IERC20Metadata;

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

    IERC20Metadata _token = IERC20Metadata(token);
    IRariPool _poolManager = IRariPool(poolManager);

    // Approve the pool manager to spend. We only approve the borrow amount for security because
    // the pool mananger is an upgradeable proxy
    // Skip allowance check and just always approve, it's a minor swing in gas (0.08%) and makes it
    // cheaper to deploy
    _token.approve(address(_poolManager), _borrowAmount);

    // Deposit into the pool
    _poolManager.deposit(_token.symbol(), _borrowAmount);
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

    ICozyToken _market = ICozyToken(_marketAddress);

    // Withdraw from pool
    IERC20Metadata _token = IERC20Metadata(token);
    IRariPool _poolManager = IRariPool(poolManager);
    _poolManager.withdraw(_token.symbol(), _withdrawAmount);

    // Pay back as much of the borrow as possible, excess is refunded to `recipient`
    uint256 _borrowBalance = _market.borrowBalanceCurrent(address(this));
    uint256 _initialBalance = _token.balanceOf(address(this));
    if (_initialBalance < _borrowBalance && _excessTokens > 0) {
      _token.safeTransferFrom(msg.sender, address(this), _excessTokens);
    }
    uint256 _balance = _initialBalance + _excessTokens; // this contract's current balance
    uint256 _repayAmount = _balance >= _borrowBalance ? type(uint256).max : _balance;

    _token.approve(address(_market), _repayAmount);
    require(_market.repayBorrow(_repayAmount) == 0, "Repay failed");

    // Transfer any remaining tokens to the user after paying back borrow
    _token.transfer(_recipient, _token.balanceOf(address(this)));
  }
}
