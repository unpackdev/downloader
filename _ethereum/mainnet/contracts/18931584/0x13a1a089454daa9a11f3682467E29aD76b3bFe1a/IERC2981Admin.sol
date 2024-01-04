/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   +@@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  -@@*     +@-  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    +@@-.#@#  =@%#.   :.     -@*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ +@#.-- .*%*. .#@@*@#  %@@%*#@@: .@@=-.         -%-   #%@:   +*-   =*@*   -@%=:
 * @@%   =##  +@@#-..%%:%.-@@=-@@+  ..   +@%  #@#*+@:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  +@*   #@#  +@@. -+@@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  =@=  :*@:=@@-:@+
 * -#%+@#-  :@#@@+%++@*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%+@#-   :*+**+=: %%++%*
 *
 * @title: EIP-2981: NFT Royalty Standard, admin extension
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: the ERC-165 identifier for this interface is unknown.
 * @custom:source https://eips.ethereum.org/EIPS/eip-2981
 * @custom:change-log MIT -> Apache-2.0
 *
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright and related rights waived via CC0.                               *
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

import "./IERC2981.sol";

interface IERC2981Admin is IERC2981 {

  /// @dev function (state storage) sets the royalty data for a token
  /// @param tokenId uint256 for the token
  /// @param receiver address for the royalty reciever for token
  /// @param permille uint16 for the permille of royalties 20 -> 2.0%
  function setRoyalties(
    uint256 tokenId
  , address receiver
  , uint16 permille
  ) external;

  /// @dev function (state storage) revokes the royalty data for a token
  /// @param tokenId uint256 for the token
  function revokeRoyalties(
    uint256 tokenId
  ) external;

  /// @dev function (state storage) sets the royalty data for a collection
  /// @param receiver address for the royalty reciever for token
  /// @param permille uint16 for the permille of royalties 20 -> 2.0%
  function setRoyalties(
    address receiver
  , uint16 permille
  ) external;

  /// @dev function (state storage) revokes the royalty data for a collection
  function revokeRoyalties()
    external;
}
