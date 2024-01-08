// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./BubbleGumRoll.sol";
import "./BubbleGumMeta.sol";

contract BubbleGumController is Ownable, Pausable, BubbleGumMeta {
  constructor(string memory _name, string memory _symbol, uint _launchAt) BubbleGumMeta(_name, _symbol, _launchAt) {}

  modifier onlyTokenOwner(uint _id) {
    require(ownerOf(_id) == msg.sender, "Unauthorized.");
    _;
  }

  modifier onlyStakeOwner(uint _id) {
    require(stakeOwners[_id] == msg.sender, "Unauthorized.");
    _;
  }

  function adminSetJuicy(address _address) external onlyOwner { _juicy = IJuicy(_address); }

  function adminSetVar(Var _key, uint _val) external onlyOwner { vars[_key] = _val; }

  function adminWipeGenesisJuice() public onlyOwner {
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "Unable to remove remaining funds.");
  }
}