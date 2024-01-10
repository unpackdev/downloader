pragma solidity 0.5.16;

import "./SafeERC20.sol";
import "./IERC20.sol";

import "./IdleBorrowableStrategy.sol";
import "./IStrategy.sol";
import "./IVault.sol";
import "./IUniswapV3Viewer.sol";
import "./IUniswapV3Vault.sol";
import "./Controllable.sol";

contract BorrowRecipient is Controllable {

  using SafeERC20 for IERC20;

  address public strategy;
  address public investmentVault;
  address public uniswapViewer;
  address public underlying;

  constructor(address _storage, address _strategy, address _investmentVault, address _uniswapViewer)
  public Controllable(_storage) {
    strategy = _strategy;
    investmentVault = _investmentVault;
    uniswapViewer = _uniswapViewer;
    underlying = IVault(IStrategy(strategy).vault()).underlying();
  }

  function approveBack(uint256 _amount) external onlyGovernance {
    IERC20(underlying).safeApprove(strategy, 0);
    IERC20(underlying).safeApprove(strategy, _amount);
  }

  function pullLoan(uint256 _amount) external {
    require(msg.sender == strategy, "Only strategy");
    IERC20(underlying).safeTransferFrom(strategy, address(this), _amount);
  }

  function deposit(
    uint256 _amount0,
    uint256 _amount1,
    bool _zapFunds,
    bool _sweep,
    uint256 _sqrtRatioX96,
    uint256 _tolerance
  ) external onlyGovernance returns (uint256, uint256) {
    IERC20 token0 = IERC20(IUniswapV3Vault(investmentVault).token0());
    IERC20 token1 = IERC20(IUniswapV3Vault(investmentVault).token1());
    token0.safeApprove(investmentVault, 0);
    token0.safeApprove(investmentVault, _amount0);
    token1.safeApprove(investmentVault, 0);
    token1.safeApprove(investmentVault, _amount1);
    return IUniswapV3Vault(investmentVault).deposit(_amount0, _amount1, _zapFunds, _sweep, _sqrtRatioX96, _tolerance);
  }

  function withdraw(uint256 _numberOfShares,
    bool _token0,
    bool _token1,
    uint256 _sqrtRatioX96,
    uint256 _tolerance) external onlyGovernance returns (uint256, uint256) {
    return IUniswapV3Vault(investmentVault).withdraw(_numberOfShares, _token0, _token1, _sqrtRatioX96, _tolerance);
  }

  function drain(address token, uint256 _amount) external onlyGovernance {
    if (underlying == token) {
      require(IdleBorrowableStrategy(strategy).borrowed() == 0, "Settle loan before taking profit");
    }
    IERC20(token).safeTransfer(msg.sender, _amount);
  }

  function getPositionId() public view returns (uint256) {
    return IUniswapV3Vault(investmentVault).getStorage().posId();
  }

  function getSqrtPriceX96ForPosition() public view returns(uint160) {
    return IUniswapV3Viewer(uniswapViewer).getSqrtPriceX96ForPosition(getPositionId());
  }

  function getLiquidityAmounts() public view returns (uint256 userAmount0, uint256 userAmount1) {
    uint256 balance = IERC20(investmentVault).balanceOf(address(this));
    return IUniswapV3Viewer(uniswapViewer).getAmountsForUserShare(investmentVault, balance);
  }

}