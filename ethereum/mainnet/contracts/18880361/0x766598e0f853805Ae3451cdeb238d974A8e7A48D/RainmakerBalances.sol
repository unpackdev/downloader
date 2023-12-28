//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./console.sol";

// ERC20 contract interface
abstract contract Token {
  function balanceOf(address) public view virtual returns (uint);
}

contract RainmakerBalances {
  struct TokenBalance {
    address token;
    uint256 balance;
  }

  /* Fallback function, don't accept any ETH */
  // function() public payable {
  //   revert("RainmakerBalances does not accept payments");
  // }

  /*
    Check the token balance of a wallet in a token contract

    Returns the balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address 
      - returns 0 if the contract doesn't implement balanceOf
  */
  function tokenBalance(
    address user,
    address token
  ) public view returns (uint) {
    // check if token is actually a contract
    uint256 tokenCode;
    assembly {
      tokenCode := extcodesize(token)
    } // contract code size

    // is it a contract and does it implement balanceOf
    if (tokenCode > 0) {
      return Token(token).balanceOf(user);
    } else {
      return 0;
    }
  }

  /*
    Check the token balances of a wallet for multiple tokens.
    Pass 0x0 as a "token" address to get ETH balance.

    Based on https://github.com/wbobeirne/eth-balance-checker

    Possible error throws:
      - extremely large arrays for tokens (gas cost too high) 
  */

  function getBalances(
    address user,
    address[] calldata tokens
  ) external view returns (TokenBalance[] memory) {
    TokenBalance[] memory tokenBalances = new TokenBalance[](tokens.length);

    for (uint256 j = 0; j < tokens.length; j++) {
      uint256 balance = 0;
      if (tokens[j] != address(0x0)) {
        balance = tokenBalance(user, tokens[j]);
      } else {
        balance = user.balance; // ETH balance
      }

      tokenBalances[j] = TokenBalance(tokens[j], balance);
    }

    return tokenBalances;
  }
}
