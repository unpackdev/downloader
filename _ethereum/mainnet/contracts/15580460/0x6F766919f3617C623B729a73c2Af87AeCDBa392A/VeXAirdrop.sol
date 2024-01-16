//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./BitMaps.sol";
import "./IERC20.sol";
import "./Ownable.sol";

interface IVE {
  // solhint-disable func-name-mixedcase
  function create_lock_for(
    address,
    uint256,
    uint256
  ) external;

  function deposit_for(address, uint256) external;

  function locked__end(address) external view returns (uint256);
  // solhint-enable func-name-mixedcase
}

contract VeXAirdrop is Ownable {
  using BitMaps for BitMaps.BitMap;

  IERC20 public token;
  IVE public ve;
  bytes32[] public roots;
  mapping(address => BitMaps.BitMap) internal _claimed;

  event RootSet(uint256 round, bytes32 root);
  event Claimed(address indexed claimer, uint256[] round, uint256[] amount);
  uint256 public constant MAX_LOCK_TIME = 4 * 365 * 86400; // 4 years

  constructor(IERC20 _token, IVE _ve) {
    token = _token;
    ve = _ve;
  }

  function addRoot(bytes32 _root) external onlyOwner {
    emit RootSet(roots.length, _root);
    roots.push(_root);
  }

  function setRoot(uint256 round, bytes32 _root) external onlyOwner {
    require(roots.length > round, "index out of bound");
    roots[round] = _root;
    emit RootSet(round, _root);
  }

  function withdraw(IERC20 _token) external onlyOwner {
    uint256 balance = _token.balanceOf(address(this));
    token.transfer(msg.sender, balance);
  }

  function nextRound() external view returns (uint256) {
    return roots.length;
  }

  function claim(
    uint256[] memory rounds,
    uint256[] memory amounts,
    bytes32[][] memory proofs
  ) external {
    require(
      rounds.length == amounts.length && amounts.length == proofs.length,
      "invalid length"
    );

    uint256 totalAmount = 0;
    for (uint256 i = 0; i < rounds.length; i++) {
      uint256 round = rounds[i];
      require(round < roots.length, "invalid round");
      require(!_claimed[msg.sender].get(round), "already claimed");
      _claimed[msg.sender].set(round);
      totalAmount += amounts[i];
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amounts[i]));
      require(
        MerkleProof.verify(proofs[i], roots[round], leaf),
        "invalid proof"
      );
    }
    require(token.approve(address(ve), totalAmount), "approve failed");
    if (ve.locked__end(msg.sender) == 0) {
      ve.create_lock_for(
        msg.sender,
        totalAmount,
        // solhint-disable-next-line not-rely-on-time
        block.timestamp + MAX_LOCK_TIME
      );
    } else {
      ve.deposit_for(msg.sender, totalAmount);
    }
    emit Claimed(msg.sender, rounds, amounts);
  }

  function claimed(address claimer, uint256 round)
    external
    view
    returns (bool)
  {
    return _claimed[claimer].get(round);
  }
}
