//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IKaratDistributor.sol";

contract KaratFactory {
  mapping(address => mapping(uint256 => address)) public airdropMap;
  mapping(address => uint256) public campaignNumByCreator;
  address[] public allCampaigns;

  function allCampaignsLength() external view returns (uint256) {
    return allCampaigns.length;
  }

  function getAllCampaigns() external view returns (address[] memory) {
    return allCampaigns;
  }

  function getAllCampaignsPaginated(uint256 _start, uint256 _length)
    external
    view
    returns (address[] memory)
  {
    uint256 length = _length;
    if (length > allCampaigns.length - _start) {
      length = allCampaigns.length - _start;
    }
    address[] memory array = new address[](length);

    for (uint256 i = 0; i < length; i++) {
      array[i] = allCampaigns[_start + i];
    }
    return array;
  }

  function getAllCampaignsByStatus(bool _isActive)
    external
    view
    returns (address[] memory)
  {
    uint256 length = allCampaigns.length;
    address[] memory array = new address[](length);
    for (uint256 i = 0; i < allCampaigns.length; i++) {
      IKaratDistributor campaign = IKaratDistributor(allCampaigns[i]);
      if (campaign.isActive() == _isActive) {
        array[i] = allCampaigns[i];
      }
    }
    return array;
  }

  function getAllCampaignsPaginatedByStatus(
    bool _isActive,
    uint256 _start,
    uint256 _length
  ) external view returns (address[] memory) {
    uint256 length = _length;
    if (length > allCampaigns.length - _start) {
      length = allCampaigns.length - _start;
    }
    address[] memory array = new address[](length);

    for (uint256 i = 0; i < length; i++) {
      IKaratDistributor campaign = IKaratDistributor(allCampaigns[_start + i]);
      if (campaign.isActive() == _isActive) {
        array[i] = allCampaigns[_start + i];
      }
    }
    return array;
  }

  function getRecentCampaign(address _creator) external view returns (address) {
    uint256 index = campaignNumByCreator[_creator] == 0
      ? 0
      : (campaignNumByCreator[_creator] - 1);
    return airdropMap[_creator][index];
  }

  function getCampaignsByCreator(address _creator)
    external
    view
    returns (address[] memory)
  {
    uint256 length = campaignNumByCreator[_creator];
    address[] memory res = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      res[i] = airdropMap[_creator][i];
    }
    return res;
  }
}
