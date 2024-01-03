// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./CurveBase.sol";

contract CurveUsdn is CurveBase {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  string constant SYMBOL = 'puCrvUsdn';
  string constant NAME = 'Puul CrvUsdn';

  constructor (address fees) 
    public CurveBase(NAME, SYMBOL, CurveHelperLibV2.CRV_USDN_LP, CurveHelperLibV2.CRV_USDN_DEPOSIT, CurveHelperLibV2.CRV_USDN_GAUGE, fees) 
  {
    // These must be in the right order - see the curve pool
    _storage._coins.push(CurveHelperLibV2.USDN);
    _storage._coins.push(CurveHelperLibV2.DAI);
    _storage._coins.push(CurveHelperLibV2.USDC);
    _storage._coins.push(CurveHelperLibV2.USDT);

    _storage._decimals[CurveHelperLibV2.USDN] = 18;
    _storage._decimals[CurveHelperLibV2.DAI] = 18;
    _storage._decimals[CurveHelperLibV2.USDC] = 6;
    _storage._decimals[CurveHelperLibV2.USDT] = 6;
  }

}
