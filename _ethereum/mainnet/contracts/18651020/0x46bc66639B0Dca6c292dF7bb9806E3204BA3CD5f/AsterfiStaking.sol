//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract AsterFiStaking {
  struct Stake {
    address owner;
    uint256 tokenId;
    uint256 stakedAt;
    uint256 unstakeAvailableAt;
    bool active;
  }

  mapping(address => mapping(uint256 => Stake)) public stakes;
  mapping(address => uint256[]) public stakedNFTs;

  uint256 public stakingPeriod = 12 * 30 days;

  function getStakeInfo(
    address _owner,
    uint256 _tokenId
  ) external view returns (Stake memory) {
    return stakes[_owner][_tokenId];
  }

  function getStakedNFTs(
    address _owner
  ) external view returns (uint256[] memory) {
    return stakedNFTs[_owner];
  }
}
