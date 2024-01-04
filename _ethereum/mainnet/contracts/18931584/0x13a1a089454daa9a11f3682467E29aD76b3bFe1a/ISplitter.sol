/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   +@@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  -@@*     +@-  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    +@@-.#@#  =@%#.   :.     -@*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ +@#.-- .*%*. .#@@*@#  %@@%*#@@: .@@=-.         -%-   #%@:   +*-   =*@*   -@%=:
 * @@%   =##  +@@#-..%%:%.-@@=-@@+  ..   +@%  #@#*+@:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  +@*   #@#  +@@. -+@@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  =@=  :*@:=@@-:@+
 * -#%+@#-  :@#@@+%++@*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%+@#-   :*+**+=: %%++%*
 *
 * @title: [Not an EIP] Payment Splitter, interface for ether payments
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Interface for Payment Splitter
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

import "./IERC165.sol";

interface ISplitter is IERC165 {

  /// @dev returns total shares
  /// @return uint256 of all shares on contract
  function totalShares()
    external
    view
    returns (uint256);

  /// @dev returns shares of an address
  /// @param payee address of payee to return
  /// @return mapping(address => uint) of _shares
  function shares(
    address payee
  ) external
    view
    returns (uint256);

  /// @dev returns total releases in "eth"
  /// @return uint256 of all "eth" released in wei
  function totalReleased()
    external
    view
    returns (uint256);

  /// @dev returns released "eth" of an payee
  /// @param payee address of payee to look up
  /// @return mapping(address => uint) of _released
  function released(
    address payee
  ) external
    view
    returns (uint256);

  /// @dev returns amount of "eth" that can be released to payee
  /// @param payee address of payee to look up
  /// @return uint in wei of "eth" to release
  function releasable(
    address payee
  ) external
    view
    returns (uint256);

  /// @dev returns index number of payee
  /// @param payee number of index
  /// @return address at _payees[index]
  function payeeIndex(
    address payee
  ) external
    view
    returns (uint256);

  /// @dev this returns the array of payees[]
  /// @return address[] payees
  function payees()
    external
    view
    returns (address[] memory);

  /// @dev this claims all "eth" on contract for msg.sender
  function claim()
    external;

  /// @dev This pays all payees
  function payClaims()
    external;

  /// @dev This adds a payee
  /// @param payee Address of payee
  /// @param _shares Shares to send user
  function addPayee(
    address payee
  , uint256 _shares
  ) external;

  /// @dev This removes a payee
  /// @param payee Address of payee to remove
  /// @dev use payPayees() prior to use if anything is on the contract
  function removePayee(
    address payee
  ) external;

  /// @dev This removes all payees
  /// @dev use payPayees() prior to use if anything is on the contract
  function clearPayees()
    external;
}

