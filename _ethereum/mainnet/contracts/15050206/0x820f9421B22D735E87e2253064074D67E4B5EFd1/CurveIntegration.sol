// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.9;

import "./CoinStatsBaseV1.sol";
import "./IntegrationInterface.sol";

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;
}

// solhint-disable func-name-mixedcase, var-name-mixedcase
interface ICurveSwap {
  function underlying_coins(int128 arg0) external view returns (address);

  function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
    external;

  function add_liquidity(
    uint256[4] calldata amounts,
    uint256 min_mint_amount,
    bool addUnderlying
  ) external;

  function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
    external;

  function add_liquidity(
    uint256[3] calldata amounts,
    uint256 min_mint_amount,
    bool addUnderlying
  ) external;

  function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
    external;

  function add_liquidity(
    uint256[2] calldata amounts,
    uint256 min_mint_amount,
    bool addUnderlying
  ) external;

  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 min_amount
  ) external;

  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 min_amount,
    bool removeUnderlying
  ) external;

  function remove_liquidity_one_coin(
    uint256 _token_amount,
    uint256 i,
    uint256 min_amount
  ) external;

  function calc_withdraw_one_coin(uint256 tokenAmount, int128 underlyingIndex)
    external
    view
    returns (uint256);

  function calc_withdraw_one_coin(
    uint256 tokenAmount,
    int128 underlyingIndex,
    bool _use_underlying
  ) external view returns (uint256);

  function calc_withdraw_one_coin(uint256 tokenAmount, uint256 underlyingIndex)
    external
    view
    returns (uint256);
}

interface ICurveEthSwap {
  function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
    external
    payable
    returns (uint256);
}

interface ICurveRegistry {
  function getSwapAddress(address tokenAddress)
    external
    view
    returns (address poolAddress);

  function getTokenAddress(address poolAddress)
    external
    view
    returns (address tokenAddress);

  function getDepositAddress(address poolAddress)
    external
    view
    returns (address depositAddress);

  function getPoolTokens(address poolAddress)
    external
    view
    returns (address[8] memory poolTokens);

  function shouldUseUnderlying(address poolAddress)
    external
    view
    returns (bool);

  function getNumTokens(address poolAddress)
    external
    view
    returns (uint8 numTokens);

  function isEthPool(address poolAddress) external view returns (bool);

  function isCryptoPool(address poolAddress) external view returns (bool);

  function isFactoryPool(address poolAddress) external view returns (bool);

  function isUnderlyingToken(address poolAddress, address tokenContractAddress)
    external
    view
    returns (bool, uint8);
}

