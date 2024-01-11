// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//   ____           _   _ _             _      
//  / ___|_ __ __ _| |_(_) |_ _   _  __| | ___ 
// | |  _| '__/ _` | __| | __| | | |/ _` |/ _ \
// | |_| | | | (_| | |_| | |_| |_| | (_| |  __/
//  \____|_|  \__,_|\__|_|\__|\__,_|\__,_|\___|
//
// A collection of 2,222 unique Non-Fungible Power SUNFLOWERS living in 
// the metaverse. Becoming a GRATITUDE GANG NFT owner introduces you to 
// a FAMILY of heart-centered, purpose-driven, service-oriented human 
// beings.
//
// https://www.gratitudegang.io/
//

import "./AccessControl.sol";
import "./Address.sol";
import "./Context.sol";
import "./ECDSA.sol";

import "./SafeERC20.sol";

// ============ Errors ============

error InvalidCall();

// ============ Interfaces ============

interface IERC20MintableBurnable is IERC20 {
  function mint(address to, uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
}

contract GratisBridge is Context, AccessControl {
  //used in redeem()
  using Address for address;

  // ============ Structs ============

  struct TX {
    uint256 contractId;
    address contractAddress;
    address owner;
    uint256 amount;
  }

  // ============ Events ============

  event Bridged(
    uint256 id, 
    uint256 contractId, 
    address contractAddress, 
    address owner, 
    uint256 amount
  );

  // ============ Constants ============

  bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
  bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

  IERC20MintableBurnable public immutable TOKEN;

  //it is possible that the same contract 
  //address exists on multiple chains
  //so we need to set an identifier
  uint256 public immutable CONTRACT_ID;

  // ============ Storage ============
  //countable
  uint256 public lastId;
  //mapping of id to original owner
  mapping(uint256 => TX) public txs;
  //mapping of incoming ids consumed
  mapping(uint256 => bool) public redeemed;
  //mapping of contract id to contract address
  mapping(uint256 => address) public destinations;

  // ============ Deploy ============

  /**
   * @dev Sets the token
   */
  constructor(
    uint256 contractId, 
    IERC20MintableBurnable token, 
    address admin
  ) {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    TOKEN = token;
    CONTRACT_ID = contractId;
  }

  // ============ Write Methods ============

  /**
   * @dev Creates a voucher
   */
  function bridge(
    uint256 contractId, 
    address contractAddress, 
    uint256 amount
  ) external {
    //make sure it is an acceptable destination
    if (destinations[contractId] == address(0)) revert InvalidCall();
    //get the owner
    address owner = _msgSender();
    //burn it. muhahaha
    address(TOKEN).functionCall(
      abi.encodeWithSelector(TOKEN.burnFrom.selector, owner, amount), 
      "Low-level mint failed"
    );
    //make a voucher
    txs[++lastId] = TX(contractId, contractAddress, owner, amount);
    //emit an event
    emit Bridged(lastId, contractId, contractAddress, owner, amount);
  }

  /**
   * @dev Redeems a voucher for a recipient (anyone)
   */
  function redeem(
    uint256 txid, 
    uint256 amount, 
    address recipient,
    bytes memory voucher
  ) external {
    //if redeemed or the signer did not sign this off
    if (redeemed[txid] || !hasRole(SIGNER_ROLE, ECDSA.recover(
      ECDSA.toEthSignedMessageHash(
        keccak256(abi.encodePacked(
          "redeem", 
          CONTRACT_ID, 
          address(this), 
          txid, 
          amount
        ))
      ),
      voucher
    ))) revert InvalidCall();
    //next mint tokens
    address(TOKEN).functionCall(
      abi.encodeWithSelector(TOKEN.mint.selector, recipient, amount), 
      "Low-level mint failed"
    );
    //last consume
    redeemed[txid] = true;
  }

  /**
   * @dev Redeems a voucher to encoded to a specific persson
   */
  function secureRedeem(
    uint256 txid, 
    uint256 amount, 
    address recipient,
    bytes memory voucher
  ) external {
    //if redeemed or the signer did not sign this off
    if (redeemed[txid] || !hasRole(SIGNER_ROLE, ECDSA.recover(
      ECDSA.toEthSignedMessageHash(
        keccak256(abi.encodePacked(
          "redeem", 
          CONTRACT_ID, 
          address(this), 
          txid, 
          amount, 
          recipient
        ))
      ),
      voucher
    ))) revert InvalidCall();
    //next mint tokens
    address(TOKEN).functionCall(
      abi.encodeWithSelector(TOKEN.mint.selector, recipient, amount), 
      "Low-level mint failed"
    );
    //last consume
    redeemed[txid] = true;
  }

  // ============ Admin Methods ============

  /**
   * @dev Adds an acceptable desination
   */
  function addDestination(
    uint256 contractId, 
    address contractAddress
  ) external onlyRole(CURATOR_ROLE) {
    destinations[contractId] = contractAddress;
  }
}