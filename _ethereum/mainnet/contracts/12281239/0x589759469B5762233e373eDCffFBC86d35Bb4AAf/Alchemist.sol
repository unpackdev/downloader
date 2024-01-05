// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IAlchemist.sol";
import "./BGLDToken.sol";

contract Alchemist is Ownable, IAlchemist {
  using SafeMath for uint256;

  struct Allocation {
    address minter;
    uint256 total;
    uint256 minted;
    bool revoked;
  }

  BGLDToken public bgldToken;
  mapping(address => Allocation) public minters;

  constructor(BGLDToken _bgldToken) public {
    bgldToken = _bgldToken;
  }

  function addMinter(address _minter, uint256 _total) public onlyOwner {
    require(_minter!=address(0), "addMinter: invalid minter");
    require(_total>0, "addMinter: invalid total");
    require(minters[_minter].minter==address(0), "addMinter: duplicate minter");

    minters[_minter] = Allocation(_minter, _total, 0, false);
  }

  function revokeMinter(address _minter) public onlyOwner {
    require(minters[_minter].minter!=address(0), "revokeMinter: invalid minter");
    minters[_minter].revoked = true;
  }

  // Returns false if amount is invalid or minter is revoked
  function mintGold(address _to, uint256 _amount) external override returns (bool) {
    Allocation storage allocation = minters[msg.sender];
    require(allocation.minter!=address(0), "mintGold: invalid minter");
    if (_amount>0) {
      if (!allocation.revoked) {
        uint256 minted = allocation.minted.add(_amount);
        if (minted <= allocation.total) {
          allocation.minted = minted;
          bgldToken.mint(_to, _amount);
          return true;
        }
      }
    }
    return false;
  }

  function updateTokenOwner(address newTokenOwner) public onlyOwner {
    bgldToken.transferOwnership(newTokenOwner);
  }
}