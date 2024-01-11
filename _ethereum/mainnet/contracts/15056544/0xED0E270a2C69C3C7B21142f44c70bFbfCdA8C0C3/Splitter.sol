// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

        ████████████
      ██            ██
    ██              ██▓▓
    ██            ████▓▓▓▓▓▓
    ██      ██████▓▓▒▒▓▓▓▓▓▓▓▓
    ████████▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒
    ██    ████████▓▓▒▒▒▒▒▒▒▒▒▒
    ██            ██▓▓▒▒▒▒▒▒▒▒
    ██              ██▓▓▓▓▓▓▓▓
    ██    ██      ██    ██       '||''|.                    ||           '||
    ██                  ██        ||   ||  ... ..   ....   ...  .. ...    || ...    ...   ... ... ...
      ██              ██          ||'''|.   ||' '' '' .||   ||   ||  ||   ||'  || .|  '|.  ||  ||  |
        ██          ██            ||    ||  ||     .|' ||   ||   ||  ||   ||    | ||   ||   ||| |||
          ██████████             .||...|'  .||.    '|..'|' .||. .||. ||.  '|...'   '|..|'    |   |

*/

import "./PaymentSplitter.sol";
import "./Ownable.sol";

/**
 * @dev An opinionated implementation of a general purpose PaymentSplitter.
 * Rather than letting each payee pull their funds on their own, a few convenience functions
 * let the owner flush all funds, Ether and Wrapped Ether, in one transaction.
 */
contract Splitter is PaymentSplitter, Ownable {
  address[] private _payees;

  IERC20 weth;

  constructor(
    address[] memory payees,
    uint256[] memory _shares,
    address _wethAddr
  ) PaymentSplitter(payees, _shares) {
    _payees = payees;
    weth = IERC20(_wethAddr);
  }

  function flush() public onlyOwner {
    uint256 length = _payees.length;

    for (uint256 i = 0; i < length; i++) {
      address payee = _payees[i];
      release(payable(payee));
    }
  }

  function flushToken(IERC20 token) public onlyOwner {
    uint256 length = _payees.length;

    for (uint256 i = 0; i < length; i++) {
      address payee = _payees[i];
      release(token, payable(payee));
    }
  }

  function flushCommon() public onlyOwner {
    uint256 length = _payees.length;
    bool hasWeth = weth.balanceOf(address(this)) > 0;

    for (uint256 i = 0; i < length; i++) {
      address payable payee = payable(_payees[i]);
      release(payable(payee));
      if (hasWeth) release(weth, payable(payee));
    }
  }
}
