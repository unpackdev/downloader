// SPDX-License-Identifier: None
pragma solidity ^0.7.5;

import "./ICover.sol";
import "./ICoverERC20.sol";
import "./IERC20.sol";
import "./IProtocol.sol";

/**
 * @title CoverRouter interface
 * @author crypto-pumpkin@github
 */
interface ICoverRouter {
  event PoolUpdate(address indexed covtoken, address indexed pairedToken, address indexed poolAddr);
  event AddLiquidity(address indexed account, address indexed poolAddr);
  event RemoveLiquidity(address indexed account, address indexed poolAddr);

  function poolForPair(address _covToken, address _pairedToken) external view returns (address);

  /// @notice _covTokenAmount + _pairedTokenAmount + XCovTokenWeight will set the initial price for the covToken
  function createNewPool(ICoverERC20 _covToken, uint256 _covAmount, IERC20 _pairedToken, uint256 _pairedAmount) external returns (address);
  /// @notice add double sided liquidity, there maybe token left after add liquidity
  function addLiquidity(ICoverERC20 _covToken,uint256 _covTokenAmount, IERC20 _pairedToken, uint256 _pairedTokenAmount, bool _addBuffer) external;
  function removeLiquidity(ICoverERC20 _covToken, IERC20 _pairedToken, uint256 _btpAmount) external;

  function addCoverAndAddLiquidity(
    IProtocol _protocol,
    IERC20 _collateral,
    uint48 _timestamp,
    uint256 _amount,
    IERC20 _pairedToken,
    uint256 _claimPairedTokenAmount,
    uint256 _noclaimPairedTokenAmount,
    bool _addBuffer
  ) external;
  function rolloverAndAddLiquidity(
    ICover _cover,
    uint48 _newTimestamp,
    IERC20 _pairedToken,
    uint256 _claimPairedTokenAmount,
    uint256 _noclaimPairedTokenAmount,
    bool _addBuffer
  ) external;

  // owner only
  function setPoolForPair(address _covToken, address _pairedToken, address _newPool) external;
  function setPoolsForPairs(address[] memory _covTokens, address[] memory _pairedTokens, address[] memory _newPools) external;
  function setCovTokenWeights(uint256 _claimCovTokenWeight, uint256 _noclaimCovTokenWeight) external;
  function setSwapFee(uint256 _claimSwapFees, uint256 _noclaimSwapFees) external;
}