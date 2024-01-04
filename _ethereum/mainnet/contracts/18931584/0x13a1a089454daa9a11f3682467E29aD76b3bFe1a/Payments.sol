/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   +@@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  -@@*     +@-  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    +@@-.#@#  =@%#.   :.     -@*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ +@#.-- .*%*. .#@@*@#  %@@%*#@@: .@@=-.         -%-   #%@:   +*-   =*@*   -@%=:
 * @@%   =##  +@@#-..%%:%.-@@=-@@+  ..   +@%  #@#*+@:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  +@*   #@#  +@@. -+@@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  =@=  :*@:=@@-:@+
 * -#%+@#-  :@#@@+%++@*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%+@#-   :*+**+=: %%++%*
 *
 * @title: [Not an EIP] Payment Splitter
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Library for two structs one with "ERC-20's" and one without
 * @custom:error-code PS:1 No Shares for address
 * @custom:error-code PS:2 No payment due for address
 * @custom:error-code PS:3 Can not use address(0)
 * @custom:error-code PS:4 Shares can not be 0
 * @custom:error-code PS:5 User has shares already
 * @custom:error-code PS:6 User not in payees
 * @custom:change-log added custom error-codes above
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

library Payments {

  struct GasTokens {
    uint256 totalShares;
    uint256 totalReleased;
    mapping(address => uint256) shares;
    mapping(address => uint256) released;
    address[] payees;
  }

  event PayeeAdded(address account, uint256 _shares);
  event PayeeRemoved(address account, uint256 _shares);
  event PayeesReset();
  event PaymentReleased(address to, uint256 amount);

  error MaxSplaining(string reason);

  function findIndex(
    address[] memory array
  , address query
  ) internal
    pure
    returns (bool found, uint256 index) {
    uint256 len = array.length;
    for (uint x = 0; x < len;) {
      if (array[x] == query) {
        found = true;
        index = x;
      }
      unchecked { ++x; }
    }
  }

  function getTotalReleased(
    GasTokens storage gasTokens
  ) internal
    view
    returns (uint256) {
    return gasTokens.totalReleased;
  }

  function getTotalShares(
    GasTokens storage gasTokens
  ) internal
    view
    returns (uint256) {
    return gasTokens.totalShares;
  }

  function payeeShares(
    GasTokens storage gasTokens
  , address payee
  ) internal
    view
    returns (uint256) {
    return gasTokens.shares[payee];
  }

  function payeeReleased(
    GasTokens storage gasTokens
  , address payee
  ) internal
    view
    returns (uint256) {
    return gasTokens.released[payee];
  }

  function payeeIndex(
    GasTokens storage gasTokens
  , address payee
  ) internal
    view
    returns (uint256) {
    (bool found, uint256 index) = findIndex(gasTokens.payees, payee);
    if (found) {
      return index;
    } else {
      revert MaxSplaining({
        reason: "PS:6"
      });
    }
  }

  function allPayees(
    GasTokens storage gasTokens
  ) internal
    view
    returns (address[] memory) {
    return gasTokens.payees;
  }

  function addPayee(
    GasTokens storage gasTokens
  , address payee
  , uint256 _shares
  ) internal {
    if (payee == address(0)) {
      revert MaxSplaining({
        reason: "PS:3"
      });
    } else if (_shares == 0) {
      revert MaxSplaining({
        reason: "PS:4"
      });
    } else if (gasTokens.shares[payee] > 0) {
      revert MaxSplaining({
        reason: "PS:5"
      });
    }
    gasTokens.payees.push(payee);
    gasTokens.shares[payee] = _shares;
    gasTokens.totalShares += _shares;
    emit PayeeAdded(payee, _shares);
  }

  function getPayees(
    GasTokens storage gasTokens
  ) internal
    view
    returns (address[] memory) {
    return gasTokens.payees;
  }

  function removePayee(
    GasTokens storage gasTokens
  , address payee
  ) internal {
    if (payee == address(0)) {
      revert MaxSplaining({
        reason: "PS:3"
      });
    }
    uint256 whacked = payeeIndex(gasTokens, payee);
    address last = gasTokens.payees[gasTokens.payees.length -1];
    gasTokens.payees[whacked] = last;
    gasTokens.payees.pop();
    uint256 whackedShares = gasTokens.shares[payee];
    delete gasTokens.shares[payee];
    gasTokens.totalShares -= whackedShares;
    emit PayeeRemoved(payee, whackedShares);
  }

  function clearPayees(
    GasTokens storage gasTokens
  ) internal {
    uint256 len = gasTokens.payees.length;
    for (uint x = 0; x < len;) {
      address whacked = gasTokens.payees[x];
      delete gasTokens.shares[whacked];
      unchecked { ++x; }
    }
    delete gasTokens.totalShares;
    delete gasTokens.payees;
    emit PayeesReset();
  }

  function processPayment(
    GasTokens storage gasTokens
  , address payee
  , uint256 payment
  ) internal {
    gasTokens.totalReleased += payment;
    gasTokens.released[payee] += payment;
    emit PaymentReleased(payee, payment);
  }
}
