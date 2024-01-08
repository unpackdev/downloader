// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./Address.sol";

import "./ICozy.sol";
import "./ICozyInvest.sol";

interface SaddlePool is IERC20 {
  function addLiquidity(
    uint256[] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  ) external returns (uint256);
}

interface AlchemixPool is IERC20 {
  function deposit(uint256 _poolId, uint256 _depositAmount) external;

  function withdraw(uint256 _poolId, uint256 _withdrawAmount) external;

  function claim(uint256 _poolId) external;

  function getPoolToken(uint256 _poolId) external returns (IERC20);

  function reward() external returns (IERC20);
}

interface WrappedEther is IERC20 {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

contract CozyInvestSaddleAlEth is ICozyInvest4, ICozyDivest4, ICozyReward {
  using Address for address payable;
  using SafeERC20 for IERC20;

  // --- Cozy markets ---
  /// @notice Cozy protection market with ETH underlying to borrow from: Saddle alETH
  address public immutable protectionMarket;

  /// @notice Cozy money market with ETH underlying
  address public immutable moneyMarket;

  /// @notice Address of Saddle's alETH pool
  address public immutable saddlePool = 0xa6018520EAACC06C30fF2e1B3ee2c7c22e64196a;

  /// @notice Alchemix pool address
  address public immutable alchemixPool = 0xAB8e74017a8Cc7c15FFcCd726603790d26d7DeCa;

  /// @notice Id of the Alchemix alETH pool
  uint256 public immutable alchemixPoolId = 6;

  /// @notice Index of the saddle pool (WETH, alETH, sETH)
  uint8 public immutable saddlePoolIndex = 0;

  /// @notice Maximillion contract for repaying ETH debt
  IMaximillion public constant maximillion = IMaximillion(0xf859A1AD94BcF445A406B892eF0d3082f4174088);

  /// @notice ALCX token
  IERC20 public immutable alcx;

  /// @notice Saddle LP token
  IERC20 public immutable saddleReceiptToken;

  /// @notice Wrapped Ether (to wrap and unwrap)
  WrappedEther public constant weth = WrappedEther(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  constructor(address _moneyMarket, address _protectionMarket) {
    moneyMarket = _moneyMarket;
    protectionMarket = _protectionMarket;

    saddleReceiptToken = IERC20(AlchemixPool(alchemixPool).getPoolToken(alchemixPoolId));
    alcx = IERC20(AlchemixPool(alchemixPool).reward());
  }

  /**
   * @notice Borrows from given Cozy ETH market,
   * wrapping it into WETH, depositing it into the Saddle alETH/WETH/sETH pool,
   * and then depositing that into the Alchemix alETH pool.
   * @param _marketAddress Address of the market to borrow ETH from
   * @param _borrowAmount Amount of ETH to borrow
   * @param _minToMint Minimum amount of saddle LP tokens to mint
   * @param _deadline Deadline txn should finish by
   */
  function invest(
    address _marketAddress,
    uint256 _borrowAmount,
    uint256 _minToMint,
    uint256 _deadline
  ) external {
    require(
      (_marketAddress == address(moneyMarket) || _marketAddress == address(protectionMarket)),
      "Invalid borrow market"
    );

    require(ICozyToken(_marketAddress).borrow(_borrowAmount) == 0, "Borrow failed");

    // 1. Call 'deposit' on WETH
    weth.deposit{value: _borrowAmount}();

    // 2. Approve Saddle to spend our WETH
    weth.approve(saddlePool, _borrowAmount);

    // 3. Add liquidity to the Saddle pool
    uint256[] memory tokenAmounts = new uint256[](3);
    tokenAmounts[0] = _borrowAmount;

    uint256 _saddleLpTokens = SaddlePool(saddlePool).addLiquidity(tokenAmounts, _minToMint, _deadline);

    // 4. Call "deposit" on alchemix address
    saddleReceiptToken.approve(alchemixPool, _saddleLpTokens);
    AlchemixPool(alchemixPool).deposit(alchemixPoolId, _saddleLpTokens);
  }

  /**
   * @notice Protected divest method for exiting a position entered using this contract's `invest` method
   * @param _marketAddress Address of the market to repay ETH to
   * @param _recipient Address of the owner's wallet
   * @param _withdrawAmount Amount to withdraw
   * @param _minWithdrawAmount Minimum amount of WETH we should receive
   * @param _deadline Deadline txn should finish by
   *
   * @dev note: This also claims Alchemix rewards.
   */
  function divest(
    address _marketAddress,
    address _recipient,
    uint256 _withdrawAmount,
    uint256 _minWithdrawAmount,
    uint256 _deadline
  ) external payable {
    require(
      (_marketAddress == address(moneyMarket) || _marketAddress == address(protectionMarket)),
      "Invalid borrow market"
    );

    // 1. Exit from Alchemix (this also claims rewards)
    AlchemixPool(alchemixPool).withdraw(alchemixPoolId, _withdrawAmount);

    // 2. Remove liquidity
    saddleReceiptToken.approve(saddlePool, _withdrawAmount);
    uint256 _wethAmountReceived = SaddlePool(saddlePool).removeLiquidityOneToken(
      _withdrawAmount,
      saddlePoolIndex,
      _minWithdrawAmount,
      _deadline
    );

    // 3. Unwrap WETH
    weth.withdraw(_wethAmountReceived);

    // 4. Pay back as much of the borrow as possible, excess ETH is refunded to `recipient`
    maximillion.repayBehalfExplicit{value: address(this).balance}(address(this), ICozyEther(_marketAddress));

    // 5. Transfer any remaining funds to the user
    payable(_recipient).sendValue(address(this).balance);

    // 6. Restake remaining LP tokens if there are any
    uint256 _saddleLpBalance = saddleReceiptToken.balanceOf(address(this));
    if (_saddleLpBalance > 0) {
      saddleReceiptToken.approve(alchemixPool, _saddleLpBalance);
      // Call "deposit" on alchemix address
      AlchemixPool(alchemixPool).deposit(alchemixPoolId, _saddleLpBalance);
    }

    // Transfer any remaining reward tokens
    alcx.transfer(_recipient, alcx.balanceOf(address(this)));
  }

  /**
   * @notice Method to claim rewards from Alchemix.
   * @param _recipient Address of the owner's wallet
   */
  function claimRewards(address _recipient) external {
    AlchemixPool(alchemixPool).claim(alchemixPoolId);
    // Transfer any remaining reward tokens
    alcx.transfer(_recipient, alcx.balanceOf(address(this)));
  }
}
