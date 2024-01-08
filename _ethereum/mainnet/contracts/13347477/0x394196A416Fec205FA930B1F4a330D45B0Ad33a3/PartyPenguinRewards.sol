// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract PartyPenguins {
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract PartyPenguinRewards is Ownable {
  uint256 private _share = 42 * 10**14; //0.0042 ETH;
  bool public _claimActive = false;
  uint256 public _totalClaimCount = 0;

  mapping(address => uint256) public _maxClaimablePerAddress;
  PartyPenguins private pp = PartyPenguins(0x31F3bba9b71cB1D5e96cD62F0bA3958C034b55E9);

  function _claimableItemCount(address _inputAddress) public view returns(uint256) {
    return _maxClaimablePerAddress[_inputAddress];
  }

  function claim() public {
    if(msg.sender != owner()) {
      require(_claimActive, "Claim is not Active, wait for your turn");
    }

    uint256 _maxClaimCount = _claimableItemCount(msg.sender);
    uint tokenCount = pp.balanceOf(msg.sender);

    if (tokenCount < _maxClaimCount){
      _maxClaimCount = tokenCount;
    }

    require (_maxClaimCount > 0, "You have claimed rewards or were not eligible");

    _totalClaimCount += _maxClaimCount;
    _maxClaimablePerAddress[msg.sender] = 0;
    require(payable(msg.sender).send(_maxClaimCount * _share), "Claim payout failed");
  }

  function setclaimBool(bool val) public onlyOwner {
    _claimActive = val;
  }

  function setmaxClaimablePerAddress(address[] memory _addresses, uint256[] memory _nums, uint256 _val) public onlyOwner {
    for(uint256 i; i < _addresses.length ; i++){
      _maxClaimablePerAddress[_addresses[i]] = (_val == 0  ? _nums[i] : _val );
    }
  }

  function setShare(uint256 _newShare) public onlyOwner() {
      _share = _newShare;
  }

  function receiveTotalRewards() public payable {}

  function withdrawAll() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}