// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./BitMaps.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

contract Airdrop is Ownable {
  using BitMaps for BitMaps.BitMap;
  using SafeERC20 for IERC20;

  address public token;
  uint256 public claimPeriodEnds;

  bytes32 public merkleRoot;

  BitMaps.BitMap private claimed;

  bool public isStart;

  event Claim(address indexed claimant, address delegate, uint256 amount);
  event SetParams(bytes32 merkleRoot, address token, uint256 claimPeriodEnds);

  constructor(address _owner) Ownable() {
    transferOwnership(_owner);
  }

  function claimTokens(
    uint256 amount,
    address delegate,
    bytes32[] calldata merkleProof
  ) external {
    require(isStart, "Not start");
    require(block.timestamp < claimPeriodEnds, "Claim period is ended");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
    (bool valid, uint256 index) = MerkleProof.verify(
      merkleProof,
      merkleRoot,
      leaf
    );

    require(valid, "Valid proof");
    require(!isClaimedByIndex(index), "Already claimed");
    claimed.set(index);

    IERC20(token).safeTransfer(delegate, amount);

    emit Claim(msg.sender, delegate, amount);
  }

  function sweep(address dest) external onlyOwner {
    require(block.timestamp > claimPeriodEnds, "Claim period not yet ended");

    IERC20 t = IERC20(token);
    t.safeTransfer(dest, t.balanceOf(address(this)));
  }

  function isClaimed(
    uint256 amount,
    address _sender,
    bytes32[] calldata merkleProof
  ) external view returns (bool _isClaimed) {
    bytes32 leaf = keccak256(abi.encodePacked(_sender, amount));
    (bool valid, uint256 index) = MerkleProof.verify(
      merkleProof,
      merkleRoot,
      leaf
    );

    require(valid, "Valid proof");

    _isClaimed = isClaimedByIndex(index);
  }

  function isClaimedByIndex(uint256 index) public view returns (bool) {
    return claimed.get(index);
  }

  function setParams(
    bytes32 _merkleRoot,
    address _token,
    uint256 _claimPeriodEnds
  ) external onlyOwner {
    require(!isStart, "Is start");

    merkleRoot = _merkleRoot;
    token = _token;
    claimPeriodEnds = _claimPeriodEnds;

    emit SetParams(_merkleRoot, _token, _claimPeriodEnds);
  }

  function start() external onlyOwner {
    isStart = true;
  }
}
