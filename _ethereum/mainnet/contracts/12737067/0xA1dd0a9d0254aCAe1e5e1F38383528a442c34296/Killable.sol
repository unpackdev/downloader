pragma solidity ^0.5.0;

import "./Ownable.sol";

// TODO: write comments

contract Killable is Ownable {
  bool private _immortal;

  event Immortality(bool immortal);

  constructor() public Ownable() {

  }

  modifier onlyMortal() {
    require(isOwner(), "Ownable: caller is not the owner");
    require(!isImmortal(), "Killable: contract is Immortal!");
    _;
  }

  function isImmortal() public view returns (bool) {
    return _immortal;
  }

  function makeImmortal() public onlyMortal {
    _immortal = true;
    emit Immortality(true);
  }

  function _suicide() external onlyMortal {
    selfdestruct(msg.sender);
  }
}
