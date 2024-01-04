/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   +@@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  -@@*     +@-  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    +@@-.#@#  =@%#.   :.     -@*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ +@#.-- .*%*. .#@@*@#  %@@%*#@@: .@@=-.         -%-   #%@:   +*-   =*@*   -@%=:
 * @@%   =##  +@@#-..%%:%.-@@=-@@+  ..   +@%  #@#*+@:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  +@*   #@#  +@@. -+@@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  =@=  :*@:=@@-:@+
 * -#%+@#-  :@#@@+%++@*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%+@#-   :*+**+=: %%++%*
 *
 * @title: Library 2981
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Library for EIP 2981
 * @custom:error-code R:1 Permille out of bounds
 * @custom:change-log Custom errors added above
 *
 * Include with 'using Lib2981 for Lib2981.Royalties;' -- unique per collection
 * Include with 'using Lib2981 for Lib2981.MappedRoyalties;' -- unique per token
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

library Lib2981c {

  struct Royalties {
    address receiver;
    uint16 permille;
  }

  event RoyaltiesSet(uint256 token, address recipient, uint16 value);
  event RoyaltiesSet(address recipient, uint16 value);

  error MaxSplaining(string reason);

  function setRoyalties(
    Royalties storage royalties
  , address receiver
  , uint16 permille
  ) internal {
    if (permille >= 1000 ||  permille == 0) {
      revert MaxSplaining({
        reason: "R:1"
      });
    }
    royalties.receiver = receiver;
    royalties.permille = permille;
    emit RoyaltiesSet(
           royalties.receiver
         , royalties.permille
         );
  }

  function revokeRoyalties(
    Royalties storage royalties
  ) internal {
    delete royalties.receiver;
    delete royalties.permille;
    emit RoyaltiesSet(
           royalties.receiver
         , royalties.permille
         );
  }

  function royaltyInfo(
    Royalties storage royalties
  , uint256 tokenId
  , uint256 salePrice
  ) internal
    view
    returns (
      address receiver
    , uint256 royaltyAmount
    ) {
    receiver = royalties.receiver;
    royaltyAmount = salePrice * royalties.permille / 1000;
  }
}
