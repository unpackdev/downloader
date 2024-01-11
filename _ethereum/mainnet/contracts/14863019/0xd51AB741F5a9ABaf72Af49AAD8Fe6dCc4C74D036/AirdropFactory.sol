//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AirdropDistributor.sol";
import "./KaratFactory.sol";
import "./console.sol";

contract AirdropFactory is KaratFactory {
  event AirdropCreated(
    address indexed creator,
    string indexed name,
    address indexed token,
    address airdropAddr,
    bytes32 merkleRoot,
    uint256 reach,
    string baseInfo,
    string frozenInfo
  );

  function createAirdrop(
    string calldata name,
    address token,
    bytes32 merkleRoot,
    uint256 reach,
    string calldata baseInfo,
    string calldata frozenInfo
  ) external returns (address newAirdropAddr) {
    uint256 index = campaignNumByCreator[msg.sender];
    AirdropDistributor airdropDistributor = new AirdropDistributor(
      name,
      msg.sender,
      token,
      merkleRoot,
      reach,
      baseInfo,
      frozenInfo
    );
    newAirdropAddr = address(airdropDistributor);
    airdropMap[msg.sender][index] = newAirdropAddr;
    allCampaigns.push(newAirdropAddr);
    campaignNumByCreator[msg.sender] = campaignNumByCreator[msg.sender] + 1;

    emit AirdropCreated(
      msg.sender,
      name,
      token,
      newAirdropAddr,
      merkleRoot,
      reach,
      baseInfo,
      frozenInfo
    );
  }
}
