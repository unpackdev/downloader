// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IPayoutEscrow.sol";
import "./IPayoutTreasury.sol";

contract PayoutTreasury is Ownable, IPayoutTreasury {
  using SafeERC20 for IERC20;
  using Address for address;

  address public PayoutEscrowAddress;
  address public usdcAddress;

  constructor (
    address _owner,
    address _PayoutEscrowAddress,
    address _usdcAddress
  ) {
    transferOwnership(_owner);
    PayoutEscrowAddress = _PayoutEscrowAddress;
    usdcAddress = _usdcAddress;
  }

  /**
   * @dev Update the PayoutEscrow address
   */
  function setPayoutEscrowAddress(address _PayoutEscrowAddress) external onlyOwner {
    PayoutEscrowAddress = _PayoutEscrowAddress;
    emit PayoutEscrowAddressChanged(_PayoutEscrowAddress);
  }

  /**
   * @dev Update the USDC token contract address
   */
  function setUsdcAddress(address _usdcAddress) external onlyOwner {
    usdcAddress = _usdcAddress;
    emit USDCAddressChanged(_usdcAddress);
  }

  /**
    * @dev Initiates USDC transfer to PayoutEscrow address and creates ClaimablePayout
    */
  function createAndTransferPayout(
    uint256 totalUsdcAmount,
    address payee,
    TokenToExchange[] memory tokensToExchange
  ) external override onlyOwner {
    uint totalUsdcExchangeAmount = 0;
    // add up over-allocated USDC that should be exchanged for non-USDC tokens
    for (uint i = 0; i < tokensToExchange.length; i++) {
      TokenToExchange memory tokenConfig = tokensToExchange[i];
      totalUsdcExchangeAmount += tokenConfig.usdcToExchange;
      require(IERC20(tokenConfig.tokenAddress).balanceOf(address(this)) >= tokenConfig.tokenAmount,
        "Insufficient token balance"
      );
    }
    require(totalUsdcAmount >= totalUsdcExchangeAmount, 'Exchange amount exceeds transfer amount');
    require(address(PayoutEscrowAddress).isContract(), "PayoutEscrowAddress is not a contract address");

    // transfer full balance in USDC to PayoutEscrow and record compliant payout
    IERC20(usdcAddress).safeTransfer(PayoutEscrowAddress, totalUsdcAmount);
    emit PayoutInitiated(payee, totalUsdcAmount);

    // transfer non-USDC tokens to PayoutEscrow
    for (uint i = 0; i < tokensToExchange.length; i++) {
      TokenToExchange memory tokenConfig = tokensToExchange[i];
      IERC20(tokenConfig.tokenAddress).safeTransfer(PayoutEscrowAddress, tokenConfig.tokenAmount);
    }
    emit TokensExchanged(payee, totalUsdcExchangeAmount);
    // transfer over-allocated USDC back to PayoutTreasury
    IPayoutEscrow payoutEscrow = IPayoutEscrow(PayoutEscrowAddress);
    payoutEscrow.refundStableAmount(totalUsdcExchangeAmount);
    emit PayoutReadyToClaim(payee, totalUsdcAmount);

    // initiate final payout from PayoutEscrow to payee
    ClaimablePayout memory payout = ClaimablePayout(payee, totalUsdcAmount, tokensToExchange);
    payoutEscrow.claimPayout(payout);
  }

  /**
  * @dev Withdraws excess liquidity from PayoutTreasury
  */
  function withdrawTokens(
    TokenToWithdraw[] calldata tokensToWithdraw,
    address _dest
  ) external override onlyOwner {
    for (uint i = 0; i < tokensToWithdraw.length; i++) {
      TokenToWithdraw calldata tokenConfig = tokensToWithdraw[i];
      IERC20(tokenConfig.tokenAddress).safeTransfer(_dest, tokenConfig.tokenAmount);
      emit TreasuryFundsWithdrawn(tokenConfig.tokenAddress, _dest, tokenConfig.tokenAmount);
    }
  }
}
