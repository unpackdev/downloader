pragma solidity 0.5.16;

import "./SNXRewardInterface.sol";
import "./SNXReward2FarmStrategyV2.sol";

contract MithCash2FarmStrategyMainnet_MIC_USDT is SNXReward2FarmStrategyV2 {

  address public constant __usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address public constant __mic = address(0x368B3a58B5f49392e5C9E4C998cb0bB966752E51);
  address public constant __mis = address(0x4b4D2e899658FB59b1D518b68fe836B100ee8958);

  address public constant __underlying = address(0xC9cB53B48A2f3A9e75982685644c1870F1405CCb);
  address public constant __rewardPool = address(0x9D9418803F042CCd7647209b0fFd617981D5c619);

  address public constant __mic_usdt = address(0xC9cB53B48A2f3A9e75982685644c1870F1405CCb);
  address public constant __uniswapRouterV2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address public constant __sushiswapRouterV2 = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

  address public constant __farm = address(0xa0246c9032bC3A600820415aE600c6388619A14D);
  address public constant __weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public constant __notifyHelper = address(0xE20c31e3d08027F5AfACe84A3A46B7b3B165053c);
  
  constructor(
    address _storage,
    address _vault,
    address _distributionPool,
    address _distributionSwitcher
  )
  SNXReward2FarmStrategyV2(
    _storage, 
    __underlying, 
    _vault, 
    __rewardPool, 
    __mis,
    __uniswapRouterV2,
    __sushiswapRouterV2, 
    __farm,
    __weth,
    _distributionPool, 
    _distributionSwitcher
  )
  public {
    require(IVault(_vault).underlying() == __mic_usdt, "Underlying mismatch");
    liquidateRewardToWethInSushi = true;
    liquidationRoutes[__mis] = [__mis, __usdt, __weth];
    liquidationRoutes[__weth] = [__weth, farm];
    autoRevertRewardDistribution = false;
    defaultRewardDistribution = __notifyHelper;
  }
}
