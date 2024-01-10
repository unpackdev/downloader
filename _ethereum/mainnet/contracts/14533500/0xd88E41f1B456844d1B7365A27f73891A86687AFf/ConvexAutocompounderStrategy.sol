// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Router02.sol";
import "./AConvexAutocompounder.sol";
import "./BasePairLPStrategy.sol";
import "./UniswapV2Library.sol";

contract ConvexAutocompounder is AConvexAutocompounder, BasePairLPStrategy {
  using SafeERC20 for IERC20;
  using OndoSaferERC20 for IERC20;

  string public constant name = "Convex Autocompounder Strategy";
  address public immutable uniFactory;
  IUniswapV2Router02 public immutable uniRouter02;
  uint256 threeCrvLPAmount;
  int128 seniorCrvIndex;
  int128 juniorCrvIndex;

  /**
   * @dev Setup contract dependencies here
   * @param _stableAsset single asset
   * @param _registry Pointer to Registry
   * @param _lpSettings The array of lp Setting structs for the tokens which we
   * Wish to farm on CVX
   * @param _rewardTokens An array of tokens that we will reveive as rewards for providing
   * the LP tokens to CVX
   * @param _factory The uniswap factory.
   * @param _router The uniswap Router that we will be swapping through for the rebalance
   */
  constructor(
    address _stableAsset,
    address _registry,
    LPSetting[] memory _lpSettings,
    address[] memory _rewardTokens,
    address _factory,
    address _router
  )
    AConvexAutocompounder(_stableAsset, _lpSettings, _rewardTokens)
    BasePairLPStrategy(_registry)
  {
    uniFactory = _factory;
    uniRouter02 = IUniswapV2Router02(_router);
  }

  /**
   * @notice Register a Vault with the strategy
   * @param _vaultId Vault
   * @param _senior Asset for senior tranche
   * @param _junior Asset for junior tranche
   */
  function addVault(
    uint256 _vaultId,
    IERC20 _senior,
    IERC20 _junior
  ) external override whenNotPaused nonReentrant isAuthorized(OLib.VAULT_ROLE) {
    require(
      address(vaults[_vaultId].origin) == address(0),
      "Vault id already registered"
    );

    vaults[_vaultId].origin = IPairVault(msg.sender);
    vaults[_vaultId].senior = _senior;
    vaults[_vaultId].junior = _junior;

    seniorCrvIndex = stableToIndex[address(_senior)];
    juniorCrvIndex = stableToIndex[address(_junior)];
  }

  /**
   * @notice invest stable asset
   * @dev we assume that all senior and junior will be invested, hence returning the same input values to AllPair
   * @return _totalSenior senior stable asset invested
   * @return _totalJunior junior stable asset invested
   */
  function invest(
    uint256 _vaultId,
    uint256 _totalSenior,
    uint256 _totalJunior,
    uint256 _extraSenior,
    uint256 _extraJunior,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  )
    external
    override
    nonReentrant
    whenNotPaused
    onlyOrigin(_vaultId)
    returns (uint256, uint256)
  {
    Vault storage vault_ = vaults[_vaultId];

    uint256 prev3CRVAmount = get3CRVAmount();
    _splitAndDepositConvex();
    uint256 new3CRVAmount = get3CRVAmount() - prev3CRVAmount;
    // calculate shares
    uint256 shares;
    if (totalSupply == 0) {
      shares = new3CRVAmount;
    } else {
      shares = OLib.safeMulDiv(new3CRVAmount, totalSupply, prev3CRVAmount);
    }

    // Assume everything was invested.
    vault_.seniorExcess = 0;
    vault_.juniorExcess = 0;
    _mint(_vaultId, shares);
    emit Invest(_vaultId, shares);
    return (_totalSenior, _totalJunior);
  }

  /**
   * @dev redeem stable asset
   */
  function redeem(
    uint256 _vaultId,
    uint256 _seniorExpected,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  )
    external
    override
    nonReentrant
    whenNotPaused
    onlyOrigin(_vaultId)
    returns (uint256 seniorReceived, uint256 juniorReceived)
  {
    uint256 amountOfLp;

    uint256 shares = balanceOf[_vaultId];
    require(shares > 0, "No invest");
    Vault storage vault_ = vaults[_vaultId];

    uint256[] memory lpAmounts = getLPAmounts();
    for (uint256 i = 0; i < lpAmounts.length; ++i) {
      _withdraw3CrvLP(i, OLib.safeMulDiv(lpAmounts[i], shares, totalSupply));
    }
    amountOfLp = THREE_CRV_LP.balanceOf(address(this));
    _swapLpToStablesVault(_seniorMinOut, _juniorMinOut, amountOfLp);

    seniorReceived = vault_.senior.balanceOf(address(this));
    juniorReceived = vault_.junior.balanceOf(address(this));

    if (address(vault_.senior) != address(vault_.junior)) {
      if (seniorReceived < _seniorExpected) {
        (seniorReceived, juniorReceived) = _swapForSr(
          _vaultId,
          address(vault_.senior),
          address(vault_.junior),
          _seniorExpected,
          seniorReceived,
          juniorReceived
        );
      } else {
        if (seniorReceived > _seniorExpected) {
          address[] memory path = new address[](2);
          path[0] = address(vault_.senior);
          path[1] = address(vault_.junior);

          juniorReceived += _swapExactIn(
            seniorReceived - _seniorExpected,
            0,
            path
          );
        }
        seniorReceived = _seniorExpected;
      }
    } else {
      // Divide the sr & jr received by 2, because they are same asset.
      // Call to balanceOf() on line 145 will report double value for both variables.
      seniorReceived = seniorReceived / 2;
      juniorReceived = juniorReceived / 2;

      if (_seniorExpected > seniorReceived) {
        uint256 seniorNeeded = _seniorExpected - seniorReceived;
        if (seniorNeeded > juniorReceived) {
          seniorReceived += juniorReceived;
          juniorReceived = 0;
        } else {
          seniorReceived = _seniorExpected;
          juniorReceived -= seniorNeeded;
        }
      } else if (seniorReceived > _seniorExpected) {
        juniorReceived += seniorReceived - _seniorExpected;
        seniorReceived = _seniorExpected;
      }
    }
    require(
      _seniorMinOut <= seniorReceived && _juniorMinOut <= juniorReceived,
      "Too Much Slippage"
    );

    vault_.senior.ondoSafeIncreaseAllowance(msg.sender, seniorReceived);
    vault_.junior.ondoSafeIncreaseAllowance(msg.sender, juniorReceived);

    _burn(_vaultId, shares);
    emit Redeem(_vaultId);
    return (seniorReceived, juniorReceived);
  }

  function _withdraw3CrvLP(uint256 pId, uint256 lpAmountToWithdraw) internal {
    LPSetting memory setting = lpSettings[pId];
    setting.cvxReward.withdrawAndUnwrap(lpAmountToWithdraw, false);

    // unwrap if not 3CRV
    if (setting.lpAddress == THREE_CRV_LP) {
      threeCrvLPAmount = lpAmountToWithdraw;
    } else {
      if (ICurve_2(setting.lpMinterAddress).coins(0) == address(THREE_CRV_LP)) {
        threeCrvLPAmount = ICurve_2(setting.lpMinterAddress)
          .remove_liquidity_one_coin(lpAmountToWithdraw, 0, 0);
      } else {
        threeCrvLPAmount = ICurve_2(setting.lpMinterAddress)
          .remove_liquidity_one_coin(lpAmountToWithdraw, 1, 0);
      }
    }
  }

  function _swapLpToStablesVault(
    uint256 srMinAsset,
    uint256 jrMinAsset,
    uint256 amountOfLp
  ) internal {
    THREE_CRV_MINTER.remove_liquidity_one_coin(
      (amountOfLp * 50) / 100,
      seniorCrvIndex,
      srMinAsset
    );

    THREE_CRV_MINTER.remove_liquidity_one_coin(
      (amountOfLp * 50) / 100,
      juniorCrvIndex,
      jrMinAsset
    );
  }

  function _swapForSr(
    uint256 _vaultId,
    address _senior,
    address _junior,
    uint256 _seniorExpected,
    uint256 seniorReceived,
    uint256 juniorReceived
  ) internal returns (uint256, uint256) {
    uint256 seniorNeeded = _seniorExpected - seniorReceived;
    Vault storage vault_ = vaults[_vaultId];
    address[] memory jr2Sr = new address[](2);
    jr2Sr[0] = address(vault_.junior);
    jr2Sr[1] = address(vault_.senior);
    if (
      seniorNeeded >
      UniswapV2Library.getAmountsOut(uniFactory, juniorReceived, jr2Sr)[1]
    ) {
      seniorReceived += _swapExactIn(juniorReceived, 0, jr2Sr);
      return (seniorReceived, 0);
    } else {
      juniorReceived -= _swapExactOut(seniorNeeded, juniorReceived, jr2Sr);
      return (_seniorExpected, juniorReceived);
    }
  }

  function _swapExactIn(
    uint256 amtIn,
    uint256 minOut,
    address[] memory path
  ) internal returns (uint256) {
    IERC20(path[0]).ondoSafeIncreaseAllowance(address(uniRouter02), amtIn);
    return
      uniRouter02.swapExactTokensForTokens(
        amtIn,
        minOut,
        path,
        address(this),
        block.timestamp
      )[path.length - 1];
  }

  /**
   * @notice Simple wrapper around uniswap
   * @param amtOut Amount out
   * @param maxIn Maximum tokens offered as input
   * @param path Router path
   */
  function _swapExactOut(
    uint256 amtOut,
    uint256 maxIn,
    address[] memory path
  ) internal returns (uint256) {
    IERC20(path[0]).ondoSafeIncreaseAllowance(address(uniRouter02), maxIn);
    return
      uniRouter02.swapTokensForExactTokens(
        amtOut,
        maxIn,
        path,
        address(this),
        block.timestamp
      )[0];
  }

  function sharesFromLp(uint256 vaultId, uint256 lpTokens)
    external
    view
    override
    returns (
      uint256 shares,
      uint256 vaultShares,
      IERC20 pool
    )
  {
    revert();
  }

  function lpFromShares(uint256 vaultId, uint256 shares)
    external
    view
    override
    returns (uint256 lpTokens, uint256 vaultShares)
  {
    revert();
  }
}
