//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./NFTAirdropDistributor.sol";
import "./KaratFactory.sol";

// import "./console.sol";

contract NFTAirdropFactory is KaratFactory {
  event NFTAirdropCreated(
    address indexed creator,
    string indexed name,
    address indexed airdropAddr,
    bytes32 merkleRoot,
    uint256 reach,
    uint256 maxSupply,
    string baseInfoURI,
    string frozenInfoURI
  );

  function createAirdrop(
    string calldata name,
    bytes32 merkleRoot,
    uint256 reach,
    uint256 maxSupply,
    string calldata baseInfoURI,
    string calldata frozenInfoURI
  ) external returns (address newAirdropAddr) {
    uint256 index = campaignNumByCreator[msg.sender];
    NFTAirdropDistributor nftAirdropDistributor = new NFTAirdropDistributor(
      name,
      msg.sender,
      merkleRoot,
      reach,
      maxSupply,
      baseInfoURI,
      frozenInfoURI
    );
    newAirdropAddr = address(nftAirdropDistributor);
    airdropMap[msg.sender][index] = newAirdropAddr;
    allCampaigns.push(newAirdropAddr);
    campaignNumByCreator[msg.sender] = campaignNumByCreator[msg.sender] + 1;

    emit NFTAirdropCreated(
      msg.sender,
      name,
      newAirdropAddr,
      merkleRoot,
      reach,
      maxSupply,
      baseInfoURI,
      frozenInfoURI
    );
  }
}
