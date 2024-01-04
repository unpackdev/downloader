/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   +@@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  -@@*     +@-  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    +@@-.#@#  =@%#.   :.     -@*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ +@#.-- .*%*. .#@@*@#  %@@%*#@@: .@@=-.         -%-   #%@:   +*-   =*@*   -@%=:
 * @@%   =##  +@@#-..%%:%.-@@=-@@+  ..   +@%  #@#*+@:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  +@*   #@#  +@@. -+@@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  =@=  :*@:=@@-:@+
 * -#%+@#-  :@#@@+%++@*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%+@#-   :*+**+=: %%++%*
 *
 * @title: [EIP721] Max-721 Implementation, using EIP 1822
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice ERC721 Implementation with:
 *         Enhanced EIP173 - Ownership via roles
 *         EIP2981 - NFT Royalties
 *         PsuedoRandom Engine - Expansion of BAYC engine
 *         TimeCop + Lists - For presales
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

import "./IERC721TokenReceiver.sol";//
import "./IERC721Metadata.sol";//
import "./IERC721.sol";//
import "./IERC2981Admin.sol";//
import "./MaxAccess.sol";//
import "./ISplitter.sol";//
import "./Address.sol";//
import "./721.sol";//
import "./Roles.sol";//
import "./2981c.sol";//
import "./Payments.sol";//

