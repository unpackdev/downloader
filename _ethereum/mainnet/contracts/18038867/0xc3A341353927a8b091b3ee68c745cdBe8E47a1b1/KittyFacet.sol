// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./EnumerableSet.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./LibDiamond.sol";
import "./LibKitty.sol";
import "./Errors.sol";
import "./IKitty.sol";

contract KittyFacet is IKitty {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  error InsufficientOwnerBalance(uint256 available);

  function partnerTokens(address partner) external view returns (address[] memory tokens_) {
    LibKitty.State storage s = LibKitty.state();

    EnumerableSet.AddressSet storage tokenSet = s.partnerTokens[partner];
    uint256 length = tokenSet.length();

    tokens_ = new address[](length);

    for (uint256 tokenIndex; tokenIndex < length; tokenIndex++) {
      tokens_[tokenIndex] = tokenSet.at(tokenIndex);
    }
  }

  function partnerTokenBalance(address partner, address token) external view returns (uint256) {
    LibKitty.State storage s = LibKitty.state();

    return s.partnerBalances[partner][token];
  }

  function partnerWithdraw(address token) external {
    LibKitty.State storage s = LibKitty.state();

    uint256 balance = s.partnerBalances[msg.sender][token];

    if (balance > 0) {
      s.partnerBalances[msg.sender][token] = 0;
      s.partnerBalancesTotal[token] -= balance;

      emit PartnerWithdraw(msg.sender, token, balance);

      if (token == address(0)) {
        // NOTE: Control transfered to untrusted address
        (bool sent, ) = payable(msg.sender).call{value: balance}('');

        if (!sent) {
          revert Errors.EthTransferFailed();
        }
      } else {
        // NOTE: The token is not removed from the partner's token set
        IERC20(token).safeTransfer(msg.sender, balance);
      }
    }
  }

  function ownerWithdraw(address token, uint256 amount, address payable to) external {
    LibDiamond.enforceIsContractOwner();

    LibKitty.State storage s = LibKitty.state();

    uint256 partnerBalanceTotal = s.partnerBalancesTotal[token];

    uint256 balance = token == address(0)
      ? address(this).balance
      : IERC20(token).balanceOf(address(this));

    uint256 available = balance - partnerBalanceTotal;

    if (amount > available) {
      revert InsufficientOwnerBalance(available);
    }

    if (token == address(0)) {
      // Send ETH
      (bool sent, ) = to.call{value: amount}('');

      if (!sent) {
        revert Errors.EthTransferFailed();
      }
    } else {
      IERC20(token).safeTransfer(to, amount);
    }
  }
}
