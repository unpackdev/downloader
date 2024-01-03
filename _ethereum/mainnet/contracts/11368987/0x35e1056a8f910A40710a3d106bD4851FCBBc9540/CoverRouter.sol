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
 * @author crypto-pumpkin@github + Kiwi
 */
contract CoverRouter is ICoverRouter, Ownable, Rollover {
  using SafeERC20 for IERC20;
  using SafeERC20 for IBPool;
  using SafeMath for uint256;

  address public protocolFactory;
  IBFactory public bFactory;

  uint256 public constant TOTAL_WEIGHT = 50 ether;
  uint256 public claimCovTokenWeight = 40 ether;
  uint256 public noclaimCovTokenWeight = 49 ether;
  uint256 public claimSwapFee = 0.01 ether;
  uint256 public noclaimSwapFee = 0.01 ether;

  mapping(bytes32 => address) private pools;

  event PoolSet(address indexed covtoken, address indexed pairedToken, address indexed poolAddr);

  constructor(address _protocolFactory, IBFactory _bFactory) Ownable() {
    protocolFactory = _protocolFactory;
    bFactory = _bFactory;
  }

  function poolForPair(address _covToken, address _pairedToken) external override view returns (address) {
    bytes32 pairKey = _pairKeyForPair(_covToken, _pairedToken);
    return pools[pairKey];
  }

  /// @dev add buffer support (1%) as suggested by balancer doc to help get tx through. https://docs.balancer.finance/smart-contracts/core-contracts/api#joinpool
  function provideLiquidity(
    address _covToken,
    uint256 _covTokenAmount,
    address _pairedToken,
    uint256 _pairedTokenAmount,
    bool _addBuffer
  ) external override {
    IERC20 covToken = IERC20(_covToken);
    IERC20 pairedToken = IERC20(_pairedToken);
    require(covToken.balanceOf(msg.sender) >= _covTokenAmount, "CoverRouter: insufficient covToken");
    require(pairedToken.balanceOf(msg.sender) >= _pairedTokenAmount, "CoverRouter: insufficient pairedToken");
    address poolAddr = pools[_pairKeyForPair(_covToken, _pairedToken)];
    require(poolAddr != address(0), "CoverRouter: pool not found");

    IBPool pool = IBPool(poolAddr);
    (uint256 bptAmountOut, uint256[] memory maxAmountsIn) = _getBptAmountOut(pool, _covToken, _covTokenAmount, _pairedToken, _pairedTokenAmount, _addBuffer);

    covToken.safeTransferFrom(msg.sender, address(this), _covTokenAmount);
    pairedToken.safeTransferFrom(msg.sender, address(this), _pairedTokenAmount);
    _approve(covToken, poolAddr, _covTokenAmount);
    _approve(pairedToken, poolAddr, _pairedTokenAmount);
    pool.joinPool(bptAmountOut, maxAmountsIn);

    IERC20 bpt = IERC20(poolAddr);
    bpt.safeTransfer(msg.sender, bpt.balanceOf(address(this)));
    uint256 remainCovToken = covToken.balanceOf(address(this));
    if (remainCovToken > 0) {
      covToken.safeTransfer(msg.sender, remainCovToken);
    }
    uint256 remainPairedToken = pairedToken.balanceOf(address(this));
    if (remainPairedToken > 0) {
      pairedToken.safeTransfer(msg.sender, remainPairedToken);
    }
  }

  function removeLiquidity(
    address _covToken,
    address _pairedToken,
    uint256 _bptAmount
  ) external override {
    require(_bptAmount > 0, "CoverRouter: insufficient covToken");
    bytes32 pairKey = _pairKeyForPair(_covToken, _pairedToken);
    address poolAddr = pools[pairKey];
    require(poolAddr != address(0), "CoverRouter: pool not found");

    uint256[] memory minAmountsOut = new uint256[](2);
    minAmountsOut[0] = 0;
    minAmountsOut[1] = 0;

    IERC20(poolAddr).safeTransferFrom(msg.sender, address(this), _bptAmount);
    IBPool(poolAddr).exitPool(IERC20(poolAddr).balanceOf(address(this)), minAmountsOut);

    IERC20 covToken = IERC20(_covToken);
    IERC20 pairedToken = IERC20(_pairedToken);
    covToken.safeTransfer(msg.sender, covToken.balanceOf(address(this)));
    pairedToken.safeTransfer(msg.sender, pairedToken.balanceOf(address(this)));
  }

  function setPoolForPair(address _covToken, address _pairedToken, address _newPool) public override onlyOwner {
    _validCovToken(_covToken);
    _validBalPoolTokens(_covToken, _pairedToken, IBPool(_newPool));

    bytes32 pairKey = _pairKeyForPair(_covToken, _pairedToken);
    pools[pairKey] = _newPool;
    emit PoolSet(_covToken, _pairedToken, _newPool);
  }

  function createNewPoolForPair(address _covToken, uint256 _covTokenAmount, address _pairedToken, uint256 _pairedTokenAmount) external override returns (address) {
    require(_pairedToken != _covToken, "CoverRouter: same token");
    bytes32 pairKey = _pairKeyForPair(_covToken, _pairedToken);
    require(pools[pairKey] == address(0), "CoverRouter: pool already exists");
    _validCovToken(_covToken);

    // Get the Cover contract from the token to check if its the claim or noclaim.
    ICover cover = ICover(ICoverERC20(_covToken).owner());
    bool isClaimPair = address(cover.claimCovToken()) == _covToken;

    IERC20(_covToken).safeTransferFrom(msg.sender, address(this), _covTokenAmount);
    IERC20(_pairedToken).safeTransferFrom(msg.sender, address(this), _pairedTokenAmount);
    address pool = _createBalPool(_covToken, _pairedToken, _covTokenAmount, _pairedTokenAmount, isClaimPair);

    pools[pairKey] = pool;
    emit PoolSet(_covToken, _pairedToken, pool);
    return pool;
  }

  function setPoolsForPairs(address[] memory _covTokens, address[] memory _pairedTokens, address[] memory _newPools) external override onlyOwner {
    require(_covTokens.length == _pairedTokens.length, "CoverRouter: Paired tokens length not equal");
    require(_covTokens.length == _newPools.length, "CoverRouter: Pools length not equal");

    for (uint256 i = 0; i < _covTokens.length; i++) {
      setPoolForPair(_covTokens[i], _pairedTokens[i], _newPools[i]);
    }
  }

  function setSwapFee(uint256 _claimSwapFees, uint256 _noclaimSwapFees) external override onlyOwner {
    require(_claimSwapFees > 0 && _noclaimSwapFees > 0, "CoverRouter: invalid fees");
    claimSwapFee = _claimSwapFees;
    noclaimSwapFee = _noclaimSwapFees;
  }

  function setCovTokenWeights(uint256 _claimCovTokenWeight, uint256 _noclaimCovTokenWeight) external override onlyOwner {
    require(_claimCovTokenWeight < TOTAL_WEIGHT, "CoverRouter: invalid claim weight");
    require(_noclaimCovTokenWeight < TOTAL_WEIGHT, "CoverRouter: invalid noclaim weight");
    claimCovTokenWeight = _claimCovTokenWeight;
    noclaimCovTokenWeight = _noclaimCovTokenWeight;
  }

  function _pairKeyForPair(address _covToken, address _pairedToken) internal view returns (bytes32) {
    (address token0, address token1) = _covToken < _pairedToken ? (_covToken, _pairedToken) : (_pairedToken, _covToken);
    bytes32 pairKey = keccak256(abi.encodePacked(
      protocolFactory,
      token0,
      token1
    ));
    return pairKey;
  }

  /// @notice make covToken is from Cover Protocol Factory
  function _validCovToken(address _covToken) private view {
    require(_covToken != address(0), "CoverRouter: covToken is 0 address");

    ICover cover = ICover(ICoverERC20(_covToken).owner());
    address tokenProtocolFactory = IProtocol(cover.owner()).owner();
    require(tokenProtocolFactory == protocolFactory, "CoverRouter: wrong factory");
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

  function _validBalPoolTokens(address _covToken, address _pairedToken, IBPool _pool) private view {
    require(_pairedToken != _covToken, "CoverRouter: same token");
    address[] memory tokens = _pool.getFinalTokens();
    require(tokens.length == 2, "CoverRouter: Too many tokens in pool");
    require((_covToken == tokens[0] && _pairedToken == tokens[1]) || (_pairedToken == tokens[0] && _covToken == tokens[1]), "CoverRouter: tokens don't match");
  }

  function _createBalPool(address _covToken, address _pairedToken, uint256 _covTokenAmount, uint256 _pairedTokenAmount, bool _isClaimPair) private returns (address _poolAddr) {
    IBPool pool = bFactory.newBPool();
    _poolAddr = address(pool);
    uint256 _covTokenSwapFee = _isClaimPair ? claimSwapFee : noclaimSwapFee;
    pool.setSwapFee(_covTokenSwapFee);

    uint256 _covTokenWeight = _isClaimPair ? claimCovTokenWeight : noclaimCovTokenWeight;
    _approve(IERC20(_covToken), _poolAddr, _covTokenAmount);
    pool.bind(_covToken, _covTokenAmount, _covTokenWeight);
    _approve(IERC20(_pairedToken), _poolAddr, _pairedTokenAmount);
    pool.bind(_pairedToken, _pairedTokenAmount, TOTAL_WEIGHT.sub(_covTokenWeight));

    pool.finalize();
    pool.setController(address(0)); // We burn controller since it's useless after finalizing.
    uint256 bptBal = pool.balanceOf(address(this));
    pool.safeTransfer(msg.sender, bptBal);
  }
}