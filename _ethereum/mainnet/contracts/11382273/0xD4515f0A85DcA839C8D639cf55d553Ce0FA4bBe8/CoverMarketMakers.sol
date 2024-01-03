// SPDX-License-Identifier: No License

pragma solidity ^0.7.5;

import "./SafeMath.sol";
import "./SafeERC20.sol";

interface IProtocolFactory {
  function getCovTokenAddress(bytes32 _protocolName, uint48 _timestamp, address _collateral, uint256 _claimNonce, bool _isClaimCovToken) external view returns (address);
}

interface IProtocol {
  function name() external view returns (bytes32);
  function claimNonce() external view returns (uint256);
  function addCover(address _collateral, uint48 _timestamp, uint256 _amount)
    external returns (bool);
}

interface IBPool {
    function getBalance(address) external view returns (uint);
    function getNormalizedWeight(address) external view returns (uint);
    function joinPool(uint, uint[] calldata maxAmountsIn) external;
    function exitPool(uint, uint[] calldata minAmountsOut) external;
    function totalSupply() external view returns (uint);
    function getFinalTokens() external view returns (address[] memory tokens);
    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint spotPrice);
    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint spotPrice);
}

interface ICover {
  function redeemCollateral(uint256 _amount) external;
}

contract CoverMarketMakers {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IProtocolFactory public factory;
    IERC20 public daiToken;

    // Initialize, called once
    constructor (IProtocolFactory _factory) {
      factory = _factory;
    }

    // Mint CLAIM / NOCLAIM , deposit CLAIM and NOCLAIM in balancer and return BPTs
    function marketMakerDeposit(
      IProtocol _protocol,
      IBPool _claimPool,
      IBPool _noclaimPool,
      uint48 _expiration,
      uint256 _mintAmount,
      uint256 _collateraLpAmount,
      address _collateral
    ) external {
      IERC20(_collateral).safeTransferFrom(msg.sender, address(this), (_collateraLpAmount.add(_mintAmount)));
      if (IERC20(_collateral).allowance(address(this), address(_protocol)) < (_collateraLpAmount.add(_mintAmount))) {
        IERC20(_collateral).approve(address(_protocol), uint256(-1));
      }
      address noclaimTokenAddr = factory.getCovTokenAddress(_protocol.name(), _expiration, _collateral, _protocol.claimNonce(), false);
      address claimTokenAddr = factory.getCovTokenAddress(_protocol.name(), _expiration, _collateral, _protocol.claimNonce(), true);

      _protocol.addCover(_collateral, _expiration, _mintAmount);
      _provideLiquidity(_claimPool, claimTokenAddr, _mintAmount, _collateral, _collateraLpAmount);
      _provideLiquidity(_noclaimPool, noclaimTokenAddr, _mintAmount, _collateral, _collateraLpAmount);

      uint256 remainCollateral = IERC20(_collateral).balanceOf(address(this));
      if (remainCollateral > 0) {
        IERC20(_collateral).safeTransfer(msg.sender, remainCollateral);
      }
    }

    // Withdraws liquidity from both CLAIM / NOCLAIM pools
    function marketMakerWithdraw(
      IProtocol _protocol,
      address _claimPoolAddr,
      address _noclaimPoolAddr,
      uint48 _expiration,
      address _collateral,
      uint256 _bptAmountClaim,
      uint256 _bptAmountNoClaim
    ) external {
      _withdrawLiquidity(_claimPoolAddr, _noclaimPoolAddr, _bptAmountClaim, _bptAmountNoClaim);

      address noclaimTokenAddr = factory.getCovTokenAddress(_protocol.name(), _expiration, _collateral, _protocol.claimNonce(), false);
      address claimTokenAddr = factory.getCovTokenAddress(_protocol.name(), _expiration, _collateral, _protocol.claimNonce(), true);

      IERC20 claimToken = IERC20(claimTokenAddr);
      IERC20 noClaimToken = IERC20(noclaimTokenAddr);
      IERC20 collateralToken = IERC20(_collateral);
      claimToken.safeTransfer(msg.sender, claimToken.balanceOf(address(this)));
      noClaimToken.safeTransfer(msg.sender, noClaimToken.balanceOf(address(this)));
      collateralToken.safeTransfer(msg.sender, collateralToken.balanceOf(address(this)));
    }

    function marketMakerWithdrawAndRedeem(
      IProtocol _protocol,
      ICover _cover,
      address _claimPoolAddr,
      address _noclaimPoolAddr,
      uint48 _expiration,
      address _collateral,
      uint256 _bptAmountClaim,
      uint256 _bptAmountNoClaim
      ) external {
      _withdrawLiquidity(_claimPoolAddr, _noclaimPoolAddr, _bptAmountClaim, _bptAmountNoClaim);

      address noclaimTokenAddr = factory.getCovTokenAddress(_protocol.name(), _expiration, _collateral, _protocol.claimNonce(), false);
      address claimTokenAddr = factory.getCovTokenAddress(_protocol.name(), _expiration, _collateral, _protocol.claimNonce(), true);

      IERC20 claimToken = IERC20(claimTokenAddr);
      IERC20 noClaimToken = IERC20(noclaimTokenAddr);

      address redeemCovAddr = claimToken.balanceOf(address(this)) > noClaimToken.balanceOf(address(this)) ? noclaimTokenAddr : claimTokenAddr;
      address remainCovAddr = redeemCovAddr == claimTokenAddr ? noclaimTokenAddr : claimTokenAddr;

      _cover.redeemCollateral(IERC20(redeemCovAddr).balanceOf(address(this)));

      if (IERC20(remainCovAddr).balanceOf(address(this)) > 0) {
        IERC20(remainCovAddr).safeTransfer(msg.sender, IERC20(remainCovAddr).balanceOf(address(this)));
      }
      IERC20(_collateral).safeTransfer(msg.sender, IERC20(_collateral).balanceOf(address(this)));
    }

    function _withdrawLiquidity(
      address _claimPoolAddr,
      address _noclaimPoolAddr,
      uint256 _bptAmountClaim,
      uint256 _bptAmountNoClaim
      ) private {
      require(_bptAmountClaim > 0, "MarketMaker: insufficient bpt balance");
      require(_bptAmountNoClaim > 0, "MarketMaker: insufficient bpt balance");

      uint256[] memory minAmountsOut = new uint256[](2);
      minAmountsOut[0] = 0;
      minAmountsOut[1] = 0;

      IERC20(_claimPoolAddr).safeTransferFrom(msg.sender, address(this), _bptAmountClaim);
      IERC20(_noclaimPoolAddr).safeTransferFrom(msg.sender, address(this), _bptAmountNoClaim);
      IBPool(_claimPoolAddr).exitPool(IERC20(_claimPoolAddr).balanceOf(address(this)), minAmountsOut);
      IBPool(_noclaimPoolAddr).exitPool(IERC20(_noclaimPoolAddr).balanceOf(address(this)), minAmountsOut);
    }

    function _provideLiquidity(
      IBPool _bPool,
      address _covTokenAddress,
      uint256 _covTokenAmount,
      address _collateralAddress,
      uint256 _collateralAmount
      ) private {
      if (IERC20(_covTokenAddress).allowance(address(this), address(_bPool)) < _covTokenAmount) {
        IERC20(_covTokenAddress).approve(address(_bPool), uint256(-1));
      }
      if (IERC20(_collateralAddress).allowance(address(this), address(_bPool)) < _collateralAmount) {
        IERC20(_collateralAddress).approve(address(_bPool), uint256(-1));
      }

      uint256 poolAmountOutInCov = _covTokenAmount.mul(_bPool.totalSupply()).div(_bPool.getBalance(_covTokenAddress));
      uint256 poolAmountOutInCollateral = _collateralAmount.mul(_bPool.totalSupply()).div(_bPool.getBalance(_collateralAddress));
      uint256 bptAmountOut = poolAmountOutInCov > poolAmountOutInCollateral ? poolAmountOutInCollateral : poolAmountOutInCov;
      bptAmountOut = bptAmountOut.sub((uint256(1 ether))); // Buffer, alternatively bptAmountOut.mul(99).div(100);

      address[] memory tokenAddresses = _bPool.getFinalTokens();
      uint[] memory maxAmountsIn = new uint256[](2);
      if(tokenAddresses[0] == _collateralAddress){
        maxAmountsIn[0] = _collateralAmount;
        maxAmountsIn[1] = _covTokenAmount;
      } else {
        maxAmountsIn[0] = _covTokenAmount;
        maxAmountsIn[1] = _collateralAmount;
      }

      _bPool.joinPool(bptAmountOut, maxAmountsIn);
      require((IERC20(address(_bPool)).balanceOf(address(this)) == bptAmountOut), "LP_FAILED");

      IERC20 bpt = IERC20(address(_bPool));
      bpt.safeTransfer(msg.sender, bpt.balanceOf(address(this)));
      uint256 remainCovToken = IERC20(_covTokenAddress).balanceOf(address(this));
      if (remainCovToken > 0) {
        IERC20(_covTokenAddress).safeTransfer(msg.sender, remainCovToken);
      }
    }

    function getCollateralAmountLp(
      IBPool _bPool,
      address _covTokenAddr,
      address _collateralAddr,
      uint256 _mintAmount
      ) external view returns(uint256) {

      return _bPool.getBalance(_collateralAddr).mul(_mintAmount).div(_bPool.getBalance(_covTokenAddr));
    }

    receive() external payable {}

}
