//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";
import "./IERC3156FlashLender.sol";
import "./ILiquidationAuction.sol";
import "./ICurvePool.sol";
import "./IVault.sol";
import "./IYearn.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract LiquidateUSDP is Ownable {
  using SafeERC20 for IERC20;

  IERC3156FlashLender public constant flashLender = IERC3156FlashLender(0x6bdC1FCB2F13d1bA9D26ccEc3983d5D4bf318693); // DyDx
  ILiquidationAuction public constant liqAuction = ILiquidationAuction(0xaEF1ed4C492BF4C57221bE0706def67813D79955);
  ICurvePool public constant pool = ICurvePool(0x42d7025938bEc20B69cBae5A77421082407f053A); // USDP Curve pool
  IVault public constant vault = IVault(0xb1cFF81b9305166ff1EFc49A129ad2AfCd7BCf19);
  IERC20 public constant USDP = IERC20(0x1456688345527bE1f37E9e627DA0837D6f08C925);
  IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  int128 usdpIndex = 0;
  int128 usdcIndex = 2;

  struct LiquidationData {
    address asset;
    address user;
    address caller;
    uint256 minProfit;
  }

  function liquidate(address _asset, address _user, uint256 _minProfit) onlyOwner external {
    bytes memory data = abi.encode(LiquidationData({
      asset: _asset,
      user: _user,
      caller: msg.sender,
      minProfit: _minProfit
    }));
    uint256 usdpNeeded = getDebtAmount(_asset, _user);
    uint256 flashAmt = getUsdcNeeded(usdpNeeded);
    require(flashAmt <= flashLender.maxFlashLoan(address(USDC)), "Insufficient lender reserves");
    uint256 _fee = flashLender.flashFee(address(USDC), flashAmt);
    uint256 _repayment = flashAmt + _fee;
    _approve(USDC, address(flashLender), _repayment);
    flashLender.flashLoan(IERC3156FlashBorrower(address(this)), address(USDC), flashAmt, data);
  }

  function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data) external returns (bytes32) {
    LiquidationData memory liqData = abi.decode(data, (LiquidationData));
    require(msg.sender == address(flashLender), "Untrusted lender");
    require(token == address(USDC), "Not USDC");
    require(initiator == address(this), "Untrusted loan initiator");
    uint256 amountOwed = amount + fee;

    // Step 1: Convert USDC to USDP
    _approve(USDC, address(pool), amount);
    uint256 usdpReceived = pool.exchange_underlying(usdcIndex, usdpIndex, amount, 0);
    
    // Step 2: Buyout position
    _approve(USDP, address(liqAuction), usdpReceived);
    liqAuction.buyout(liqData.asset, liqData.user);
    uint256 collateralReceived = IERC20(liqData.asset).balanceOf(address(this));

    // Step 3: Convert collateral to USDC [NEED TO WRITE CUSTOM CODE]
    // INSERT CODE HERE
    // INSERT CODE HERE
    // INSERT CODE HERE
    // INSERT CODE HERE
    // INSERT CODE HERE
    // INSERT CODE HERE
    IERC20(0xB4AdA607B9d6b2c9Ee07A275e9616B84AC560139).approve(0xB4AdA607B9d6b2c9Ee07A275e9616B84AC560139, collateralReceived);
    IYearn(0xB4AdA607B9d6b2c9Ee07A275e9616B84AC560139).withdraw(collateralReceived);
    uint256 bal = IERC20(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B).balanceOf(address(this));
    ICurvePool(0xA79828DF1850E8a3A3064576f380D90aECDD3359).remove_liquidity_one_coin(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B, bal, 2, 0);

    uint256 usdcReceived = USDC.balanceOf(address(this));

    // Step 4: Ensure profit (usdcReceived - (flashAmt + flashFee)) is > minProfit and send to caller
    require(usdcReceived > amountOwed + liqData.minProfit, "Less than minProfit");
    USDC.safeTransfer(liqData.caller, usdcReceived - amountOwed);
    return keccak256("ERC3156FlashBorrower.onFlashLoan");
  }

  function getUsdcNeeded(uint256 _usdpNeeded) public view returns (uint256) {
    uint256 usdcNeeded = _usdpNeeded;
    uint256 amountOut = pool.get_dy_underlying(usdcIndex, usdpIndex, usdcNeeded);
    while (amountOut < _usdpNeeded) {
      usdcNeeded += usdcNeeded / 20; // increment by 5% until amountOut > usdpNeeded
      amountOut = pool.get_dy_underlying(usdcIndex, usdpIndex, usdcNeeded);
    }
    return usdcNeeded;
  }

  function getDebtAmount(address _asset, address _user) public view returns (uint256) {
    return vault.getTotalDebt(_asset, _user);
  }

  function _approve(IERC20 _token, address _spender, uint256 _amount) internal {
    if (_token.allowance(address(this), _spender) < _amount) {
        _token.safeApprove(_spender, type(uint256).max);
    }
  }
}
