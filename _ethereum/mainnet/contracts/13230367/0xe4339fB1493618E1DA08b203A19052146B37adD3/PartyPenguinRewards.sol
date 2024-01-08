// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract PartyPenguins {
  function balanceOf(address owner) external virtual view returns (uint256 balance);
  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
}

contract PartyPenguinRewards is Ownable {
  uint256 private _share = 62 * 10**14; //0.0062 ETH;
  bool public _claimActive = false;
  uint256 public _totalClaimCount = 0;

  mapping(uint256 => bool) public _claimedIds;
  mapping(address => uint256) public _maxClaimablePerAddress;

  struct UnclaimedItems {
      uint unclaimedItemCount;
      uint256[] unclaimedItemIds;
  }

  PartyPenguins private pp = PartyPenguins(0x31F3bba9b71cB1D5e96cD62F0bA3958C034b55E9);

  function _claimableItemCount(address _inputAddress) public view returns(uint256) {
    return _maxClaimablePerAddress[_inputAddress];
  }

  function _unclaimedItemIds(address _inputAddress) public view returns(UnclaimedItems memory) {
    uint tokenCount = pp.balanceOf(_inputAddress);

    UnclaimedItems memory result = UnclaimedItems(0, new uint256[](tokenCount));
    for(uint256 i; i < tokenCount; i++){
        uint tokenId = pp.tokenOfOwnerByIndex(_inputAddress, i);
        if (_claimedIds[tokenId] == false) {
            result.unclaimedItemIds[result.unclaimedItemCount] = tokenId;
            result.unclaimedItemCount +=1;
        }
      }
    return result;
  }

  function claim() public {
    if(msg.sender != owner()) {
      require(_claimActive, "Claim is not Active, wait for your turn");
    }

    uint256 _maxClaimCount = _claimableItemCount(msg.sender);
    UnclaimedItems memory uc_items = _unclaimedItemIds(msg.sender);

    if (uc_items.unclaimedItemCount < _maxClaimCount){
      _maxClaimCount = uc_items.unclaimedItemCount;
    }

    require (_maxClaimCount > 0, "You have claimed rewards or were not eligible");

    for(uint256 i; i < _maxClaimCount; i++) {
      _claimedIds[uc_items.unclaimedItemIds[i]] = true;
    }

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