// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IBagBang.sol";

contract LinearVest is Ownable {
  using SafeMath for uint256;

  IBagBang public bagBang;
  uint256 public totalAmount;
  uint256 public startBlock;
  uint256 public endBlock;
  uint256 public cliffBlock;
  uint256 public numBlocks;
  uint256 public withdrawn;

  constructor(IBagBang _bagBang, uint256 _totalAmount, uint256 _startBlock, uint256 _endBlock, uint256 _cliffBlock) public {
    require(_endBlock > _startBlock);

    bagBang = _bagBang;
    totalAmount = _totalAmount;
    startBlock = _startBlock;
    endBlock = _endBlock;
    cliffBlock = _cliffBlock;
    numBlocks = _endBlock.sub(_startBlock);
    withdrawn = 0;
  }

  function withdraw(uint256 amount) public onlyOwner {
    require(amount > 0, "withdraw: amount must be nonzero");

    uint256 withdrawableAmount = getWithdrawableAmount();
    require(amount <= withdrawableAmount, "withdraw: amount not available");
    
    bagBang.mintDev(msg.sender, amount);
    withdrawn = withdrawn.add(amount);
  }

  function getVestedAmount() public view returns (uint256) {
    if (block.number < startBlock) {
      return 0;
    }
    
    if (block.number >= endBlock) {
      return totalAmount;
    }

    return totalAmount.mul(block.number.sub(startBlock)).div(numBlocks);
  }

  function getWithdrawableAmount() public view returns (uint256) {
    // No withdrawals until cliff has passed
    if (block.number < cliffBlock) {
      return 0;
    }

    return getVestedAmount().sub(withdrawn);
  }
}
