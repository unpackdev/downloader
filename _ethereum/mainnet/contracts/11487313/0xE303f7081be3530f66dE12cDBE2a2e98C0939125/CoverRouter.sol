// SPDX-License-Identifier: None
pragma solidity ^0.7.5;

import "./IBFactory.sol";
import "./IBPool.sol";
import "./ICover.sol";
import "./ICoverERC20.sol";
import "./ICoverRouter.sol";
import "./IERC20.sol";
import "./IProtocol.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Rollover.sol";

/**
 * @title CoverRouter for Cover Protocol, handles balancer activities
 * @author crypto-pumpkin@github
 */
contract CoverRouter is ICoverRouter, Ownable, Rollover {
  using SafeERC20 for IBPool;
  using SafeERC20 for ICoverERC20;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  event SwapFeeUpdate(uint256 _oldClaimSwapFee, uint256 _oldNoclaimSwapFee, uint256 _newClaimSwapFee, uint256 _newNoclaimSwapFee);
  event CovTokenWeightsUpdate(uint256 _oldClaimWeight, uint256 _oldNoclaimWeight, uint256 _newClaimWeight, uint256 _newNoclaimWeight);

  IBFactory public bFactory;
  uint256 public constant TOTAL_WEIGHT = 50 ether;
  uint256 public claimCovTokenWeight = 40 ether;
  uint256 public noclaimCovTokenWeight = 49 ether;
  uint256 public claimSwapFee = 0.03 ether;
  uint256 public noclaimSwapFee = 0.01 ether;
  mapping(bytes32 => address) private pools;

  constructor(address _protocolFactory, IBFactory _bFactory) Rollover(_protocolFactory) {
    require(address(_bFactory) != address(0), "CoverRouter: bFactory is 0");
    bFactory = _bFactory;
  }

  function poolForPair(address _covToken, address _pairedToken) external override view returns (address) {
    bytes32 pairKey = _pairKeyForPair(_covToken, _pairedToken);
    return pools[pairKey];
  }

  /**
   * @notice mint cover token and add liquidity into the balancer pools
   * Capped by amount, claim and noclaim pairedToken amount
   */
  function addCoverAndAddLiquidity(
    IProtocol _protocol,
    IERC20 _collateral,
    uint48 _timestamp,
    uint256 _amount,
    IERC20 _pairedToken,
    uint256 _claimPTAmt,
    uint256 _noclaimPTAmt,
    bool _addBuffer
  ) external override {
    _validateProtocolLegitimacy(_protocol);
    require(_amount > 0 && _claimPTAmt > 0 && _noclaimPTAmt > 0, "CoverRouter: amount is 0");
    _collateral.safeTransferFrom(msg.sender, address(this), _amount);
    _addCover(_protocol, address(_collateral), _timestamp, _collateral.balanceOf(address(this)));

    ICover cover = ICover(_protocol.coverMap(address(_collateral), _timestamp));
    _addLiquidityForCover(msg.sender, cover, _pairedToken, _claimPTAmt, _noclaimPTAmt, _addBuffer);
  }

  /**
   * @notice rollover coverage and add liquidity for a different account (from sender), covTokens have to be in account already
   * Can only rollover to a future expiry once, expiries have to be in the Cover Protocol. Otherwise, will revert
   */
  function rolloverAndAddLiquidityForAccount(
    address _account,
    ICover _cover,
    uint48 _newTimestamp,
    IERC20 _pairedToken,
    uint256 _claimPTAmt,
    uint256 _noclaimPTAmt,
    bool _addBuffer
  ) public override {
    _rolloverAccount(_account, address(_cover), _newTimestamp, false);

    // if has not reverted, gurranteed protocol is from Cover Protocol
    IProtocol protocol = IProtocol(_cover.owner());

    ICover newCover = ICover(protocol.coverMap(_cover.collateral(), _newTimestamp));
    _addLiquidityForCover(_account, newCover, _pairedToken, _claimPTAmt, _noclaimPTAmt, _addBuffer);
  }

  /// @notice rollover for self
  function rolloverAndAddLiquidity(
    ICover _cover,
    uint48 _newTimestamp,
    IERC20 _pairedToken,
    uint256 _claimPTAmt,
    uint256 _noclaimPTAmt,
    bool _addBuffer
  ) external override {
    rolloverAndAddLiquidityForAccount(msg.sender, _cover, _newTimestamp, _pairedToken, _claimPTAmt, _noclaimPTAmt, _addBuffer);
  }

  /// @notice remove liquidity for a covToken and transfer tokens back to sender
  function removeLiquidity(ICoverERC20 _covToken, IERC20 _pairedToken, uint256 _bptAmount) external override {
    require(_bptAmount > 0, "CoverRouter: insufficient covToken");
    bytes32 pairKey = _pairKeyForPair(address(_covToken), address(_pairedToken));
    IBPool pool = IBPool(pools[pairKey]);
    require(pool.balanceOf(msg.sender) >= _bptAmount, "CoverRouter: insufficient BPT");

    uint256[] memory minAmountsOut = new uint256[](2);
    minAmountsOut[0] = 0;
    minAmountsOut[1] = 0;

    pool.safeTransferFrom(msg.sender, address(this), _bptAmount);
    pool.exitPool(pool.balanceOf(address(this)), minAmountsOut);

    _covToken.safeTransfer(msg.sender, _covToken.balanceOf(address(this)));
    _pairedToken.safeTransfer(msg.sender, _pairedToken.balanceOf(address(this)));
    emit RemoveLiquidity(msg.sender, address(pool));
  }

  /// @notice add double sided liquidity, there maybe tokens left after
  function addLiquidity(
    ICoverERC20 _covToken,
    uint256 _covTokenAmount,
    IERC20 _pairedToken,
    uint256 _pairedTokenAmount,
    bool _addBuffer
  ) external override {
    require(_covToken.balanceOf(msg.sender) >= _covTokenAmount, "CoverRouter: insufficient covToken");
    require(_pairedToken.balanceOf(msg.sender) >= _pairedTokenAmount, "CoverRouter: insufficient pairedToken");

    _covToken.safeTransferFrom(msg.sender, address(this), _covTokenAmount);
    _pairedToken.safeTransferFrom(msg.sender, address(this), _pairedTokenAmount);
    _joinPoolAndTransferRemCovToken(msg.sender, _covToken, _pairedToken, _pairedToken.balanceOf(address(this)), _addBuffer);
    _transferRem(msg.sender, _pairedToken);
  }

  function createNewPool(
    ICoverERC20 _covToken,
    uint256 _covTokenAmount,
    IERC20 _pairedToken,
    uint256 _pairedTokenAmount
  ) external override returns (address pool) {
    require(address(_pairedToken) != address(_covToken), "CoverRouter: same token");
    bytes32 pairKey = _pairKeyForPair(address(_covToken), address(_pairedToken));
    require(pools[pairKey] == address(0), "CoverRouter: pool already exists");
    _validCovToken(address(_covToken));

    // Get the Cover contract from the token to check if its the claim or noclaim.
    ICover cover = ICover(ICoverERC20(_covToken).owner());
    bool isClaimPair = cover.claimCovToken() == _covToken;

    _covToken.safeTransferFrom(msg.sender, address(this), _covTokenAmount);
    _pairedToken.safeTransferFrom(msg.sender, address(this), _pairedTokenAmount);
    pool = _createBalPoolAndTransferBpt(msg.sender, _covToken, _pairedToken, _pairedToken.balanceOf(address(this)), isClaimPair);
    pools[pairKey] = pool;
    _transferRem(msg.sender, _pairedToken);
    _transferRem(msg.sender, _covToken);
  }

  function setSwapFee(uint256 _claimSwapFee, uint256 _noclaimSwapFee) external override onlyOwner {
    require(_claimSwapFee > 0 && _noclaimSwapFee > 0, "CoverRouter: invalid fees");
    emit SwapFeeUpdate(claimSwapFee, noclaimSwapFee, _claimSwapFee, _noclaimSwapFee);
    claimSwapFee = _claimSwapFee;
    noclaimSwapFee = _noclaimSwapFee;
  }

  function setCovTokenWeights(uint256 _claimCovTokenWeight, uint256 _noclaimCovTokenWeight) external override onlyOwner {
    require(_claimCovTokenWeight < TOTAL_WEIGHT, "CoverRouter: invalid claim weight");
    require(_noclaimCovTokenWeight < TOTAL_WEIGHT, "CoverRouter: invalid noclaim weight");
    emit CovTokenWeightsUpdate(
      claimCovTokenWeight,
      noclaimCovTokenWeight,
      _claimCovTokenWeight,
      _noclaimCovTokenWeight
    );
    claimCovTokenWeight = _claimCovTokenWeight;
    noclaimCovTokenWeight = _noclaimCovTokenWeight;
  }

  function setPoolForPair(address _covToken, address _pairedToken, address _newPool) public override onlyOwner {
    _validCovToken(_covToken);
    _validBalPoolTokens(_covToken, _pairedToken, IBPool(_newPool));

    bytes32 pairKey = _pairKeyForPair(_covToken, _pairedToken);
    pools[pairKey] = _newPool;
    emit PoolUpdate(_covToken, _pairedToken, _newPool);
  }

  function setPoolsForPairs(address[] memory _covTokens, address[] memory _pairedTokens, address[] memory _newPools) external override onlyOwner {
    require(_covTokens.length == _pairedTokens.length, "CoverRouter: Paired tokens length not equal");
    require(_covTokens.length == _newPools.length, "CoverRouter: Pools length not equal");

    for (uint256 i = 0; i < _covTokens.length; i++) {
      setPoolForPair(_covTokens[i], _pairedTokens[i], _newPools[i]);
    }
  }

  function _pairKeyForPair(address _covToken, address _pairedToken) internal view returns (bytes32 pairKey) {
    (address token0, address token1) = _covToken < _pairedToken ? (_covToken, _pairedToken) : (_pairedToken, _covToken);
    pairKey = keccak256(abi.encodePacked(
      protocolFactory,
      token0,
      token1
    ));
  }

  function _getBptAmountOut(
    IBPool pool,
    address _covToken,
    uint256 _covTokenAmount,
    address _pairedToken,
    uint256 _pairedTokenAmount,
    bool _addBuffer
  ) internal view returns (uint256 bptAmountOut, uint256[] memory maxAmountsIn) {
    uint256 poolAmountOutInCov = _covTokenAmount.mul(pool.totalSupply()).div(pool.getBalance(_covToken));
    uint256 poolAmountOutInPaired = _pairedTokenAmount.mul(pool.totalSupply()).div(pool.getBalance(_pairedToken));
    bptAmountOut = poolAmountOutInCov > poolAmountOutInPaired ? poolAmountOutInPaired : poolAmountOutInCov;
    bptAmountOut = _addBuffer ? bptAmountOut.mul(99).div(100) : bptAmountOut;

    address[] memory tokens = pool.getFinalTokens();
    maxAmountsIn = new uint256[](2);
    maxAmountsIn[0] =  _covTokenAmount;
    maxAmountsIn[1] = _pairedTokenAmount;
    if (tokens[1] == _covToken) {
      maxAmountsIn[0] =  _pairedTokenAmount;
      maxAmountsIn[1] = _covTokenAmount;
    }
  }

  /// @notice make covToken is from Cover Protocol Factory
  function _validCovToken(address _covToken) private view {
    require(_covToken != address(0), "CoverRouter: covToken is 0 address");

    ICover cover = ICover(ICoverERC20(_covToken).owner());
    address tokenProtocolFactory = IProtocol(cover.owner()).owner();
    require(tokenProtocolFactory == protocolFactory, "CoverRouter: wrong factory");
  }

  function _validBalPoolTokens(address _covToken, address _pairedToken, IBPool _pool) private view {
    require(_pairedToken != _covToken, "CoverRouter: same token");
    address[] memory tokens = _pool.getFinalTokens();
    require(tokens.length == 2, "CoverRouter: Too many tokens in pool");
    require((_covToken == tokens[0] && _pairedToken == tokens[1]) || (_pairedToken == tokens[0] && _covToken == tokens[1]), "CoverRouter: tokens don't match");
  }

  /// @dev add buffer support (1%) as suggested by balancer doc to help get tx through. https://docs.balancer.finance/smart-contracts/core-contracts/api#joinpool
  function _joinPoolAndTransferRemCovToken(
    address _account,
    IERC20 _covToken,
    IERC20 _pairedToken,
    uint256 _pairedTokenAmount,
    bool _addBuffer
  ) internal {
    address poolAddr = pools[_pairKeyForPair(address(_covToken), address(_pairedToken))];
    require(poolAddr != address(0), "CoverRouter: pool not found");

    IBPool pool = IBPool(poolAddr);
    uint256 covTokenAmount = _covToken.balanceOf(address(this));
    (uint256 bptAmountOut, uint256[] memory maxAmountsIn) = _getBptAmountOut(pool, address(_covToken), covTokenAmount, address(_pairedToken), _pairedTokenAmount, _addBuffer);
    _approve(_covToken, poolAddr, covTokenAmount);
    _approve(_pairedToken, poolAddr, _pairedTokenAmount);
    pool.joinPool(bptAmountOut, maxAmountsIn);

    pool.safeTransfer(_account, pool.balanceOf(address(this)));
    _transferRem(_account, _covToken);
    emit AddLiquidity(_account, poolAddr);
  }

  function _transferRem(address _account, IERC20 token) internal {
    uint256 rem = token.balanceOf(address(this));
    if (rem > 0) {
      token.safeTransfer(_account, rem);
    }
  }

  function _receivePairdTokens(
    address _account,
    IERC20 _pairedToken,
    uint256 _claimPTAmt,
    uint256 _noclaimPTAmt
  ) internal returns (uint256 receivedClaimPTAmt, uint256 receivedNoclaimPTAmt) {
    uint256 total = _claimPTAmt.add(_noclaimPTAmt);
    _pairedToken.safeTransferFrom(_account, address(this), total);
    uint256 bal = _pairedToken.balanceOf(address(this));
    receivedClaimPTAmt = bal.mul(_claimPTAmt).div(total);
    receivedNoclaimPTAmt = bal.mul(_noclaimPTAmt).div(total);
  }

  function _addLiquidityForCover(
    address _account,
    ICover _cover,
    IERC20 _pairedToken,
    uint256 _claimPTAmt,
    uint256 _noclaimPTAmt,
    bool _addBuffer
  ) private {
    IERC20 claimCovToken = _cover.claimCovToken();
    IERC20 noclaimCovToken = _cover.noclaimCovToken();
    (uint256 claimPTAmt, uint256 noclaimPTAmt) =  _receivePairdTokens(_account, _pairedToken, _claimPTAmt, _noclaimPTAmt);

    _joinPoolAndTransferRemCovToken(_account, claimCovToken, _pairedToken, claimPTAmt, _addBuffer);
    _joinPoolAndTransferRemCovToken(_account, noclaimCovToken, _pairedToken, noclaimPTAmt, _addBuffer);
    _transferRem(_account, _pairedToken);
  }

  function _createBalPoolAndTransferBpt(
    address _account,
    IERC20 _covToken,
    IERC20 _pairedToken,
    uint256 _pairedTokenAmount,
    bool _isClaimPair
  ) private returns (address poolAddr) {
    IBPool pool = bFactory.newBPool();
    poolAddr = address(pool);

    uint256 _covTokenSwapFee = claimSwapFee;
    uint256 _covTokenWeight = claimCovTokenWeight;
    if (!_isClaimPair) {
      _covTokenSwapFee = noclaimSwapFee;
      _covTokenWeight = noclaimCovTokenWeight;
    }
    pool.setSwapFee(_covTokenSwapFee);
    uint256 covTokenAmount = _covToken.balanceOf(address(this));
    _approve(_covToken, poolAddr, covTokenAmount);
    pool.bind(address(_covToken), covTokenAmount, _covTokenWeight);
    _approve(_pairedToken, poolAddr, _pairedTokenAmount);
    pool.bind(address(_pairedToken), _pairedTokenAmount, TOTAL_WEIGHT.sub(_covTokenWeight));

    pool.finalize();
    emit PoolUpdate(address(_covToken), address(_pairedToken), poolAddr);
    pool.safeTransfer(_account, pool.balanceOf(address(this)));
  }
}