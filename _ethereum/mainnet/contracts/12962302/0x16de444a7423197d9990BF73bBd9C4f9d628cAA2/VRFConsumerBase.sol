// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./SafeMath.sol";
import "./LinkTokenInterface.sol";
import "./VRFRequestIDBase.sol";

abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMath for uint256;

  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    public returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  mapping(bytes32 => uint256) public nonces;
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}