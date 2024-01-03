// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Amount.sol";

contract SyntheticStorageV1 {

    /* solium-disable-next-line */
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /**
     * @dev ERC20 Properties
     */
    string  internal _name;
    string  internal _symbol;
    uint256 internal _totalSupply;
    string  internal _version;

    mapping (address => uint256)                      internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    /**
     * @dev Permittable Properties
     */
    bytes32                      public DOMAIN_SEPARATOR;
    mapping (address => uint256) public permitNonces;

    /**
     * @dev Minter Properties
     */
    address[]                            internal _mintersArray;
    mapping(address => bool)             internal _minters;
    mapping(address => uint256)          internal _minterLimits;
    mapping(address => Amount.Principal) internal _minterIssued;
}

contract SyntheticStorage is SyntheticStorageV1 { /* solium-disable-line no-empty-blocks */ }
