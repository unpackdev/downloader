// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./ERC20.sol";

import "./Ownable.sol";


interface IFeed
{
  function latestAnswer() external view returns (int256);
}

interface IOracle
{
  function getRate(address from, address to) external view returns (uint256);

  function convertFromUSD(address to, uint256 amount) external view returns (uint256);

  function convertToUSD(address from, uint256 amount) external view returns (uint256);

  function convert(address from, address to, uint256 amount) external view returns (uint256);
}

contract Oracle is IOracle, Ownable
{
  using SafeMath for uint256;


  address private constant _DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address private constant _WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  uint256 private constant _DECIMALS = 1e18;

  mapping(address => address) private _ETHFeeds;
  mapping(address => address) private _USDFeeds;


  constructor()
  {
    // address INCH = 0x111111111117dC0aa78b770fA6A738034120C302;
    // address AMPL = 0xD46bA6D942050d489DBd938a2C909A5d5039A161;
    // address BNT = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C;
    // address AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    // address ANT = 0xa117000000f279D81A1D3cc75430fAA017FA5A2e;
    // address BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    // address BAND = 0xBA11D00c5f74255f56a5E366F4F77f5A186d7f55;
    // address BAT = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
    // address COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    // address CREAM = 0x2ba592F78dB6436527729929AAf6c908497cB200;
    // address CRO = 0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b;
    // address CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    // address ENJ = 0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c;
    // address GRT = 0xc944E90C64B2c07662A292be6244BDf05Cda44a7;
    // address KNC = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
    // address KEEPER = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
    // address LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    // address LRC = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;
    // address MANA = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;
    // address MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    // address REN = 0x408e41876cCCDC0F92210600ef50372656052a38;
    // address SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    // address SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    // address SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    // address TUSD = 0x0000000000085d4780B73119b644AE5ecd22b376;
    // address UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    // address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    // address WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    // address YFI = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
    // address ZRX = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;

    _ETHFeeds[_DAI] = address(0x773616E4d11A78F511299002da57A0a94577F1f4);
    _ETHFeeds[0x111111111117dC0aa78b770fA6A738034120C302] = address(0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8);
    _ETHFeeds[0xD46bA6D942050d489DBd938a2C909A5d5039A161] = address(0x492575FDD11a0fCf2C6C719867890a7648d526eB);
    _ETHFeeds[0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C] = address(0xCf61d1841B178fe82C8895fe60c2EDDa08314416);
    _ETHFeeds[0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9] = address(0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012);
    _ETHFeeds[0xa117000000f279D81A1D3cc75430fAA017FA5A2e] = address(0x8f83670260F8f7708143b836a2a6F11eF0aBac01);
    _ETHFeeds[0xba100000625a3754423978a60c9317c58a424e3D] = address(0xC1438AA3823A6Ba0C159CfA8D98dF5A994bA120b);
    _ETHFeeds[0xBA11D00c5f74255f56a5E366F4F77f5A186d7f55] = address(0x0BDb051e10c9718d1C29efbad442E88D38958274);
    _ETHFeeds[0x0D8775F648430679A709E98d2b0Cb6250d2887EF] = address(0x0d16d4528239e9ee52fa531af613AcdB23D88c94);
    _ETHFeeds[0xc00e94Cb662C3520282E6f5717214004A7f26888] = address(0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699);
    _ETHFeeds[0x2ba592F78dB6436527729929AAf6c908497cB200] = address(0x82597CFE6af8baad7c0d441AA82cbC3b51759607);
    _ETHFeeds[0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b] = address(0xcA696a9Eb93b81ADFE6435759A29aB4cf2991A96);
    _ETHFeeds[0xD533a949740bb3306d119CC777fa900bA034cd52] = address(0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e);
    _ETHFeeds[0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c] = address(0x24D9aB51950F3d62E9144fdC2f3135DAA6Ce8D1B);
    _ETHFeeds[0xc944E90C64B2c07662A292be6244BDf05Cda44a7] = address(0x17D054eCac33D91F7340645341eFB5DE9009F1C1);
    _ETHFeeds[0xdd974D5C2e2928deA5F71b9825b8b646686BD200] = address(0x656c0544eF4C98A6a98491833A89204Abb045d6b);
    _ETHFeeds[0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44] = address(0xe7015CCb7E5F788B8c1010FC22343473EaaC3741);
    _ETHFeeds[0x514910771AF9Ca656af840dff83E8264EcF986CA] = address(0xDC530D9457755926550b59e8ECcdaE7624181557);
    _ETHFeeds[0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD] = address(0x160AC928A16C93eD4895C2De6f81ECcE9a7eB7b4);
    _ETHFeeds[0x0F5D2fB29fb7d3CFeE444a200298f468908cC942] = address(0x82A44D92D6c329826dc557c5E1Be6ebeC5D5FeB9);
    _ETHFeeds[0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2] = address(0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2);
    _ETHFeeds[0x408e41876cCCDC0F92210600ef50372656052a38] = address(0x3147D7203354Dc06D9fd350c7a2437bcA92387a4);
    _ETHFeeds[0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F] = address(0x79291A9d692Df95334B1a0B3B4AE6bC606782f8c);
    _ETHFeeds[0x57Ab1ec28D129707052df4dF418D58a2D46d5f51] = address(0x8e0b7e6062272B5eF4524250bFFF8e5Bd3497757);
    _ETHFeeds[0x6B3595068778DD592e39A122f4f5a5cF09C90fE2] = address(0xe572CeF69f43c2E488b33924AF04BDacE19079cf);
    _ETHFeeds[0x0000000000085d4780B73119b644AE5ecd22b376] = address(0x3886BA987236181D98F2401c507Fb8BeA7871dF2);
    _ETHFeeds[0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984] = address(0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e);
    _ETHFeeds[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = address(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
    _ETHFeeds[0xdAC17F958D2ee523a2206206994597C13D831ec7] = address(0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46);
    _ETHFeeds[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = address(0xdeb288F737066589598e9214E782fa5A8eD689e8);
    _ETHFeeds[0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e] = address(0x7c5d4F8345e66f68099581Db340cd65B078C41f4);
    _ETHFeeds[0xE41d2489571d322189246DaFA5ebDe1F4699F498] = address(0x2Da4983a622a8498bb1a21FaE9D8F6C664939962);

    _USDFeeds[_WETH] = address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
  }

  function getFeeds(address token) external view returns (address, address)
  {
    return (_ETHFeeds[token], _USDFeeds[token]);
  }

  function setFeeds(address[] calldata tokens, address[] calldata feeds, bool is_USDFeeds) external onlyOwner
  {
    require(tokens.length == feeds.length, "!=");

    if (is_USDFeeds)
    {
      for (uint256 i = 0; i < tokens.length; i++)
      {
        address token = tokens[i];

        _USDFeeds[token] = feeds[i];
      }
    }
    else
    {
      for (uint256 i = 0; i < tokens.length; i++)
      {
        address token = tokens[i];

        _ETHFeeds[token] = feeds[i];
      }
    }
  }


  function uintify(int256 val) private pure returns (uint256)
  {
    require(val > 0, "Feed err");

    return uint256(val);
  }

  function getTokenETHRate(address token) private view returns (uint256)
  {
    if (_ETHFeeds[token] != address(0))
    {
      return uintify(IFeed(_ETHFeeds[token]).latestAnswer());
    }
    else if (_USDFeeds[token] != address(0))
    {
      return uintify(IFeed(_USDFeeds[token]).latestAnswer()).mul(_DECIMALS).div(uintify(IFeed(_USDFeeds[_WETH]).latestAnswer()));
    }
    else
    {
      return 0;
    }
  }

  function getRate(address from, address to) public view override returns (uint256)
  {
    if (from == to && to == _DAI)
    {
      return _DECIMALS;
    }

    uint256 srcRate = from == _WETH ? _DECIMALS : getTokenETHRate(from);
    uint256 destRate = to == _WETH ? _DECIMALS : getTokenETHRate(to);

    require(srcRate > 0 && destRate > 0 && srcRate < type(uint256).max && destRate < type(uint256).max, "No oracle");

    return srcRate.mul(_DECIMALS).div(destRate);
  }

  function calcDestQty(uint256 srcQty, address from, address to, uint256 rate) private view returns (uint256)
  {
    uint256 srcDecimals = ERC20(from).decimals();
    uint256 destDecimals = ERC20(to).decimals();

    uint256 difference;

    if (destDecimals >= srcDecimals)
    {
      difference = 10 ** destDecimals.sub(srcDecimals);

      return srcQty.mul(rate).mul(difference).div(_DECIMALS);
    }
    else
    {
      difference = 10 ** srcDecimals.sub(destDecimals);

      return srcQty.mul(rate).div(_DECIMALS.mul(difference));
    }
  }

  function convertFromUSD(address to, uint256 amount) external view override returns (uint256)
  {
    return calcDestQty(amount, _DAI, to, getRate(_DAI, to));
  }

  function convertToUSD(address from, uint256 amount) external view override returns (uint256)
  {
    return calcDestQty(amount, from, _DAI, getRate(from, _DAI));
  }

  function convert(address from, address to, uint256 amount) external view override returns (uint256)
  {
    return calcDestQty(amount, from, to, getRate(from, to));
  }
}
