/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   +@@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  -@@*     +@-  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    +@@-.#@#  =@%#.   :.     -@*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ +@#.-- .*%*. .#@@*@#  %@@%*#@@: .@@=-.         -%-   #%@:   +*-   =*@*   -@%=:
 * @@%   =##  +@@#-..%%:%.-@@=-@@+  ..   +@%  #@#*+@:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  +@*   #@#  +@@. -+@@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  =@=  :*@:=@@-:@+
 * -#%+@#-  :@#@@+%++@*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%+@#-   :*+**+=: %%++%*
 *
 * @title: [EIP721] HOW NFT
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice ERC721 Implementation with:
 *         Enhanced EIP173 - Ownership via roles
 *         EIP2981 - NFT Royalties
 *         PaymentSplitter v2 - For "ETH" payments
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

pragma solidity >=0.8.17 <0.9.0;

import "./Max-721-2981-PSv2.sol";
import "./721.sol";
import "./Lists.sol";
import "./CountersV2.sol";
import "./MerkleProof.sol";
import "./Base64.sol";

contract HOW is Max721 {

  using Lib721 for Lib721.Token;
  using Lists for Lists.Access;
  using CountersV2 for CountersV2.Counter;

  CountersV2.Counter internal theTokenID;

  event Claimed(uint256 index, address account, uint256 amount, string what);

  constructor(
    string memory _name
  , string memory _symbol
  , address _admin
  , address _dev
  , address _owner
  , uint256 _start
  ) {
      __Max721_init(_name, _symbol, _admin, _dev, _owner);
      theTokenID.set(_start);
  }

  // set time block
  modifier preSale() {
    if (block.timestamp < startTime + period && block.timestamp >= startTime) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  modifier Sale() {
    if (block.timestamp >= startTime + period) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  function setTime(
    uint256 _start
  , uint256 _period
  ) external
    onlyDev() {
    startTime = _start;
    period = _period;
  }

  function showTimes()
    external
    view
    returns (uint256, uint256) {
    return (startTime, startTime + period);
  }

  function setCap(
    uint256 _amount
  ) external
    onlyDev() {
    maxCap = _amount;
  }

  function setMerks(
    bytes32 _admin
  , bytes32 _homies
  , bytes32 _normies
  ) external
    onlyDev() {
    admin = _admin;
    homies = _homies;
    normies = _normies;
  }

  function isClaimedAdmin(
    uint256 index
  ) public
    view
    returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedAdmin[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function isClaimedHomies(
    uint256 index
  ) public
    view
    returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedHomies[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function isClaimedNormies(
    uint256 index
  ) public
    view
    returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedNormies[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function _setClaimedAdmin(
    uint256 index
  ) internal {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedAdmin[claimedWordIndex] = claimedAdmin[claimedWordIndex] | (1 << claimedBitIndex);
  }

  function _setClaimedHomies(
    uint256 index
  ) internal {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedHomies[claimedWordIndex] = claimedHomies[claimedWordIndex] | (1 << claimedBitIndex);
  }

  function _setClaimedNormies(
    uint256 index
  ) internal {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedNormies[claimedWordIndex] = claimedNormies[claimedWordIndex] | (1 << claimedBitIndex);
  }

  function adminMint(
    uint256 index
  , address account
  , uint256 amount
  , bytes32[] calldata merkleProof
  ) external
    preSale() {
    if (startTime == 0) {
      revert Unauthorized();
    }
    if (isClaimedAdmin(index)) {
      revert MaxSplaining({
        reason: "Already Claimed"
      });
    }

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    if (!MerkleProof.verify(merkleProof, admin, node)) {
      revert MaxSplaining({
        reason: "Invalid Proof"
      });
    }

    // Mark it claimed and send the token.
    _setClaimedAdmin(index);
    if (token721.getSupply() + amount > maxCap) {
      revert Unauthorized();
    } else {
      for (uint c = 0; c < amount;) {
        // mint each
        token721.mint(account, theTokenID.current());
        emit Transfer(address(0), account, theTokenID.current());
        theTokenID.increment();
        unchecked { ++c; }
      }
    }
    emit Claimed(index, account, amount, "Admin");
  }

  function homiesMint(
    uint256 index
  , address account
  , bytes32[] calldata merkleProof
  ) external
    preSale() {
    if (startTime == 0) {
      revert Unauthorized();
    }
    if (isClaimedHomies(index)) {
      revert MaxSplaining({
        reason: "Already Claimed"
      });
    }

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account));
    if (!MerkleProof.verify(merkleProof, homies, node)) {
      revert MaxSplaining({
        reason: "Invalid Proof"
      });
    }

    // Mark it claimed and send the token.
    _setClaimedHomies(index);
    if (token721.getSupply() + 1 > maxCap) {
      revert Unauthorized();
    } else {
      token721.mint(account, theTokenID.current());
      emit Transfer(address(0), account, theTokenID.current());
      theTokenID.increment();
    }
    emit Claimed(index, account, 1, "Homies");
  }

  function normiesMint(
    uint256 index
  , address account
  , bytes32[] calldata merkleProof
  ) external
    payable
    preSale() {
    if (startTime == 0) {
      revert Unauthorized();
    }
    if (msg.value != normiesCost) {
      revert MaxSplaining ({
        reason: "msg.value too low"
      });
    }
    if (isClaimedNormies(index)) {
      revert MaxSplaining({
        reason: "Already Claimed"
      });
    }

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account));
    if (!MerkleProof.verify(merkleProof, normies, node)) {
      revert MaxSplaining({
        reason: "Invalid Proof"
      });
    }

    // Mark it claimed and send the token.
    _setClaimedNormies(index);
    if (token721.getSupply() + 1 > maxCap) {
      revert Unauthorized();
    } else {
      token721.mint(account, theTokenID.current());
      emit Transfer(address(0), account, theTokenID.current());
      theTokenID.increment();
    }
    emit Claimed(index, account, 1, "Normies");
  }

  function publicMint(
    uint256 quant
  ) external
    payable
    Sale() {
    if (quant > 5) {
      revert Unauthorized();
    }
    if (startTime == 0) {
      revert Unauthorized();
    }
    if (msg.value != publicCost * quant) {
      revert MaxSplaining ({
        reason: "msg.value too low"
      });
    }
    if (token721.getSupply() + quant > maxCap) {
      revert Unauthorized();
    } else {
      for (uint c = 0; c < quant;) {
        // mint each
        token721.mint(msg.sender, theTokenID.current());
        emit Transfer(address(0), msg.sender, theTokenID.current());
        theTokenID.increment();
        unchecked { ++c; }
      }
    }
  }

  function setFees(
    uint256 _normies
  , uint256 _public
  ) external
    onlyDev() {
    normiesCost = _normies;
    publicCost = _public;
  }

  function setContractURI(
    string memory newURI
  ) external
    onlyDev() {
    contractURL = newURI;
  }

  function contractURI()
    public
    view
    returns (string memory) {
    return contractURL;
  }

  function setJSON(
    string memory _description
  , string memory _image
  , string memory _animation
  ) external
    onlyDev() {
    description = _description;
    image = _image;
    animationURI = _animation;
  }

  function tokenURI(
    uint256 tokenId
  ) public
    view
    virtual
    override
    returns (string memory) {
    bytes memory json = abi.encodePacked(
      "{",
      '"name": "Homies Genesis #',
      Strings.toString(uint256(tokenId)),
      '",',
      '"description": "',
      description,
      '",',
      '"image": "',
      image,
      '",',
      '"animation_url": "',
      animationURI,
      '"',
      "}"
    );

    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(json)
      )
    );
  }

  /// @dev Function to receive ether, msg.data must be empty
  receive()
    external
    payable {
    // From PaymentSplitter.sol
    emit PaymentReceived(msg.sender, msg.value);
  }

  /// @dev Function to receive ether, msg.data is not empty
  fallback()
    external
    payable {
    // From PaymentSplitter.sol
    emit PaymentReceived(msg.sender, msg.value);
  }

  /// @dev this is a public getter for ETH blance on contract
  function getBalance()
    external
    view
    returns (uint) {
    return address(this).balance;
  }
}
