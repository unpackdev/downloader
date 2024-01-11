// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.9;

import "./CoinStatsBaseV1.sol";
import "./IntegrationInterface.sol";

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}

interface ISavingsContractV2 {
  function depositSavings(uint256 _amount, address _beneficiary)
    external
    returns (uint256 creditsIssued); // V2

  function redeemCredits(uint256 _amount)
    external
    returns (uint256 underlyingReturned); // V2

  function creditsToUnderlying(uint256 _underlying)
    external
    view
    returns (uint256 credits); // V2
}

contract MStableIntegration is IntegrationInterface, CoinStatsBaseV1 {
  using SafeERC20 for IERC20;

  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

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

  constructor(
    uint256 _goodwill,
    uint256 _affiliateSplit,
    address _vaultAddress
  ) CoinStatsBaseV1(_goodwill, _affiliateSplit, _vaultAddress) {
    // 0x exchange
    approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    // 1inch exchange
    approvedTargets[0x1111111254fb6c44bAC0beD2854e76F90643097d] = true;
  }

  /**
    @notice Returns pools total supply
    @param savingsContractAddress MStable savings contract address from which to get supply
   */
  function getTotalSupply(address savingsContractAddress)
    public
    view
    returns (uint256)
  {
    return IERC20(savingsContractAddress).totalSupply();
  }

  /**
    @notice Returns account balance from pool
    @param savingsContractAddress MStable savings contract address from which to get balance
    @param account The account
   */
  function getBalance(address savingsContractAddress, address account)
    public
    view
    override
    returns (uint256)
  {
    return IERC20(savingsContractAddress).balanceOf(account);
  }

  /**
    @notice Adds liquidity to any mstable savings contracts with ETH or ERC20 tokens
    @param entryTokenAddress The token used for entry (address(0) if ETH).
    @param entryTokenAmount The depositTokenAmount of entryTokenAddress to invest
    @param savingsContractAddress mstable savings contract address
    @param depositTokenAddress Token to be transfered to poolAddress
    @param minExitTokenAmount Min acceptable amount of liquidity/stake tokens to reeive
    @param swapTarget Underlying target's swap target
    @param swapData Data for swap
    @param affiliate Affiliate address 
  */
  function deposit(
    address entryTokenAddress,
    uint256 entryTokenAmount,
    address savingsContractAddress,
    address depositTokenAddress,
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
    entryTokenAmount =
      entryTokenAmount -
      _subtractGoodwill(entryTokenAddress, entryTokenAmount, affiliate, true);

    if (entryTokenAddress == address(0)) {
      entryTokenAddress = ETH_ADDRESS;
    }

    // Swap {entryToken} to {depositToken}
    uint256 depositTokenAmount = _fillQuote(
      entryTokenAddress,
      entryTokenAmount,
      depositTokenAddress,
      swapTarget,
      swapData
    );

    _deposit(
      depositTokenAddress,
      depositTokenAmount,
      savingsContractAddress,
      minExitTokenAmount
    );

    emit Deposit(
      msg.sender,
      savingsContractAddress,
      depositTokenAmount,
      affiliate
    );
  }

  function _deposit(
    address depositTokenAddress,
    uint256 depositTokenAmount,
    address savingContract,
    uint256 minExitTokenAmount
  ) internal {
    _approveToken(depositTokenAddress, savingContract);

    uint256 imTokensReceived = ISavingsContractV2(savingContract)
      .depositSavings(depositTokenAmount, msg.sender);

    require(
      imTokensReceived >= minExitTokenAmount,
      "DepositSavings: High Slippage"
    );
  }

  /**
    @notice Removes liquidity from Yarn vaults in ETH or ERC20 tokens
    @param savingsContractAddress MStable savings address
    @param savingsTokenAmount Token amount to be transferes to integration contract
    @param exitTokenAddress Specifies the token which will be send to caller
    @param minExitTokenAmount Min acceptable amount of tokens to reeive
    @param targetWithdrawTokenAddress Token which will be used to withdraw funds in target contract
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address to share fees
  */
  function withdraw(
    address savingsContractAddress,
    uint256 savingsTokenAmount,
    address exitTokenAddress,
    uint256 minExitTokenAmount,
    address,
    address targetWithdrawTokenAddress,
    address swapTarget,
    bytes calldata swapData,
    address affiliate
  ) external payable override whenNotPaused {
    savingsTokenAmount = _pullTokens(
      savingsContractAddress,
      savingsTokenAmount
    );

    uint256 underlyingTokenReceived = ISavingsContractV2(savingsContractAddress)
      .redeemCredits(savingsTokenAmount);

    uint256 exitTokenAmount = _fillQuote(
      targetWithdrawTokenAddress,
      underlyingTokenReceived,
      exitTokenAddress,
      swapTarget,
      swapData
    );

    require(exitTokenAmount >= minExitTokenAmount, "Withdraw: High Slippage");

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

    emit Withdraw(
      msg.sender,
      savingsContractAddress,
      exitTokenAmount,
      affiliate
    );
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
    @notice Utility function to determine the quantity of underlying tokens removed from vault
    @param savingsContract savings contract from which to remove liquidity
    @param liquidity Quantity of vault tokens to remove
    @return Quantity of underlying LP or token removed
  */
  function removeAssetReturn(
    address savingsContract,
    address,
    uint256 liquidity
  ) external view override returns (uint256) {
    return ISavingsContractV2(savingsContract).creditsToUnderlying(liquidity);
  }
}
