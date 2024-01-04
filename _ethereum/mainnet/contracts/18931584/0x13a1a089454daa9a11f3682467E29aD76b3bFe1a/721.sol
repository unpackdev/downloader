/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   +@@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  -@@*     +@-  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    +@@-.#@#  =@%#.   :.     -@*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ +@#.-- .*%*. .#@@*@#  %@@%*#@@: .@@=-.         -%-   #%@:   +*-   =*@*   -@%=:
 * @@%   =##  +@@#-..%%:%.-@@=-@@+  ..   +@%  #@#*+@:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  +@*   #@#  +@@. -+@@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  =@=  :*@:=@@-:@+
 * -#%+@#-  :@#@@+%++@*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%+@#-   :*+**+=: %%++%*
 *
 * @title: Library 721
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Library for EIP 721
 * @custom:error-code L:1 "non-existent tokenId" 
 * @custom:error-code L:2 "approval to current owner"
 * @custom:error-code L:3 "approve caller is not token owner nor approved for all"
 * @custom:error-code L:4 "approve to caller"
 * @custom:error-code L:5 "caller is not token owner nor approved"
 * @custom:error-code L:6 "transfer from incorrect owner"
 * @custom:error-code L:7 "transfer to the zero address"
 * @custom:error-code L:8 "mint to the zero address"
 * @custom:error-code L:9 "token already minted"
 * @custom:change-log Custom errors added above
 *
 * Include with 'using Lib721 for Lib721.Token;'
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

import "./Strings.sol";
import "./CountersV2.sol";

library Lib721 {

  using Strings for uint256;
  using CountersV2 for CountersV2.Counter;

  struct Token {
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
    string name;
    string symbol;
    string baseURI;
    CountersV2.Counter supply;
  }

  event NameSet(string name);
  event SymbolSet(string symbol);
  event NewBaseURI(string baseURI);

  error MaxSplaining(string reason);

  function getBalanceOf(
    Token storage token
  , address owner
  ) internal
    view
    returns (uint256) {
    return token.balances[owner];
  }

  function getOwnerOf(
    Token storage token
  , uint256 tokenId
  ) internal 
    view
    returns (address) {
    return token.owners[tokenId];
  }

  function setName(
    Token storage token
  , string memory newName
  ) internal {
    token.name = newName;
    emit NameSet(newName);
  }

  function getName(
   Token storage token
  ) internal
    view
    returns (string memory) {
    return token.name;
  }

  function setSymbol(
    Token storage token
  , string memory newSymbol
  ) internal {
    token.symbol = newSymbol;
    emit SymbolSet(newSymbol);
  }

  function getSymbol(
   Token storage token
  ) internal
    view
    returns (string memory) {
    return token.symbol;
  }

  function getSupply(
   Token storage token
  ) internal
    view
    returns (uint256) {
    return token.supply.current();
  }

  function setBaseURI(
    Token storage token
  , string memory newURI
  ) internal {
    token.baseURI = newURI;
    emit NewBaseURI(newURI);
  }

  function getTokenURI(
    Token storage token
  , uint256 tokenId
  ) internal
    view
    returns (string memory) {
    if (getOwnerOf(token, tokenId) == address(0)) {
      revert MaxSplaining({
        reason: "L:1"
      });
    }
    return bytes(token.baseURI).length > 0 ? string(abi.encodePacked(token.baseURI, tokenId.toString())) : "";
  }

  function setApprove(
    Token storage token
  , address to
  , address by
  , uint256 tokenId
  ) internal {
    address owner = getOwnerOf(token, tokenId);
    if (to == owner) {
      revert MaxSplaining({
        reason: "L:2"
      });
    } else if (!isApprovedOrOwner(token, by, tokenId)) {
      revert MaxSplaining({
        reason: "L:3"
      });
    }
    token.tokenApprovals[tokenId] = to;
  }

  function getApproved(
    Token storage token
  , uint256 tokenId
  ) internal
    view
    returns (address) {
    if (getOwnerOf(token, tokenId) == address(0)) {
      revert MaxSplaining({
        reason: "L:1"
      });
    }
    return token.tokenApprovals[tokenId];
  }

  function setApprovalForAll(
    Token storage token
  , address operator
  , address from
  , bool approved
  ) internal {
    if (from == operator) {
      revert MaxSplaining({
        reason: "L:4"
      });
    }
    token.operatorApprovals[from][operator] = approved;
  }

  function isApprovedForAll(
    Token storage token
  , address owner
  , address operator
  ) internal
    view
    returns (bool) {
    return token.operatorApprovals[owner][operator];
  }

  function isApprovedOrOwner(
    Token storage token
  , address spender
  , uint256 tokenId
  ) internal
    view
    returns (bool) {
    address owner = getOwnerOf(token, tokenId);
    return (
      spender == owner ||
      isApprovedForAll(token, owner, spender) ||
      getApproved(token, tokenId) == spender
    );
  }

  function doTransferFrom(
    Token storage token
  , address from
  , address to
  , address by
  , uint256 tokenId
  ) internal {
    if (!isApprovedOrOwner(token, by, tokenId)) {
      revert MaxSplaining({
        reason: "L:5"
      });
    }
    address owner = getOwnerOf(token, tokenId);
    if (owner != from) {
      revert MaxSplaining({
        reason: "L:6"
      });
    } else if (to == address(0)) {
      revert MaxSplaining({
        reason: "L:7"
      });
    }
    // Clear approvals from the previous owner
    setApprove(token, address(0), by, tokenId);
    // Change balances
    token.balances[from] -= 1;
    token.balances[to] += 1;
    // Move tokenId
    token.owners[tokenId] = to;
  }

  function mint(
    Token storage token
  , address to
  , uint256 tokenId
  ) internal {
    if (to == address(0)) {
      revert MaxSplaining({
        reason: "L:8"
      });
    } else if (getOwnerOf(token, tokenId) != address(0)) {
      revert MaxSplaining({
        reason: "L:9"
      });
    }
    token.balances[to] += 1;
    token.owners[tokenId] = to;
    token.supply.increment();
  }

  function burn(
    Token storage token
  , address by
  , uint256 tokenId
  ) internal {
    address owner = getOwnerOf(token, tokenId);
    // Clear approvals
    setApprove(token, address(0), by, tokenId);
    // Change balances
    token.balances[owner] -= 1;
    delete token.owners[tokenId];
    token.supply.decrement();
  }
}
