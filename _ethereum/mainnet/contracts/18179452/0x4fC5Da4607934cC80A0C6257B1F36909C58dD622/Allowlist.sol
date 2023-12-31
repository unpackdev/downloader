// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IAllowlist.sol";

/**
 * A contract that keeps track of a list of allowed addresses and code hashes. This is
 * intended to be inherited by the Registry contract.
 */
contract Allowlist is IAllowlist {
  mapping(address => bool) public allowedContractAddresses;
  mapping(bytes32 => bool) public allowedCodeHashes;

  bool public isAllowlistDisabled;

  event AllowlistDisabled(bool indexed disabled);
  event AllowedContractAddressAdded(address indexed contractAddress);
  event AllowedContractAddressRemoved(address indexed contractAddress);
  event AllowedCodeHashAdded(bytes32 indexed codeHash);
  event AllowedCodeHashRemoved(bytes32 indexed codeHash);

  /**
   * @notice A global killswitch to either enable or disable the allowlist. By default
   * it is not disabled.
   * @param disabled Status of the allowlist
   */
  function _setIsAllowlistDisabled(
    bool disabled
  )
  internal
  virtual
  {
    isAllowlistDisabled = disabled;
    emit AllowlistDisabled(disabled);
  }

  /**
   * @notice Checks if operator is on the allowlist. If the operator is a contract
   * it also checks whether or not the codehash is on the allowlist.
   * Returns true if operator is an externally owned account.
   * @param operator Address of operator
   * @return Bool whether operator is allowed
   */
  function _isAllowed(
    address operator
  )
  internal
  virtual
  view
  returns (bool)
  {
    if (_isEOA(operator)) {
      return true;
    } else if (_isContract(operator)) {
      if (_isAllowedContractAddress(operator)) {
        return true;
      } else {
        return _isAllowedCodeHash(operator.codehash);
      }
    }

    return false;
  }

  modifier onlyAllowlistAllowed(address operator) {
    if (_isAllowed(operator)) {
      _;
    } else {
      revert IAllowlist.NotAllowlisted();
    }
  }

  /**
  * @notice Checks if operator is an externally owned account and not a contract
  * @param operator Address of operator
  * @return Bool whether operator is externally owned account
  */
  function _isEOA(address operator)
  internal
  view
  returns (bool)
  {
    return tx.origin == operator;
  }

  /**
   * @dev Returns true if the caller is a contract. This can only positively
   * identify a contract, i.e. if it returns true, then the caller is definitely
   * a contract. If it returns false, you should not draw any conclusions,
   * since e.g. code is length 0 if the caller is a contract's caller (in which
   * case this method returns false, despite the caller being a contract).
   * @param operator Address of operator
   * @return Bool whether operator is a contract
   */
  function _isContract(address operator)
  internal
  view
  returns (bool)
  {
    return (operator.code.length > 0);
  }

  /**
   * @notice Calls the internal function _isAllowed that checks if operator is on the allowlist.
   * @param operator - Address of operator
   * @return Bool whether operator is allowed
   */
  function isAllowed(
    address operator
  )
  external
  view
  virtual
  returns (bool)
  {
    return _isAllowed(operator);
  }

  /**
   * @notice Add a contract to the allowed registry
   * @param contractAddress - Contract address
   */
  function _addAllowedContractAddress(
    address contractAddress
  )
  internal
  virtual
  {
    allowedContractAddresses[contractAddress] = true;

    emit AllowedContractAddressAdded(
      contractAddress
    );
  }

  /**
   * @notice If the allowlist functionality has been disabled via the global killswitch,
   * always return true to let all requests through.
   * @param contractAddress - Contract address
   * @return Bool whether contract address is allowed
   */
  function _isAllowedContractAddress(
    address contractAddress
  )
  internal
  view
  virtual
  returns (bool)
  {
    if (isAllowlistDisabled) {
      return true;
    }

    return allowedContractAddresses[contractAddress];
  }

  /**
   * @notice External function that checks if contract address is on the allowlist
   * @param contractAddress - Contract address
   * @return Bool whether contract address is allowed
   */
  function isAllowedContractAddress(
    address contractAddress
  )
  external
  view
  virtual
  returns (bool)
  {
    return _isAllowedContractAddress(contractAddress);
  }

  /**
   * @notice Removes a contract from the allowlist
   * @param contractAddress - Contract address
   */
  function _removeAllowedContractAddress(
    address contractAddress
  )
  internal
  virtual
  {
    delete allowedContractAddresses[contractAddress];

    emit AllowedContractAddressRemoved(
      contractAddress
    );
  }

  /**
   * @notice Adds a codehash to the allowlist
   * @param codeHash - Contract address
   */
  function _addAllowedCodeHash(
    bytes32 codeHash
  )
  internal
  virtual
  {
    allowedCodeHashes[codeHash] = true;

    emit AllowedCodeHashAdded(
      codeHash
    );
  }

  /**
   * @notice If the allowlist functionality has been disabled via the global killswitch,
   * always return true to let all requests through.
   * @param codeHash - Code hash
   * @return Bool whether code hash is allowed
   */
  function _isAllowedCodeHash(
    bytes32 codeHash
  )
  internal
  view
  virtual
  returns (bool)
  {
    if (isAllowlistDisabled) {
      return true;
    }

    return allowedCodeHashes[codeHash];
  }

  /**
   * @notice External function that checks if the codehash is on the allowlist
   * @param contractAddress - Contract address
   * @return Bool whether code hash is allowed
   */
  function isAllowedCodeHash(
    address contractAddress
  )
  external
  view
  virtual
  returns (bool)
  {
    return _isAllowedCodeHash(contractAddress.codehash);
  }

  /**
   * @notice Removes a codehash from the allowlist
   * @param codeHash - Code hash
   */
  function _removeAllowedCodeHash(
    bytes32 codeHash
  )
  internal
  virtual
  {
    delete allowedCodeHashes[codeHash];

    emit AllowedCodeHashRemoved(
      codeHash
    );
  }
}
