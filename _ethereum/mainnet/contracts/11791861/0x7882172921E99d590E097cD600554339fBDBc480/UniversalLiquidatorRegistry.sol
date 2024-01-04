// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IUniversalLiquidatorRegistry.sol";

contract UniversalLiquidatorRegistry is Ownable, IUniversalLiquidatorRegistry {
  address constant public farm = address(0xa0246c9032bC3A600820415aE600c6388619A14D);

  address constant public usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address constant public dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

  address constant public wbtc = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
  address constant public renBTC = address(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
  address constant public sushi = address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
  address constant public dego = address(0x88EF27e69108B2633F8E1C184CC37940A075cC02);
  address constant public uni = address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
  address constant public comp = address(0xc00e94Cb662C3520282E6f5717214004A7f26888);
  address constant public crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);

  address constant public idx = address(0x0954906da0Bf32d5479e25f46056d22f08464cab);
  address constant public idle = address(0x875773784Af8135eA0ef43b5a374AaD105c5D39e);

  address constant public ycrv = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);

  address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address constant public mis = address(0x4b4D2e899658FB59b1D518b68fe836B100ee8958);
  address constant public bsg = address(0xB34Ab2f65c6e4F764fFe740ab83F982021Faed6d);
  address constant public bas = address(0xa7ED29B253D8B4E3109ce07c80fc570f81B63696);
  address constant public bsgs = address(0xA9d232cC381715aE791417B624D7C4509D2c28DB);
  address constant public kbtc = address(0xE6C3502997f97F9BDe34CB165fBce191065E068f);

  address public override universalLiquidator;

  function setUniversalLiquidator(address _ul) public override onlyOwner {
    require(_ul != address(0), "new universal liquidator is nill");
    universalLiquidator = _ul;
  }

  // path[UNISWAP][tokenA][tokenB]
  mapping (bytes32 => mapping(address => mapping(address => address[])) ) public dexPaths;

  constructor() public {
    bytes32 uniDex = bytes32(uint256(keccak256("uni")));
    bytes32 sushiDex = bytes32(uint256(keccak256("sushi")));

    // preset for the already in use crops
    dexPaths[uniDex][weth][farm] = [weth, farm];
    dexPaths[uniDex][dai][farm] = [dai, weth, farm];
    dexPaths[uniDex][usdc][farm] = [usdc, farm];
    dexPaths[uniDex][usdt][farm] = [usdt, weth, farm];

    dexPaths[uniDex][wbtc][farm] = [wbtc, weth, farm];
    dexPaths[uniDex][renBTC][farm] = [renBTC, weth, farm];

    // use Sushiswap for SUSHI, convert into WETH
    dexPaths[sushiDex][sushi][weth] = [sushi, weth];

    dexPaths[uniDex][dego][farm] = [dego, weth, farm];
    dexPaths[uniDex][crv][farm] = [crv, weth, farm];
    dexPaths[uniDex][comp][farm] = [comp, weth, farm];

    dexPaths[uniDex][idx][farm] = [idx, weth, farm];
    dexPaths[uniDex][idle][farm] = [idle, weth, farm];

    // use Sushiswap for MIS -> USDT
    dexPaths[sushiDex][mis][usdt] = [mis, usdt];
    dexPaths[uniDex][bsg][farm] = [bsg, dai, weth, farm];
    dexPaths[uniDex][bas][farm] = [bas, dai, weth, farm];
    dexPaths[uniDex][bsgs][farm] = [bsgs, dai, weth, farm];
    dexPaths[uniDex][kbtc][farm] = [kbtc, wbtc, weth, farm];
  }

  function getPath(bytes32 dex, address inputToken, address outputToken) public override view returns(address[] memory) {
    require(dexPaths[dex][inputToken][outputToken].length > 1, "Liquidation path is not set");
    return dexPaths[dex][inputToken][outputToken];
  }

  function setPath(bytes32 dex, address inputToken, address outputToken, address[] memory path) external override onlyOwner {
    // path could also be an empty array

    require(inputToken == path[0],
      "The first token of the Uniswap route must be the from token");
    require(outputToken == path[path.length - 1],
      "The last token of the Uniswap route must be the to token");

    // path can also be empty
    dexPaths[dex][inputToken][outputToken] = path;
  }
}
