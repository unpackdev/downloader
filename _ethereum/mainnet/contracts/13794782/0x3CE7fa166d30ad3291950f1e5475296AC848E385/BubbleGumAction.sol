// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BubbleGumStore.sol";

contract BubbleGumAction is BubbleGumStore {
  constructor(string memory _name, string memory _symbol, uint _launchAt) BubbleGumStore(_name, _symbol, _launchAt) {}

  function _removeGenesis(uint _id) private {
    uint256 lastIdx = --totalGenesis;
    uint256 idx = _genesisIdx[_id];
    if (idx != lastIdx) {
      uint256 lastId = genesis[lastIdx];
      genesis[idx] = lastId;
      _genesisIdx[lastId] = idx;
    }
    delete _genesisIdx[_id];
    delete genesis[lastIdx];
  }

  function _destroy(uint _id) internal {
    if (meta[_id].isGenesis) _removeGenesis(_id);
    delete meta[_id];
    _burn(_id);

    emit Destroy(_id, msg.sender);
  }

  function blow(uint _id) onlyTokenOwner(_id) whenNotPaused external {
    require(meta[_id].size < 25, "Max size reached.");

    _juicy.burn(msg.sender, vars[Var.FEE_BLOW]);

    bool isBurst = _roll("burst", _id, vars[Var.PROBA_BURST]);
    if (isBurst) {
      return _destroy(_id);
    } else {
      uint gasBurn = 0;
      for (uint i = 0; i < 420; i++) gasBurn++; // Prevent low-pass exploit.

      meta[_id].size++;

      bool isFren = meta[_id].isGenesis ? _roll("fren", _id, vars[Var.PROBA_FREN]) : false;
      if (isFren) {
        uint amt = _juicy.balanceOf(address(this));
        if (amt > 0) {
          _juicy.burn(address(this), amt);
          _juicy.mint(msg.sender, amt);
          emit Frens(_id, amt, msg.sender);
        }
      }
      emit Blow(_id, meta[_id].size, msg.sender);
    }
  }

  function join(uint _a, uint _b) onlyTokenOwner(_a) onlyTokenOwner(_b) whenNotPaused external {
    _juicy.burn(msg.sender, vars[Var.FEE_JOIN]);

    uint8 flavorA = meta[_a].flavor;
    uint8 flavorB = meta[_b].flavor;
    uint8 flavor = flavorA | flavorB;
    require(flavor != flavorA && flavor != flavorB, "Must create a new flavor.");
    require(meta[_a].isGenesis == meta[_b].isGenesis, "Must be same type.");

    uint size = meta[_a].size + meta[_b].size;
    uint intensity = 0;

    for (uint8 i = 0; i < 8; i++) intensity += _taste(flavor, i) ? 1 : 0;

    bool isGenesis = meta[_a].isGenesis;
    _destroy(_a);
    _destroy(_b);

    bool isDropped = _roll("join", _a, vars[Var.PROBA_DROP]);
    if (isDropped) {
      return;
    } else {
      uint id = _mintGum(isGenesis, size, flavor, intensity, msg.sender);
      emit Join(_a, _b, id);
    }
  }
}