contract CurveIntegration is IntegrationInterface, CoinStatsBaseV1 {
  using SafeERC20 for IERC20;

  ICurveRegistry public curveRegistry;

  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  mapping(address => bool) internal v2Pool;

  constructor(
    ICurveRegistry _curveRegistry,
    uint256 _goodwill,
    uint256 _affiliateSplit,
    address _vaultAddress
  ) CoinStatsBaseV1(_goodwill, _affiliateSplit, _vaultAddress) {
    // Curve pool address registry
    curveRegistry = _curveRegistry;

    // 0x exchange
    approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    // 1inch exchange
    approvedTargets[0x1111111254fb6c44bAC0beD2854e76F90643097d] = true;
  }

  event Deposit(
    address indexed from,
    address indexed pool,
    uint256 poolTokensReceived,
    address affiliate
  );
  event Withdraw(
    address indexed from,
    address indexed pool,
    uint256 poolTokensReceived,
    address affiliate
  );

  /**
    @notice Returns pools total supply2
    @param poolAddress Curve pool address from which to get supply
   */
  function getTotalSupply(address poolAddress) public view returns (uint256) {
    address tokenAddress = curveRegistry.getTokenAddress(poolAddress);
    return IERC20(tokenAddress).totalSupply();
  }

  /**
    @notice Returns account balance from pool
    @param poolAddress Curve pool address from which to get balance
    @param account The account
   */
  function getBalance(address poolAddress, address account)
    public
    view
    override
    returns (uint256)
  {
    address tokenAddress = curveRegistry.getTokenAddress(poolAddress);
    return IERC20(tokenAddress).balanceOf(account);
  }

  /**
    @notice Adds liquidity to any Curve pools with ETH or ERC20 tokens
    @param entryTokenAddress The token used for entry (address(0) if ETH).
    @param entryTokenAmount The depositAmount of entryTokenAddress to invest
    @param poolAddress Curve swap address for the pool
    @param depositTokenAddress Token to be transfered to poolAddress
    @param minExitTokenAmount Min acceptable amount of liquidity/stake tokens to reeive
    @param / underlyingTarget Underlying target which will execute swap
    @param / targetDepositTokenAddress Token which will be used to deposit fund in target contract
    @param swapTarget Underlying target's swap target
    @param swapData Data for swap
    @param affiliate Affiliate address 
    */

  function deposit(
    address entryTokenAddress,
    uint256 entryTokenAmount,
    address poolAddress,
    address depositTokenAddress, // Token to enter curve pool
    uint256 minExitTokenAmount,
    address,
    address,
    address swapTarget,
    bytes calldata swapData,
    address affiliate
  ) external payable override whenNotPaused {
    // Transfer {entryTokens} to contract
    entryTokenAmount = _pullTokens(entryTokenAddress, entryTokenAmount);

    // Subtract goodwill
    entryTokenAmount -= _subtractGoodwill(
      entryTokenAddress,
      entryTokenAmount,
      affiliate,
      true
    );

    if (entryTokenAddress == address(0)) {
      entryTokenAddress = ETH_ADDRESS;
    }

    uint256 tokensReceived = _makeDeposit(
      entryTokenAddress,
      entryTokenAmount,
      depositTokenAddress,
      poolAddress,
      swapTarget,
      swapData,
      minExitTokenAmount
    );

    address poolTokenAddress = curveRegistry.getTokenAddress(poolAddress);

    IERC20(poolTokenAddress).safeTransfer(msg.sender, tokensReceived);

    emit Deposit(msg.sender, poolTokenAddress, tokensReceived, affiliate);
  }

  function _makeDeposit(
    address entryTokenAddress,
    uint256 entryTokenAmount,
    address depositTokenAddress,
    address poolAddress,
    address swapTarget,
    bytes memory swapData,
    uint256 minExitTokenAmount
  ) internal returns (uint256 tokensReceived) {
    // First Underlying Check
    (bool isUnderlying, uint8 underlyingIndex) = curveRegistry
      .isUnderlyingToken(poolAddress, entryTokenAddress);

    if (isUnderlying) {
      tokensReceived = _enterCurve(
        poolAddress,
        entryTokenAmount,
        underlyingIndex
      );
    } else {
      // Swap {entryToken} to {depositToken}
      uint256 depositTokenAmount = _fillQuote(
        entryTokenAddress,
        entryTokenAmount,
        depositTokenAddress,
        swapTarget,
        swapData
      );

      // Second Underlying Check
      (isUnderlying, underlyingIndex) = curveRegistry.isUnderlyingToken(
        poolAddress,
        depositTokenAddress
      );

      if (isUnderlying) {
        tokensReceived = _enterCurve(
          poolAddress,
          depositTokenAmount,
          underlyingIndex
        );
      } else {
        (uint256 tokens, uint256 metaIndex) = _enterMetaPool(
          poolAddress,
          depositTokenAddress,
          depositTokenAmount
        );
        tokensReceived = _enterCurve(poolAddress, tokens, metaIndex);
      }

      require(
        tokensReceived > minExitTokenAmount,
        "MakeDeposit: Received less than expected"
      );
    }
  }

  /**
    @notice Adds the liquidity for meta pools and returns the token underlyingIndex and swap tokens
    @param poolAddress Curve swap address for the pool
    @param depositTokenAddress The ERC20 token to which from token to be convert
    @param swapTokens quantity of exitTokenAddress to invest
    @return depositTokenAmount quantity of curve LP acquired
    @return underlyingIndex underlyingIndex of LP token in poolAddress whose pool tokens were acquired
  */
  function _enterMetaPool(
    address poolAddress,
    address depositTokenAddress,
    uint256 swapTokens
  ) internal returns (uint256 depositTokenAmount, uint256 underlyingIndex) {
    address[8] memory poolTokens = curveRegistry.getPoolTokens(poolAddress);
    for (uint256 i = 0; i < 8; i++) {
      address intermediateSwapAddress;
      if (poolTokens[i] != address(0)) {
        intermediateSwapAddress = curveRegistry.getSwapAddress(poolTokens[i]);
      }
      if (intermediateSwapAddress != address(0)) {
        (, underlyingIndex) = curveRegistry.isUnderlyingToken(
          intermediateSwapAddress,
          depositTokenAddress
        );

        depositTokenAmount = _enterCurve(
          intermediateSwapAddress,
          swapTokens,
          underlyingIndex
        );

        return (depositTokenAmount, i);
      }
    }
  }

  function _fillQuote(
    address inputTokenAddress,
    uint256 inputTokenAmount,
    address outputTokenAddress,
    address swapTarget,
    bytes memory swapData
  ) internal returns (uint256 outputTokensBought) {
    if (inputTokenAddress == outputTokenAddress) {
      return inputTokenAmount;
    }

    if (swapTarget == WETH) {
      if (
        outputTokenAddress == address(0) || outputTokenAddress == ETH_ADDRESS
      ) {
        IWETH(WETH).withdraw(inputTokenAmount);
        return inputTokenAmount;
      } else {
        IWETH(WETH).deposit{value: inputTokenAmount}();
        return inputTokenAmount;
      }
    }

    uint256 value;
    if (inputTokenAddress == ETH_ADDRESS) {
      value = inputTokenAmount;
    } else {
      _approveToken(inputTokenAddress, swapTarget);
    }

    uint256 initialOutputTokenBalance = _getBalance(outputTokenAddress);

    // solhint-disable-next-line reason-string
    require(approvedTargets[swapTarget], "FillQuote: Target is not approved");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = swapTarget.call{value: value}(swapData);

    require(success, "FillQuote: Failed to swap tokens");

    outputTokensBought =
      _getBalance(outputTokenAddress) -
      initialOutputTokenBalance;

    // solhint-disable-next-line reason-string
    require(outputTokensBought > 0, "FillQuote: Swapped to invalid token");
  }

  /**
        @notice This function adds liquidity to a curve pool
        @param poolAddress Curve swap address for the pool
        @param amount The quantity of tokens being added as liquidity
        @param underlyingIndex The token underlyingIndex for the add_liquidity call
        @return poolTokensReceived the quantity of curve LP tokens received
    */
  function _enterCurve(
    address poolAddress,
    uint256 amount,
    uint256 underlyingIndex
  ) internal returns (uint256 poolTokensReceived) {
    address tokenAddress = curveRegistry.getTokenAddress(poolAddress);
    address depositAddress = curveRegistry.getDepositAddress(poolAddress);
    uint256 initialBalance = _getBalance(tokenAddress);
    address entryToken = curveRegistry.getPoolTokens(poolAddress)[
      underlyingIndex
    ];
    if (entryToken != ETH_ADDRESS) {
      _approveToken(entryToken, depositAddress);
      // IERC20(entryToken).safeIncreaseAllowance(address(depositAddress), amount);
    }

    uint256 numTokens = curveRegistry.getNumTokens(poolAddress);

    bool shouldUseUnderlying = curveRegistry.shouldUseUnderlying(poolAddress);

    if (numTokens == 4) {
      uint256[4] memory amounts;
      amounts[underlyingIndex] = amount;
      if (shouldUseUnderlying) {
        ICurveSwap(depositAddress).add_liquidity(amounts, 0, true);
      } else {
        ICurveSwap(depositAddress).add_liquidity(amounts, 0);
      }
    } else if (numTokens == 3) {
      uint256[3] memory amounts;
      amounts[underlyingIndex] = amount;
      if (shouldUseUnderlying) {
        ICurveSwap(depositAddress).add_liquidity(amounts, 0, true);
      } else {
        ICurveSwap(depositAddress).add_liquidity(amounts, 0);
      }
    } else {
      uint256[2] memory amounts;
      amounts[underlyingIndex] = amount;
      if (curveRegistry.isEthPool(depositAddress)) {
        if (entryToken != ETH_ADDRESS) {
          ICurveEthSwap(depositAddress).add_liquidity{value: 0}(amounts, 0);
        } else {
          ICurveEthSwap(depositAddress).add_liquidity{value: amount}(
            amounts,
            0
          );
        }
      } else {
        if (shouldUseUnderlying) {
          ICurveSwap(depositAddress).add_liquidity(amounts, 0, true);
        } else {
          ICurveSwap(depositAddress).add_liquidity(amounts, 0);
        }
      }
    }
    poolTokensReceived = _getBalance(tokenAddress) - initialBalance;
  }

  /**
    @notice This method removes the liquidity from curve pools
    @param poolAddress indicates Curve swap address for the pool
    @param liquidityAmount indicates the amount of lp tokens to remove
    @param exitTokenAddress indicates the ETH/ERC token to which tokens to convert
    @param minExitTokenAmount indicates the minimum amount of toTokens to receive
    @param / Underlying target which will execute swap
    @param targetWithdrawTokenAddress Token which will be used to withdraw funds from curve contract
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address to share fees
  */
  function withdraw(
    address poolAddress,
    uint256 liquidityAmount,
    address exitTokenAddress,
    uint256 minExitTokenAmount,
    address,
    address targetWithdrawTokenAddress,
    address swapTarget,
    bytes calldata swapData,
    address affiliate
  ) external payable override whenNotPaused {
    address poolTokenAddress = curveRegistry.getTokenAddress(poolAddress);
    // Transfer {liquidityTokens} to contract
    liquidityAmount = _pullTokens(poolTokenAddress, liquidityAmount);

    uint256 exitTokenAmount = _makeWithdrawal(
      poolAddress,
      liquidityAmount,
      targetWithdrawTokenAddress,
      exitTokenAddress,
      minExitTokenAmount,
      swapTarget,
      swapData
    );

    exitTokenAmount -= _subtractGoodwill(
      exitTokenAddress,
      exitTokenAmount,
      affiliate,
      true
    );

    if (exitTokenAddress == ETH_ADDRESS) {
      Address.sendValue(payable(msg.sender), exitTokenAmount);
    } else {
      IERC20(exitTokenAddress).safeTransfer(msg.sender, exitTokenAmount);
    }

    emit Withdraw(msg.sender, poolAddress, exitTokenAmount, affiliate);
  }

  function _makeWithdrawal(
    address poolAddress,
    uint256 entryTokenAmount,
    address curveExitTokenAddress,
    address exitTokenAddress,
    uint256 minExitTokenAmount,
    address swapTarget,
    bytes memory swapData
  ) internal returns (uint256 exitTokenAmount) {
    (bool isUnderlying, uint256 underlyingIndex) = curveRegistry
      .isUnderlyingToken(poolAddress, curveExitTokenAddress);

    // Not Metapool
    if (isUnderlying) {
      uint256 intermediateReceived = _exitCurve(
        poolAddress,
        entryTokenAmount,
        int128(uint128(underlyingIndex)),
        curveExitTokenAddress
      );

      exitTokenAmount = _fillQuote(
        curveExitTokenAddress,
        intermediateReceived,
        exitTokenAddress,
        swapTarget,
        swapData
      );
    } else {
      // Metapool
      address[8] memory poolTokens = curveRegistry.getPoolTokens(poolAddress);
      address intermediateSwapAddress;
      uint8 i;
      for (; i < 8; i++) {
        if (curveRegistry.getSwapAddress(poolTokens[i]) != address(0)) {
          intermediateSwapAddress = curveRegistry.getSwapAddress(poolTokens[i]);
          break;
        }
      }
      // _exitCurve to {intermediateToken}
      uint256 intermediateTokenBought = _exitMetaCurve(
        poolAddress,
        entryTokenAmount,
        i,
        poolTokens[i]
      );

      // Runs itself but now fromPool = {intermediateToken}
      exitTokenAmount = _makeWithdrawal(
        intermediateSwapAddress,
        intermediateTokenBought,
        curveExitTokenAddress,
        exitTokenAddress,
        minExitTokenAmount,
        swapTarget,
        swapData
      );
    }

    require(exitTokenAmount >= minExitTokenAmount, "High Slippage");
  }

  /*
   *@notice This method removes the liquidity from meta curve pools
   *@param poolAddress indicates the curve pool address from which liquidity to be removed.
   *@param entryTokenAmount indicates the amount of liquidity to be removed from the pool
   *@param underlyingIndex indicates the underlyingIndex of underlying token of the pool in which liquidity will be removed.
   *@return intermediateTokensBought - indicates the amount of reserve tokens received
   */
  function _exitMetaCurve(
    address poolAddress,
    uint256 entryTokenAmount,
    uint256 underlyingIndex,
    address exitTokenAddress
  ) internal returns (uint256 intermediateTokensBought) {
    address tokenAddress = curveRegistry.getTokenAddress(poolAddress);

    // _approveToken(tokenAddress, poolAddress, 0);
    _approveToken(tokenAddress, poolAddress);

    uint256 iniTokenBal = IERC20(exitTokenAddress).balanceOf(address(this));
    ICurveSwap(poolAddress).remove_liquidity_one_coin(
      entryTokenAmount,
      int128(uint128(underlyingIndex)),
      0
    );
    intermediateTokensBought =
      (IERC20(exitTokenAddress).balanceOf(address(this))) -
      iniTokenBal;

    require(intermediateTokensBought > 0, "Could not receive reserve tokens");
  }

  /*
   *@notice This method removes the liquidity from given curve pool
   *@param poolAddress indicates the curve pool address from which liquidity to be removed.
   *@param entryTokenAmount indicates the amount of liquidity to be removed from the pool
   *@param underlyingIndex indicates the underlyingIndex of underlying token of the pool in which liquidity will be removed.
   *@return intermediateTokensBought - indicates the amount of reserve tokens received
   */
  function _exitCurve(
    address poolAddress,
    uint256 entryTokenAmount,
    int128 underlyingIndex,
    address exitTokenAddress
  ) internal returns (uint256 intermediateTokensBought) {
    address depositAddress = curveRegistry.getDepositAddress(poolAddress);
    address tokenAddress = curveRegistry.getTokenAddress(poolAddress);

    _approveToken(tokenAddress, depositAddress);

    uint256 iniTokenBal = _getBalance(exitTokenAddress);

    if (curveRegistry.shouldUseUnderlying(poolAddress)) {
      // aave
      ICurveSwap(depositAddress).remove_liquidity_one_coin(
        entryTokenAmount,
        underlyingIndex,
        0,
        true
      );
    } else if (curveRegistry.isCryptoPool(poolAddress)) {
      ICurveSwap(depositAddress).remove_liquidity_one_coin(
        entryTokenAmount,
        uint256(uint128(underlyingIndex)),
        0
      );
    } else {
      ICurveSwap(depositAddress).remove_liquidity_one_coin(
        entryTokenAmount,
        int128(uint128(underlyingIndex)),
        0
      );
    }

    intermediateTokensBought = _getBalance(exitTokenAddress) - iniTokenBal;

    require(intermediateTokensBought > 0, "Could not receive reserve tokens");
  }

  /**
    @notice Utility function to determine the quantity and address of a token being removed
    @param poolAddress indicates the curve pool address from which liquidity to be removed
    @param tokenAddress token to be removed
    @param liquidity Quantity of LP tokens to remove.
    @return Quantity of token removed
    */
  function removeAssetReturn(
    address poolAddress,
    address tokenAddress,
    uint256 liquidity
  ) external view override returns (uint256) {
    require(liquidity > 0, "RAR: Zero amount return");

    if (tokenAddress == address(0)) tokenAddress = ETH_ADDRESS;
    (bool underlying, uint256 underlyingIndex) = curveRegistry
      .isUnderlyingToken(poolAddress, tokenAddress);

    if (underlying) {
      if (curveRegistry.isCryptoPool(poolAddress)) {
        return
          ICurveSwap(curveRegistry.getDepositAddress(poolAddress))
            .calc_withdraw_one_coin(liquidity, uint256(underlyingIndex));
      } else {
        return
          ICurveSwap(curveRegistry.getDepositAddress(poolAddress))
            .calc_withdraw_one_coin(
              liquidity,
              int128(uint128(underlyingIndex))
            );
      }
    } else {
      address[8] memory poolTokens = curveRegistry.getPoolTokens(poolAddress);
      address intermediateSwapAddress;
      for (uint256 i = 0; i < 8; i++) {
        intermediateSwapAddress = curveRegistry.getSwapAddress(poolTokens[i]);
        if (intermediateSwapAddress != address(0)) break;
      }
      uint256 metaTokensRec = ICurveSwap(poolAddress).calc_withdraw_one_coin(
        liquidity,
        int128(1)
      );

      (, underlyingIndex) = curveRegistry.isUnderlyingToken(
        intermediateSwapAddress,
        tokenAddress
      );

      return
        ICurveSwap(intermediateSwapAddress).calc_withdraw_one_coin(
          metaTokensRec,
          int128(uint128(underlyingIndex))
        );
    }
  }

  /// @notice Updates Current Curve Registry
  /// @param  newCurveRegistry new curve address
  function updateCurveRegistry(ICurveRegistry newCurveRegistry)
    external
    onlyOwner
  {
    require(newCurveRegistry != curveRegistry, "Already using this Registry");
    curveRegistry = newCurveRegistry;
  }
}
