// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ICHNOPS {
  // READ ONLY methods
  function tokenURIForStage(uint256 _tokenId, uint256 _gen) external view returns (string memory);
  function totalMinted() external view returns (uint256);
  function maxMintAmountPerWallet() external view returns (uint256);
  function maxSupply() external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function paused() external view returns (bool);
  function tokenStage(uint256 _tokenId) external view returns (uint256);  
  function tokensClaimed(address _address) external view returns (uint256); 
  function revealedStage() external view returns (uint256);
  function allowListCost() external view returns (uint256);
  function maxAllowlistSupply() external view returns (uint256);
  function allowlistTokenCnt() external view returns (uint256);
  function publicSaleCost() external view returns (uint256);
  function maxPublicSaleSupply() external view returns (uint256);
  function publicSaleTokenCnt() external view returns (uint256);
  function allowlistMintEnabled() external view returns (bool);
  function publicSaleEnabled() external view returns (bool);
  function sideCarsEnabled() external view returns (bool);
}
