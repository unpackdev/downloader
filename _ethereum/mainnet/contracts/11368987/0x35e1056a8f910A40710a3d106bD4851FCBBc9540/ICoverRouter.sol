// SPDX-License-Identifier: None
pragma solidity ^0.7.5;

/**
 * @title CoverRouter interface
 * @author crypto-pumpkin@github
 */
interface ICoverRouter {
  function poolForPair(address _covToken, address _pairedToken) external view returns (address);

  function createNewPoolForPair(address _covToken, uint256 _covAmount, address _pairedToken, uint256 _pairedAmount) external returns (address);

  // owner only
  function setPoolForPair(address _covToken, address _pairedToken, address _newPool) external;
  function setPoolsForPairs(address[] memory _covTokens, address[] memory _pairedTokens, address[] memory _newPools) external;
  function setCovTokenWeights(uint256 _claimCovTokenWeight, uint256 _noclaimCovTokenWeight) external;
  function setSwapFee(uint256 _claimSwapFees, uint256 _noclaimSwapFees) external;

  function removeLiquidity(address _covToken, address _pairedToken, uint256 _btpAmount) external;
  function provideLiquidity(
    address _covToken,
    uint256 _covTokenAmount,
    address _pairedToken,
    uint256 _pairedTokenAmount,
    bool _addBuffer
  ) external;
}