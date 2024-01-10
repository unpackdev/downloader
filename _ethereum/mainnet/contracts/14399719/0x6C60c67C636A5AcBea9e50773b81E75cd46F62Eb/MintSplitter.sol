// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
        ████████████
      ██            ██
    ██              ██
    ██              ██▓▓
    ██            ████▓▓▓▓▓▓
    ██      ██████▓▓▒▒▓▓▓▓▓▓▓▓
    ████████▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒
    ██    ████████▓▓▒▒▒▒▒▒▒▒▒▒
    ██            ██▓▓▒▒▒▒▒▒▒▒
    ██              ██▓▓▓▓▓▓▓▓
    ██    ██      ██  ██████
      ██              ██        '||''|.                    ||           '||
      ██              ██         ||   ||  ... ..   ....   ...  .. ...    || ...    ...   ... ... ...
      ██              ██         ||'''|.   ||' '' '' .||   ||   ||  ||   ||'  || .|  '|.  ||  ||  |
        ██          ██           ||    ||  ||     .|' ||   ||   ||  ||   ||    | ||   ||   ||| |||
          ██████████            .||...|'  .||.    '|..'|' .||. .||. ||.  '|...'   '|..|'    |   |

*/

import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract MintSplitter is PaymentSplitter, Ownable {
  address[] private _payees;

  IERC20 immutable weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  constructor(address[] memory payees, uint256[] memory shares_) PaymentSplitter(payees, shares_) {
    _payees = payees;
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

    for (uint256 i = 0; i < length; i++) {
      address payable payee = payable(_payees[i]);
      release(payable(payee));
      release(weth, payable(payee));
    }
  }
}

