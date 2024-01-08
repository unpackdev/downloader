// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Counters.sol";

import "./IERC2612Permit.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to use their tokens
 * without sending any transactions by setting {IERC20-allowance} with a
 * signature using the {permit} method, and then spend them via
 * {IERC20-transferFrom}.
 */


abstract contract ERC20Permit is ERC20, IERC2612Permit {
  using Counters for Counters.Counter;

  mapping(address => Counters.Counter) private _nonces;

  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

  bytes32 public DOMAIN_SEPARATOR;

  constructor() {
    uint256 chainID;
    assembly {
      chainID := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(name())),
        keccak256(bytes("1")), // Version
        chainID,
        address(this)
      )
    );
  }

  /**
   * @dev See {IERC2612Permit-permit}.
   * v,r,s params are ecdsa signature output for more information please see ethereum ecdsa specs.
   * Apendix-f of https://ethereum.github.io/yellowpaper/paper.pdf.
   * @param owner token owner
   * @param spender user address which is allowed to spend tokens
   * @param amount number of token to be spent
   * @param deadline validity for spending the tokens
   * @param v recovery identifier of ecdsa signature
   * @param r r value/ x-value of ecdsa signature
   * @param s s value of ecdsa signature
   */
  function permit(
    address owner,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual override {
    require(block.timestamp <= deadline, "TDLPermit: expired deadline");

    bytes32 hashStruct =
      keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline));

    bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

    address signer = ecrecover(_hash, v, r, s);
    require(signer != address(0) && signer == owner, "TDLPermit: Invalid signature");

    _nonces[owner].increment();
    _approve(owner, spender, amount);
  }

  /**
   * @dev See {IERC2612Permit-nonces}.
   * @param owner token owner
   * @return current nonce of the owner address
   */
  function nonces(address owner) public view override returns (uint256) {
    return _nonces[owner].current();
  }
}
