// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./ANWERC20.sol";

import "./EIP712.sol";

import "./IPairERC20.sol";

contract PairERC20 is ANWERC20, EIP712, IPairERC20 {
    bytes32 public override DOMAIN_SEPARATOR;

    bytes32 public constant override PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 salt,uint256 deadline)");

    mapping(address => mapping(uint256 => bool)) public override permitSalt;

    constructor() ANWERC20("ANW Finance LPs", "ANWFI-LP") EIP712("ANW Finance LPs", "1.0.0") {
        DOMAIN_SEPARATOR = _domainSeparatorV4();
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 salt,
        uint256 deadline,
        bytes calldata signature
    ) public virtual override {
        require(deadline >= block.timestamp, "PoolERC20::permit: EXPIRED");
        require(!permitSalt[owner][salt], "PoolERC20::permit: INVALID_SALT");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, salt, deadline))
        );

        address signer = ECDSA.recover(digest, signature);
        require(signer != address(0) && signer == owner, "PoolERC20::permit: INVALID_SIGNATURE");

        permitSalt[owner][salt] = true;
        _approve(owner, spender, value);
    }
}
