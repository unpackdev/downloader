// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Amount.sol";

contract SyntheticStorageV1 {

    /**
     * @dev ERC20 Properties
     */
    uint8   internal _version;
    string  internal _name;
    string  internal _symbol;
    uint256 internal _totalSupply;

    mapping (address => uint256)                      internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    /**
     * @dev Minter Properties
     */
    address[]                            internal _mintersArray;
    mapping(address => bool)             internal _minters;
    mapping(address => uint256)          internal _minterLimits;
    mapping(address => Amount.Principal) internal _minterIssued;
}

contract SyntheticStorage is SyntheticStorageV1 { /* solium-disable-line no-empty-blocks */ }
