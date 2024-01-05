// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IBagBang.sol";

contract AdvisorPool is Ownable {
  using SafeMath for uint256;

  IBagBang public bagBang;
  uint256 public totalPool;
  uint256 public cliffBlock;

  mapping(address => uint256) public advisors;
  uint256 public totalAllocated;
  uint256 public totalWithdrawn;

  constructor(IBagBang _bagBang, uint256 _totalPool, uint256 _cliffBlock) public {
    bagBang = _bagBang;
    totalPool = _totalPool;
    cliffBlock = _cliffBlock;
    totalAllocated = 0;
    totalWithdrawn = 0;
  }

  function addAdvisor(address _advisor, uint256 _amount) public onlyOwner {
    require(advisors[_advisor]==0);
    require(_amount > 0);
    require(totalAllocated.add(_amount) <= totalPool);
    
    advisors[_advisor] = _amount;
    totalAllocated = totalAllocated.add(_amount);
  }

  function withdraw() public {
    require(block.number >= cliffBlock);

    uint256 amount = advisors[msg.sender];
    require(amount > 0);

    advisors[msg.sender] = 0;
    totalWithdrawn = totalWithdrawn.add(amount);
    bagBang.mintAdvisors(msg.sender, amount);
  }
}