abstract contract Max721 is MaxAccess
                          , IERC721
                          , IERC721Metadata
                          , IERC721TokenReceiver
                          , IERC2981Admin
                          , ISplitter {

  using Lib721 for Lib721.Token;
  using Roles for Roles.Role;
  using Lib2981c for Lib2981c.Royalties;
  using Payments for Payments.GasTokens;
  using Address for address;

  // The Structs...
  Lib721.Token internal token721;
  Roles.Role internal contractRoles;
  Lib2981c.Royalties internal royalties;
  Payments.GasTokens internal splitter;

  // The rest (got to have a few)
  bytes4 constant internal DEVS = 0xca4b208b;
  bytes4 constant internal PENDING_DEVS = 0xca4b208a; // DEVS - 1
  bytes4 constant internal OWNERS = 0x8da5cb5b;
  bytes4 constant internal PENDING_OWNERS = 0x8da5cb5a; // OWNERS - 1
  bytes4 constant internal ADMIN = 0xf851a440;

  uint256 startTime; // Set to opening (can +48h for secondary)
  uint256 period; // Set to the period
  uint256 maxCap; // Cpacity of minter
  bytes32 internal admin;
  mapping(uint256 => uint256) internal claimedAdmin;
  bytes32 internal homies;
  mapping(uint256 => uint256) internal claimedHomies;
  bytes32 internal normies;
  mapping(uint256 => uint256) internal claimedNormies;
  string internal contractURL;
  string internal image;
  string internal description;
  string internal animationURI;
  uint256 public normiesCost = 0.069 ether;
  uint256 public publicCost = 0.1 ether;

  event PaymentReceived(address indexed _payee, uint256 _amount);

  /// @dev this is Unauthorized(), basically a catch all, zero description
  /// @notice 0x82b42900 bytes4 of this
  error Unauthorized();

  /// @dev this is MaxSplaining(), giving you a reason, aka require(param, "reason")
  /// @param reason: Use the "Contract name: error"
  /// @notice 0x0661b792 bytes4 of this
  error MaxSplaining(
    string reason
  );

  /// @dev this is TooSoonJunior(), using times
  /// @param yourTime: should almost always be block.timestamp
  /// @param hitTime: the time you should have started
  /// @notice 0xf3f82ac5 bytes4 of this
  error TooSoonJunior(
    uint yourTime
  , uint hitTime
  );

  /// @dev this is TooLateBoomer(), using times
  /// @param yourTime: should almost always be block.timestamp
  /// @param hitTime: the time you should have ended
  /// @notice 0x43c540ef bytes4 of this
  error TooLateBoomer(
    uint yourTime
  , uint hitTime
  );

  ///////////////////////
  /// MAX-721: Modifiers
  ///////////////////////

  modifier onlyRole(bytes4 role) {
    if (contractRoles.has(role, msg.sender) || contractRoles.has(ADMIN, msg.sender)) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  modifier onlyOwner() {
    if (contractRoles.has(OWNERS, msg.sender)) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  modifier onlyDev() {
    if (contractRoles.has(DEVS, msg.sender)) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  ///////////////////////
  /// MAX-721: Internals
  ///////////////////////

  function __Max721_init(
    string memory _name
  , string memory _symbol
  , address _admin
  , address _dev
  , address _owner
  ) internal {
    token721.setName(_name);
    token721.setSymbol(_symbol);
    contractRoles.add(ADMIN, _admin);
    contractRoles.setAdmin(_admin);
    contractRoles.add(DEVS, _dev);
    contractRoles.setDeveloper(_dev);
    contractRoles.add(OWNERS, _owner);
    contractRoles.setOwner(_owner);
  }

  function safeHook(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal
    returns (bool) {
    if (to.isContract()) {
      try IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data)
        returns (bytes4 retval) {
        return retval == IERC721TokenReceiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert Unauthorized();
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /////////////////////////////////////////
  /// EIP-173: Contract Ownership Standard
  /////////////////////////////////////////

  /// @notice Get the address of the owner    
  /// @return The address of the owner.
  function owner()
    view
    external
    returns(address) {
    return contractRoles.getOwner();
  }
	
  /// @notice Set the address of the new owner of the contract
  /// @dev Set _newOwner to address(0) to renounce any ownership.
  /// @param _newOwner The address of the new owner of the contract    
  function transferOwnership(
    address _newOwner
  ) external
    onlyRole(OWNERS) {
    contractRoles.add(OWNERS, _newOwner);
    contractRoles.setOwner(_newOwner);
    contractRoles.remove(OWNERS, msg.sender);
  }

  ////////////////////////////////////////////////////////////////
  /// EIP-173: Contract Ownership Standard, MaxFlowO2's extension
  ////////////////////////////////////////////////////////////////

  /// @dev This is the classic "EIP-173" method of renouncing onlyOwner()  
  function renounceOwnership()
    external 
    onlyRole(OWNERS) {
    contractRoles.setOwner(address(0));
    contractRoles.remove(OWNERS, msg.sender);
  }

  /// @dev This accepts the push-pull method of onlyOwner()
  function acceptOwnership()
    external
    onlyRole(PENDING_OWNERS) {
    contractRoles.add(OWNERS, msg.sender);
    contractRoles.setOwner(msg.sender);
    contractRoles.remove(PENDING_OWNERS, msg.sender);
  }

  /// @dev This declines the push-pull method of onlyOwner()
  function declineOwnership()
    external
    onlyRole(PENDING_OWNERS) {
    contractRoles.remove(PENDING_OWNERS, msg.sender);
  }

  /// @dev This starts the push-pull method of onlyOwner()
  /// @param newOwner: addres of new pending owner role
  function pushOwnership(
    address newOwner
  ) external
    onlyRole(OWNERS) {
    contractRoles.add(PENDING_OWNERS, newOwner);
  }

  //////////////////////////////////////////////
  /// [Not an EIP]: Contract Developer Standard
  //////////////////////////////////////////////

  /// @dev Classic "EIP-173" but for onlyDev()
  /// @return Developer of contract
  function developer()
    external
    view
    returns (address) {
    return contractRoles.getDeveloper();
  }

  /// @dev This renounces your role as onlyDev()
  function renounceDeveloper()
    external
    onlyRole(DEVS) {
    contractRoles.setDeveloper(address(0));
    contractRoles.remove(DEVS, msg.sender);
  }

  /// @dev Classic "EIP-173" but for onlyDev()
  /// @param newDeveloper: addres of new pending Developer role
  function transferDeveloper(
    address newDeveloper
  ) external
    onlyRole(DEVS) {
    contractRoles.add(DEVS, newDeveloper);
    contractRoles.setDeveloper(newDeveloper);
    contractRoles.remove(DEVS, msg.sender);
  }

  /// @dev This accepts the push-pull method of onlyDev()
  function acceptDeveloper()
    external
    onlyRole(PENDING_DEVS) {
    contractRoles.add(DEVS, msg.sender);
    contractRoles.setDeveloper(msg.sender);
    contractRoles.remove(PENDING_DEVS, msg.sender);
  }

  /// @dev This declines the push-pull method of onlyDev()
  function declineDeveloper()
    external
    onlyRole(PENDING_DEVS) {
    contractRoles.remove(PENDING_DEVS, msg.sender);
  }

  /// @dev This starts the push-pull method of onlyDev()
  /// @param newDeveloper: addres of new pending developer role
  function pushDeveloper(
    address newDeveloper
  ) external
    onlyRole(DEVS) {
    contractRoles.add(PENDING_DEVS, newDeveloper);
  }

  //////////////////////////////////////////
  /// [Not an EIP]: Contract Roles Standard
  //////////////////////////////////////////

  /// @dev Returns `true` if `account` has been granted `role`.
  /// @param role: Bytes4 of a role
  /// @param account: Address to check
  /// @return bool true/false if account has role
  function hasRole(
    bytes4 role
  , address account
  ) external
    view
    returns (bool) {
    return contractRoles.has(role, account);
  }

  /// @dev Returns the admin role that controls a role
  /// @param role: Role to check
  /// @return admin role
  function getRoleAdmin(
    bytes4 role
  ) external
    view 
    returns (bytes4) {
    return ADMIN;
  }

  /// @dev Grants `role` to `account`
  /// @param role: Bytes4 of a role
  /// @param account: account to give role to
  function grantRole(
    bytes4 role
  , address account
  ) external
    onlyRole(role) {
    if (role == PENDING_DEVS || role == PENDING_OWNERS) {
      revert Unauthorized();
    } else {
      contractRoles.add(role, account);
    }
  }

  /// @dev Revokes `role` from `account`
  /// @param role: Bytes4 of a role
  /// @param account: account to revoke role from
  function revokeRole(
    bytes4 role
  , address account
  ) external
    onlyRole(role) {
    if (role == PENDING_DEVS || role == PENDING_OWNERS) {
      if (account == msg.sender) {
        contractRoles.remove(role, account);
      } else {
        revert Unauthorized();
      }
    } else {
      contractRoles.remove(role, account);
    }
  }

  /// @dev Renounces `role` from `account`
  /// @param role: Bytes4 of a role
  function renounceRole(
    bytes4 role
  ) external
    onlyRole(role) {
    contractRoles.remove(role, msg.sender);
  }

  ////////////////////////////////////////////////////////////////////////
  /// ERC-721 Non-Fungible Token Standard, optional enumeration extension
  /// @dev may be added, but not fully supported see ERC-165 below
  ////////////////////////////////////////////////////////////////////////

  /// @notice Count NFTs tracked by this contract
  /// @return A count of valid NFTs tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply()
    external
    view
    virtual
    returns (uint256) {
    return token721.getSupply();
  }

  /////////////////////////////////////////////////
  /// ERC721 Metadata, optional metadata extension
  /////////////////////////////////////////////////

  /// @notice A descriptive name for a collection of NFTs in this contract
  function name()
    external
    view
    virtual
    override
    returns (string memory _name) {
    return token721.getName();
  }

  /// @notice An abbreviated name for NFTs in this contract
  function symbol()
    external
    view
    virtual
    override
    returns (string memory _symbol) {
    return token721.getSymbol();
  }

  /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
  /// @notice Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
  ///  3986. The URI may point to a JSON file that conforms to the "ERC721
  ///  Metadata JSON Schema".
  function tokenURI(
    uint256 _tokenId
  ) external
    view
    virtual
    override
    returns (string memory) {
    return token721.getTokenURI(_tokenId);
  }

  ////////////////////////////////////////
  /// ERC-721 Non-Fungible Token Standard
  ////////////////////////////////////////

  /// @notice Count all NFTs assigned to an owner
  /// @notice NFTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param _owner An address for whom to query the balance
  /// @return The number of NFTs owned by `_owner`, possibly zero
  function balanceOf(
    address _owner
  ) external
    view
    virtual
    override
    returns (uint256) {
    return token721.getBalanceOf(_owner);
  }

  /// @notice Find the owner of an NFT
  /// @notice NFTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param _tokenId The identifier for an NFT
  /// @return The address of the owner of the NFT
  function ownerOf(
    uint256 _tokenId
  ) external
    view
    virtual
    override
    returns (address) {
    return token721.getOwnerOf(_tokenId);
  }

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @notice Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
  ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
  ///  `onERC721Received` on `_to` and throws if the return value is not
  ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  /// @param data Additional data with no specified format, sent in call to `_to`
  function safeTransferFrom(
    address _from
  , address _to
  , uint256 _tokenId
  , bytes calldata data
  ) external
    virtual
    override {
    token721.doTransferFrom(_from, _to, msg.sender, _tokenId);
    safeHook(_from, _to, _tokenId, data);
    emit Transfer(_from, _to, _tokenId);
  }

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @notice This works identically to the other function with an extra data parameter,
  ///  except this function just sets data to "".
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  function safeTransferFrom(
    address _from
  , address _to
  , uint256 _tokenId
  ) external
    virtual
    override {
    this.safeTransferFrom(_from, _to, _tokenId, "");
  }

  /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
  ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
  ///  THEY MAY BE PERMANENTLY LOST
  /// @notice Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  `_tokenId` is not a valid NFT.
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  function transferFrom(
    address _from
  , address _to
  , uint256 _tokenId
  ) external
    virtual
    override {
    token721.doTransferFrom(_from, _to, msg.sender, _tokenId);
    emit Transfer(_from, _to, _tokenId);
  }

  /// @notice Change or reaffirm the approved address for an NFT
  /// @notice The zero address indicates there is no approved address.
  ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
  ///  operator of the current owner.
  /// @param _approved The new approved NFT controller
  /// @param _tokenId The NFT to approve
  function approve(
    address _approved
  , uint256 _tokenId
  ) external
    virtual
    override {
    token721.setApprove(_approved, msg.sender, _tokenId);
    emit Approval(msg.sender, _approved, _tokenId);
  }

  /// @notice Enable or disable approval for a third party ("operator") to manage
  ///  all of `msg.sender`'s assets
  /// @notice Emits the ApprovalForAll event. The contract MUST allow
  ///  multiple operators per owner.
  /// @param _operator Address to add to the set of authorized operators
  /// @param _approved True if the operator is approved, false to revoke approval
  function setApprovalForAll(
    address _operator
  , bool _approved
  ) external
    virtual
    override {
    token721.setApprovalForAll(_operator, msg.sender, _approved);
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /// @notice Get the approved address for a single NFT
  /// @notice Throws if `_tokenId` is not a valid NFT.
  /// @param _tokenId The NFT to find the approved address for
  /// @return The approved address for this NFT, or the zero address if there is none
  function getApproved(
    uint256 _tokenId
  ) external
    view
    virtual
    override
    returns (address) {
    return token721.getApproved(_tokenId);
  }

  /// @notice Query if an address is an authorized operator for another address
  /// @param _owner The address that owns the NFTs
  /// @param _operator The address that acts on behalf of the owner
  /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
  function isApprovedForAll(
    address _owner
  , address _operator
  ) external
    view
    virtual
    override
    returns (bool) {
    return token721.isApprovedForAll(_owner, _operator);
  }

  ///////////////////////////////////////////////////////////////////
  /// ERC-721 Non-Fungible Token Standard, required wallet interface
  /// @dev This is to disable all safe transfers to this contract
  ///////////////////////////////////////////////////////////////////

  /// @notice Handle the receipt of an NFT
  /// @notice The ERC721 smart contract calls this function on the recipient
  ///  after a `transfer`. This function MAY throw to revert and reject the
  ///  transfer. Return of other than the magic value MUST result in the
  ///  transaction being reverted.
  ///  Note: the contract address is always the message sender.
  /// @param _operator The address which called `safeTransferFrom` function
  /// @param _from The address which previously owned the token
  /// @param _tokenId The NFT identifier which is being transferred
  /// @param _data Additional data with no specified format
  /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  ///  unless throwing
  function onERC721Received(
    address _operator
  , address _from
  , uint256 _tokenId
  , bytes calldata _data
  ) external
    virtual
    override
    returns(bytes4) {
    revert Unauthorized();
  }

  ///////////////////////////////////
  /// EIP-2981: NFT Royalty Standard
  ///////////////////////////////////

  /// @notice Called with the sale price to determine how much royalty
  ///         is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
  /// @return receiver - address of who should be sent the royalty payment
  /// @return royaltyAmount - the royalty payment amount for _salePrice
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external
    view
    virtual
    override
    returns (
      address receiver,
      uint256 royaltyAmount
    ) {
    (receiver, royaltyAmount) = royalties.royaltyInfo(_tokenId,_salePrice);
  }

  ////////////////////////////////////////////////////
  /// EIP-2981: NFT Royalty Standard, admin extension
  /// @dev Using the collection standard
  ////////////////////////////////////////////////////

  /// @dev function (state storage) sets the royalty data for a token
  /// @param tokenId uint256 for the token
  /// @param receiver address for the royalty reciever for token
  /// @param permille uint16 for the permille of royalties 20 -> 2.0%
  function setRoyalties(
    uint256 tokenId
  , address receiver
  , uint16 permille
  ) external
    virtual
    override {
    revert Unauthorized();
  }

  /// @dev function (state storage) revokes the royalty data for a token
  /// @param tokenId uint256 for the token
  function revokeRoyalties(
    uint256 tokenId
  ) external
    virtual
    override {
    revert Unauthorized();
  }

  /// @dev function (state storage) sets the royalty data for a collection
  /// @param receiver address for the royalty reciever for token
  /// @param permille uint16 for the permille of royalties 20 -> 2.0%
  function setRoyalties(
    address receiver
  , uint16 permille
  ) external
    virtual
    onlyOwner()
    override {
    royalties.setRoyalties(receiver, permille);
  }

  /// @dev function (state storage) revokes the royalty data for a collection
  function revokeRoyalties()
    external
    virtual
    onlyOwner()
    override {
    royalties.revokeRoyalties();
  }

  ////////////////////////////////////////////////////////////////
  /// [Not an EIP] Payment Splitter, interface for ether payments
  ////////////////////////////////////////////////////////////////

  /// @dev returns total shares
  /// @return uint256 of all shares on contract
  function totalShares()
    external
    view
    virtual
    override
    returns (uint256) {
    return splitter.getTotalShares();
  }

  /// @dev returns shares of an address
  /// @param payee address of payee to return
  /// @return mapping(address => uint) of _shares
  function shares(
    address payee
  ) external
    view
    virtual
    override
    returns (uint256) {
    return splitter.payeeShares(payee);
  }

  /// @dev returns total releases in "eth"
  /// @return uint256 of all "eth" released in wei
  function totalReleased()
    external
    view
    virtual
    override
    returns (uint256) {
    return splitter.getTotalReleased();
  }

  /// @dev returns released "eth" of an payee
  /// @param payee address of payee to look up
  /// @return mapping(address => uint) of _released
  function released(
    address payee
  ) external
    view
    virtual
    override
    returns (uint256) {
    return splitter.payeeReleased(payee);
  }

  /// @dev returns amount of "eth" that can be released to payee
  /// @param payee address of payee to look up
  /// @return uint in wei of "eth" to release
  function releasable(
    address payee
  ) external
    view
    virtual
    override
    returns (uint256) {
    uint totalReceived
      = address(this).balance
      + this.totalReleased();
    return 
      totalReceived
    * this.shares(payee)
    / this.totalShares()
    - this.released(payee);
  }

  /// @dev returns index number of payee
  /// @param payee number of index
  /// @return address at _payees[index]
  function payeeIndex(
    address payee
  ) external
    view
    virtual
    override
    returns (uint256) {
    return splitter.payeeIndex(payee);
  }

  /// @dev this returns the array of payees[]
  /// @return address[] payees
  function payees()
    external
    view
    virtual
    override
    returns (address[] memory) {
    return splitter.getPayees();
  }

  /// @dev this claims all "eth" on contract for msg.sender
  function claim()
    external
    virtual
    override {
    if (this.shares(msg.sender) == 0) {
      revert Unauthorized();
    }
    uint256 payment = this.releasable(msg.sender);
    if (payment == 0) {
      revert Unauthorized();
    }
    splitter.processPayment(msg.sender, payment);
    Address.sendValue(payable(msg.sender), payment);
  }

  /// @dev This pays all payees
  function payClaims()
    external
    virtual
    override {
    address[] memory toPay = splitter.getPayees();
    uint256 len = toPay.length;
    for (uint x = 0 ; x < len ;) {
      uint256 payment = this.releasable(toPay[x]);
      splitter.processPayment(toPay[x], payment);
      Address.sendValue(payable(toPay[x]), payment);
      unchecked { ++x; }
    }
  }

  /// @dev This adds a payee
  /// @param payee Address of payee
  /// @param _shares Shares to send user
  function addPayee(
    address payee
  , uint256 _shares
  ) external
    virtual
    onlyDev()
    override {
    splitter.addPayee(payee, _shares);
  }

  /// @dev This removes a payee
  /// @param payee Address of payee to remove
  /// @notice use payPayees() prior to use if anything is on the contract
  function removePayee(
    address payee
  ) external
    virtual
    onlyDev()
    override {
    splitter.removePayee(payee);
  }

  /// @dev This removes all payees
  /// @notice use payPayees() prior to use if anything is on the contract
  function clearPayees()
    external
    virtual
    onlyDev()
    override {
    splitter.clearPayees();
  }

  //////////////////////////////////////////
  /// EIP-165: Standard Interface Detection
  //////////////////////////////////////////

  /// @dev Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @notice Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(
    bytes4 interfaceID
  ) external
    view
    virtual
    override
    returns (bool) {
    return (
      interfaceID == type(IERC173).interfaceId  ||
      interfaceID == type(IERC721).interfaceId  ||
      interfaceID == type(IERC2981).interfaceId  ||
      interfaceID == type(IERC721Metadata).interfaceId
    );
  }
}
