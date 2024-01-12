pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./GeneralLevSwap.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

interface CurveBasePool {
  function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;

  function coins(int128) external view returns (address);
}

interface CurveMetaPool {
  function coins(int128) external view returns (address);

  function add_liquidity(uint256[2] memory amounts, uint256 _min_mint_amount) external;
}

contract ThreeCrvFraxLevSwap is GeneralLevSwap {
  using SafeERC20 for IERC20;

  CurveMetaPool public constant POOL = CurveMetaPool(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B);
  CurveBasePool public constant threecrv =
    CurveBasePool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

  IERC20 public constant threeCrvToken = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490); // 3crv

  address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  constructor(
    address asset,
    address vault,
    address _provider
  ) GeneralLevSwap(asset, vault, _provider) {
    ENABLED_STABLE_COINS[DAI] = true;
    ENABLED_STABLE_COINS[USDC] = true;
    ENABLED_STABLE_COINS[USDT] = true;
  }

  function getAvailableStableCoins() external pure override returns (address[] memory assets) {
    assets = new address[](3);
    assets[0] = DAI;
    assets[1] = USDC;
    assets[2] = USDT;
  }

  function _getCoinIndex(address stableAsset) internal pure returns (uint256) {
    if (stableAsset == DAI) return 0;
    if (stableAsset == USDC) return 1;
    require(stableAsset == USDT, 'Invalid stable coin');
    return 2;
  }

  function _swap(address stableAsset, uint256 _amount) internal override returns (uint256) {
    uint256 coinIndex = _getCoinIndex(stableAsset);

    // stable coin -> 3crv
    IERC20(stableAsset).safeApprove(address(threecrv), 0);
    IERC20(stableAsset).safeApprove(address(threecrv), _amount);

    uint256[3] memory amountsAdded;
    amountsAdded[coinIndex] = _amount;
    threecrv.add_liquidity(amountsAdded, 0);
    uint256 amountTo = threeCrvToken.balanceOf(address(this));

    // 3crv -> frax3crv-f
    threeCrvToken.safeApprove(address(POOL), 0);
    threeCrvToken.safeApprove(address(POOL), amountTo);
    POOL.add_liquidity([0, amountTo], 0);
    amountTo = IERC20(COLLATERAL).balanceOf(address(this));

    return amountTo;
  }
}
