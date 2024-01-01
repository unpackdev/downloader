//SPDX-License-Identifier: MIT

pragma solidity >=0.8.14;

import "./Structs.sol";

contract MasterStorage is Structs {

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 constant PROOFDATA_TYPEHASH =
        keccak256("ProofData(address account,uint256 nonce,uint256 timestamp,address destination)");

    bytes32 DOMAIN_SEPARATOR;

    address public owner;
    mapping(address => uint256) public nonces;
    mapping(address => bool) public signer;
}
