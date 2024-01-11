// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./MockERC20.sol";

contract MockERC20Permit is MockERC20 {
  bytes32 public immutable DOMAIN_SEPARATOR;

  bytes32 public constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  mapping(address => uint256) public nonces;

  string public constant version = "1";

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    uint256 supply
  ) public MockERC20(_name, _symbol, _decimals, supply) {
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(_name)),
        keccak256(bytes(version)),
        31337,
        address(this)
      )
    );
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    require(owner != address(0), "INVALID_OWNER");
    require(block.timestamp <= deadline, "INVALID_EXPIRATION");
    uint256 currentValidNonce = nonces[owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
      )
    );

    require(owner == ecrecover(digest, v, r, s), "INVALID_SIGNATURE");
    nonces[owner] = currentValidNonce.add(1);
    _approve(owner, spender, value);
  }
}
