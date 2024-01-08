// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Counters.sol";
import "./BubbleGumRoll.sol";
import "./BubbleGumController.sol";

contract BubbleGumStore is BubbleGumRoll, BubbleGumController {
  using Counters for Counters.Counter;

  constructor(string memory _name, string memory _symbol, uint _launchAt) BubbleGumController(_name, _symbol, _launchAt) {}

  function _rollGenesisOwner(uint _id) private view returns (address) {
    uint rndIdx = _rnd("genesis", _id) % totalGenesis;
    uint id = genesis[rndIdx];
    address owner = ownerOf(id);

    return owner == address(this) ? stakeOwners[id] : owner;
  }

  function _mintGum(
    bool _isGenesis,
    uint _size,
    uint8 _flavor,
    uint _intensity,
    address _recipient
  ) internal returns (uint) {
    _ids.increment();
    uint id = _ids.current();

    Meta memory bubbleGum;
    bubbleGum.size = _size;
    bubbleGum.flavor = _flavor;
    bubbleGum.intensity = _intensity;
    bubbleGum.isGenesis = _isGenesis;
    meta[id] = bubbleGum;

    if (_isGenesis) {
      _genesisIdx[id] = totalGenesis;
      genesis[totalGenesis] = id;
      totalGenesis++;
    }
    _mint(_recipient, id);

    return id;
  }

  function mint(bool _isGenesis, uint _maxJuicy) whenNotPaused external payable returns (uint) {
    require(block.timestamp > launchAt, "Hasn't launched.");

    if (_isGenesis) {
      require(totalSupply() < vars[Var.TOTAL_GENESIS], "Max supply.");
      require(msg.value >= vars[Var.FEE_GENESIS], "Requires fee.");
    } else {
      uint fee = _juicy.totalSupply() * 1000 / (vars[Var.TARGET_SUPPLY] - totalSupply());
      require(_maxJuicy == 0 || fee <= _maxJuicy, "Price slipped.");
      _juicy.burn(msg.sender, fee);
    }

    uint8 flavor = uint8(2 ** (_rnd("flavor", _ids.current()) % 8));
    bool isShared = _roll("mint", _ids.current(), vars[Var.PROBA_SHARE]);
    address recipient = totalGenesis > 0 ? _rollGenesisOwner(_ids.current()) : msg.sender;

    return _mintGum(_isGenesis, 1, flavor, 1, (_isGenesis || !isShared) ? msg.sender : recipient);
  }
}