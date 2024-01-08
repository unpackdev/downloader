// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BubbleGumAction.sol";

contract BubbleGumJuice is BubbleGumAction {
  constructor(string memory _name, string memory _symbol, uint _launchAt) BubbleGumAction(_name, _symbol, _launchAt) {}

  function tokenOfStakerByIndex(address _staker, uint256 _index) public view returns (uint256) {
    require(_index < totalStakedGums[_staker], "Staker index out of bounds");
    return _stakedGums[_staker][_index];
  }

  function snappable(uint _id) public view returns (uint) {
    if (meta[_id].lastSnap == 0) return 0;

    uint delta = block.number - meta[_id].lastSnap;
    uint amt = meta[_id].size * meta[_id].intensity * delta * vars[Var.CHEW_RATE];

    return amt;
  }

  function snap(uint _id) onlyStakeOwner(_id) whenNotPaused public {
    uint amt = snappable(_id);
    uint split = amt / vars[Var.STAKE_SPLIT];
    amt -= split;

    if (amt > 0) _juicy.mint(msg.sender, amt);
    if (split > 0) _juicy.mint(address(this), split);

    meta[_id].lastSnap = block.number;

    emit Snap(amt, msg.sender);
  }

  function stake(uint _id) onlyTokenOwner(_id) whenNotPaused external {
    meta[_id].lastSnap = block.number;
    uint256 length = totalStakedGums[msg.sender];
    _stakedGums[msg.sender][length] = _id;
    _stakedGumsIndex[_id] = length;
    stakeOwners[_id] = msg.sender;
    totalStakedGums[msg.sender]++;

    _transfer(msg.sender, address(this), _id);
    emit Stake(_id, msg.sender);
  }

  function unstake(uint _id) onlyStakeOwner(_id) whenNotPaused external {
    snap(_id);

    uint256 lastIdx = --totalStakedGums[msg.sender];
    uint256 idx = _stakedGumsIndex[_id];
    if (idx != lastIdx) {
      uint256 lastId = _stakedGums[msg.sender][lastIdx];
      _stakedGums[msg.sender][idx] = lastId;
      _stakedGumsIndex[lastId] = idx;
    }
    delete _stakedGumsIndex[_id];
    delete _stakedGums[msg.sender][lastIdx];
    delete stakeOwners[_id];
    meta[_id].lastSnap = 0;

    bool isDropped = _roll("drop", _id, vars[Var.PROBA_DROP]);
    if (isDropped) {
      return _destroy(_id);
    } else {
      uint gasBurn = 0;
      for (uint i = 0; i < 250; i++) gasBurn++; // Prevent low-pass exploit.

      _transfer(address(this), msg.sender, _id);
      emit Unstake(_id, msg.sender);
    }
  }
}