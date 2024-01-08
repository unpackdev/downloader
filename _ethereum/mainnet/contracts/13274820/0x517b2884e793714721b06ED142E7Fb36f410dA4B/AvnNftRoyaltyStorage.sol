// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IAvnNftRoyaltyStorage.sol";
import "./Owned.sol";

contract AvnNftRoyaltyStorage is IAvnNftRoyaltyStorage, Owned {

  uint32 constant private ONE_MILLION = 1000000;

  mapping (address => bool) public isPermitted;
  mapping (uint256 => uint256) private royaltiesId;
  mapping (uint256 => Royalty[]) private royalties;
  uint256 private rId;

  modifier onlyPermitted() {
    require(isPermitted[msg.sender], "Access not permitted");
    _;
  }

  function setPermission(address _partnerContract, bool _status)
    onlyOwner
    external
    override
  {
    isPermitted[_partnerContract] = _status;
    emit LogPermissionUpdated(_partnerContract, _status);
  }

  function setRoyaltyId(uint256 _batchId, uint256 _nftId)
    onlyPermitted
    external
    override
  {
    royaltiesId[_nftId] = royaltiesId[_batchId];
  }

  function setRoyalties(uint256 _id, Royalty[] calldata _royalties)
    onlyPermitted
    external
    override
  {
    if (royaltiesId[_id] != 0) return;

    royaltiesId[_id] = ++rId;

    uint64 totalRoyalties;

    for (uint256 i = 0; i < _royalties.length; i++) {
      if (_royalties[i].recipient != address(0) && _royalties[i].partsPerMil != 0) {
        totalRoyalties += _royalties[i].partsPerMil;
        require(totalRoyalties <= ONE_MILLION, "Royalties too high");
        royalties[rId].push(_royalties[i]);
      }
    }
  }

  function getRoyalties(uint256 _id)
    external
    view
    override
    returns(Royalty[] memory)
  {
    return royalties[royaltiesId[_id]];
  }
}