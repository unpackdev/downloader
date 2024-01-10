// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.11;

interface IClans {
  function stake(
    address contractAddress,
    uint256[] memory tokenIds,
    uint256 clanId
  ) external;

  function claim(
    uint256 oxgnTokenClaim,
    uint256 oxgnTokenDonate,
    uint256 clanTokenClaim,
    address benificiaryOfTax,
    uint256 oxgnTokenTax,
    uint256 timestamp,
    bytes calldata signature
  ) external;

  function mint(
    address recipient,
    uint256 id,
    uint256 amount
  ) external;

  function burn(uint256 id, uint256 amount) external;

  function getAccountsInClan(uint256 clanId) external view returns (address[] memory);

  function getClanRecords(uint256 clanId) external view returns (address[] memory entity, uint256[] memory updateClanTimestamp);

  function isClanLeader(address entityAddress) external view returns (bool);

  function stakedTokensOfOwner(address contractAddress, address owner) external view returns (uint256[] memory);

  function claimableOfOwner(address contractAddress, address owner) external view returns (uint256[] memory stakedTimestamps, uint256[] memory claimableTimestamps);
}
