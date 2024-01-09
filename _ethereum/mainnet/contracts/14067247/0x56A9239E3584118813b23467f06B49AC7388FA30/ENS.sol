// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ENS.sol";
import "./ECDSA.sol";

contract ENSRegistrar {
  using ECDSA for bytes32;


  event AuthorizedOperator(address indexed operator, bytes32 indexed zone);
  event RevokedOperator(address indexed operator, bytes32 indexed zone);
  event DomainMapped(string label);

  mapping (bytes32 => mapping (address => bool)) private _operators;
  mapping (bytes32 => bytes32) public domains;
  mapping (bytes32 => uint256) public nonces;

  ENS public ens;

  constructor(ENS registry) {
    ens = registry;
  }

  function isOperatorFor(
    address operator,
    bytes32 zone
  ) public view virtual returns (bool) {
    return _operators[zone][operator];
  }

  function authorizeOperator(
    bytes32 zone,
    address operator
  ) public virtual {
    require(msg.sender == ens.owner(domains[zone]), "unauthorized");
    _operators[zone][operator] = true;
    emit AuthorizedOperator(operator, zone);
  }

  function revokeOperator(
    bytes32 zone,
    address operator
  ) public virtual {
    require(msg.sender == ens.owner(domains[zone]), "unauthorized");
    delete _operators[zone][operator];
    emit RevokedOperator(operator, zone);
  }

  function mapDomain(string memory label) public virtual {
    bytes32 _label = keccak256(bytes(label));
    bytes32 _eth = keccak256(abi.encodePacked(
      bytes32(0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae),
      _label
    ));

    require(msg.sender == ens.owner(_eth), "unauthorized");
    bytes32 zone = keccak256(abi.encodePacked(bytes32(0x0), _label));

    domains[zone] = _eth;
    emit DomainMapped(label);
  }

  function claim(
    address to,
    bytes32 zone,
    string memory label,
    bytes memory signature,
    uint256 nonce
  ) public virtual {
    bytes32 _label = keccak256(bytes(label));
    bytes32 _domain = keccak256(abi.encodePacked(zone, _label));

    require(nonce > nonces[_domain], "invalid nonce");

    bytes32 message = keccak256(abi.encodePacked(nonce, to, _domain));
    address operator = message.toEthSignedMessageHash().recover(signature);

    require(isOperatorFor(operator, zone), "unauthorized");

    nonces[_domain] = nonce;
    ens.setSubnodeOwner(domains[zone], _label, to);
  }
}
