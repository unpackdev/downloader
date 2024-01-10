// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract Claim is Ownable, ReentrancyGuard {
  bytes32 public ROOT;
  ERC20 public REWARD;

  constructor(address reward, bytes32 root) {
    ROOT = root;
    REWARD = ERC20(reward);
  }

  function verify(bytes32[] memory proof, bytes32 leaf)
    public
    view
    returns (bool)
  {
    return MerkleProof.verify(proof, ROOT, leaf);
  }

  mapping(address => bool) public claimedAddresses;

  function claim(uint256 amount, bytes32[] memory proof) public nonReentrant {
    require(claimedAddresses[msg.sender] == false, "Already claimed");
    require(
      verify(proof, keccak256(abi.encodePacked(amount, msg.sender))),
      "Not valid"
    );
    claimedAddresses[msg.sender] = true;
    REWARD.transfer(msg.sender, amount);
  }

  function setRoot(bytes32 _root) public onlyOwner {
    ROOT = _root;
  }

  function migrate() public onlyOwner {
    REWARD.transfer(owner(), REWARD.balanceOf(address(this)));
  }
}
