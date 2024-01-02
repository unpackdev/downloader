// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./SNS.sol";
import "./IReverseRegistrar.sol";
import "./Resolver.sol";
import "./Controllable.sol";

contract ReverseRegistrar is Controllable, IReverseRegistrar {
  bytes32 constant lookup =
    0x3031323334353637383961626364656600000000000000000000000000000000;

  // value of `namehash('addr.reverse')`
  bytes32 constant ADDR_REVERSE_NODE =
    0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

  SNS public immutable sns;
  address public defaultResolver;

  event ReverseClaimed(address indexed addr, bytes32 indexed node);

  constructor(SNS _sns) {
    sns = _sns;
  }

  modifier authorised(address addr) {
    require(
      addr == msg.sender ||
        controllers[msg.sender] ||
        sns.isApprovedForAll(addr, msg.sender),
      "ReverseRegistrar: Caller is not a controller or authorised by address"
    );
    _;
  }

  function claimForAddr(
    address addr,
    address owner,
    address resolver
  ) public override authorised(addr) returns (bytes32) {
    bytes32 labelHash = sha3HexAddress(addr);
    bytes32 reverseNode = keccak256(
      abi.encodePacked(ADDR_REVERSE_NODE, labelHash)
    );
    emit ReverseClaimed(addr, reverseNode);
    sns.setSubnodeRecord(ADDR_REVERSE_NODE, labelHash, owner, resolver, 0);
    return reverseNode;
  }

  function setNameForAddr(
    address addr,
    address owner,
    address resolver,
    string memory name
  ) public override returns (bytes32) {
    bytes32 node = claimForAddr(addr, owner, resolver);
    Resolver(resolver).setName(node, name);
    return node;
  }

  function node(address addr) public pure override returns (bytes32) {
    return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr)));
  }

  function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
    assembly {
      for {
        let i := 40
      } gt(i, 0) {

      } {
        i := sub(i, 1)
        mstore8(i, byte(and(addr, 0xf), lookup))
        addr := div(addr, 0x10)
        i := sub(i, 1)
        mstore8(i, byte(and(addr, 0xf), lookup))
        addr := div(addr, 0x10)
      }

      ret := keccak256(0, 40)
    }
  }
}
